#!/usr/bin/env python3
"""Check every name used in the SL100 design documents against the Legends wiki. Lookup only - no judgement.

  legends_check.py [--no-live]     -> docs/collation/legends_check.csv  (+ legends_check_summary.md)
  legends_check.py --summary-only  rewrite legends_check_summary.md from the existing CSV (no lookups)

Names are taken from: markdown headings, the first column of tables, and Wookieepedia links.
status:
  legends         a Legends article with this name is in our local wiki
  legends-link    the doc links to a Wookieepedia /Legends page that we hold
  canon-link      the doc links to a canon (non-/Legends) Wookieepedia page
  canon-only      not in our Legends wiki, but the live Wookieepedia has a canon page of that name (checked over the API)
  not-found       neither - probably an SL100 invention, a rename or a spelling difference (see 'closest')
"""
import csv, os, re, sys, urllib.parse
from collections import defaultdict
from pathlib import Path

WIKI = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(WIKI / "tools"))
import common as C   # noqa: E402

OUT = WIKI / "docs" / "collation"
RULES_DOCS = ("Characteristics", "Origin", "Careers", "Skills", "Talents", "Talents (index)", "The Force")   # game-term pages: names there are rules words, not setting names
DOCS = sorted(p for p in C.RULES_DIR.glob("*.md") if p.name not in C.SUPERSEDED)
HEAD_SKIP = re.compile(r"^(table|traits?|special|notes?|description|abilities|skills|talents|characteristics|trappings|example|"
                       r"species|origin|factions?|careers?|equipment|weapons?|armou?r|vehicles?|ships?|star ?fighters?|"
                       r"capital ships|freighters|transports|mounts|air mounts|land mounts|water mounts|creatures|introduction|"
                       r"overview|summary|career path|level \d|class|status|advance scheme|.*rules?)$", re.I)


def clean(s):
    s = re.sub(r"\[([^\]]*)\]\([^)]*\)", r"\1", s)
    s = re.sub(r"[*_`#☀☾⚖️]|&#\d+;|<[^>]+>", "", s)
    s = re.sub(r"\s*\(.*?\)\s*$", "", s)
    return re.sub(r"\s+", " ", s).strip(" :-–—|")


def norm(s):
    s = s.replace("/Legends", "").lower()
    s = re.sub(r"[’'`\"“”]", "", s)
    return re.sub(r"[^a-z0-9]+", " ", s).strip()


def harvest():
    out = []   # (doc, line, kind, name, url)
    for p in DOCS:
        for i, ln in enumerate(p.read_text(encoding="utf-8", errors="replace").split("\n"), 1):
            for m in re.finditer(r"\[([^\]]+)\]\((https?://[^)\s]*(?:fandom|wikia)\.[^)\s]*/wiki/([^)\s#?]+))\)", ln):
                out.append((p.name, i, "link", clean(m.group(1)), urllib.parse.unquote(m.group(3)).replace("_", " ")))
            h = re.match(r"^#{1,6}\s+(.*)$", ln)
            if h:
                n = clean(h.group(1))
                if n and not HEAD_SKIP.match(n) and len(n) < 60:
                    out.append((p.name, i, "heading", n, ""))
                continue
            t = re.match(r"^\|\s*([^|]+?)\s*\|", ln)
            if t:
                n = clean(t.group(1))
                if n and not re.fullmatch(r"[-\s:]*|\d[\d\s.,+%-]*|[A-Z]{1,3}", n) and len(n) < 60 and len(n.split()) <= 7 \
                        and not HEAD_SKIP.match(n):
                    out.append((p.name, i, "table", n, ""))
    return out


def main(live=True):
    con = C.db_connect()
    by = {}
    for (t,) in con.execute("SELECT title FROM pages WHERE ns=0 AND path IS NOT NULL"):
        n = norm(t)
        if t.endswith("/Legends") or n not in by:
            by[n] = t
    names = harvest()
    rows, pending = [], {}

    def local(n):
        for v in (n, re.sub(r"s$", "", n), n + "s", re.sub(r"ies$", "y", n), re.sub(r"^the ", "", n)):
            if norm(v) in by:
                return by[norm(v)]
        return ""

    for doc, line, kind, name, url in names:
        r = {"doc": doc, "line": line, "found_in": kind, "name": name, "status": "", "legends_title": "", "link_target": url, "closest": ""}
        if kind == "link":
            if url.endswith("/Legends"):
                r["status"] = "legends-link" if url in by.values() or norm(url) in by else "legends-link (not held)"
                r["legends_title"] = by.get(norm(url), "")
            else:
                lt = local(url)
                r["status"] = "canon-link"
                r["legends_title"] = lt
        else:
            lt = local(name)
            if lt:
                r["status"], r["legends_title"] = "legends", lt
            else:
                pending[name] = None
        rows.append(r)
    # live lookups for names we do not hold (50 titles per request, throttled by common.api)
    if live and pending:
        todo = list(pending)
        for i in range(0, len(todo), 50):
            chunk = todo[i:i + 50]
            r = C.api(action="query", titles="|".join(chunk), redirects="1")
            q = r.get("query", {})
            norm_map = {x["from"]: x["to"] for x in q.get("normalized", [])}
            redir = {x["from"]: x["to"] for x in q.get("redirects", [])}
            exists = {p["title"] for p in q.get("pages", []) if not p.get("missing") and not p.get("invalid")}
            for n in chunk:
                t = redir.get(norm_map.get(n, n), norm_map.get(n, n))
                pending[n] = t if t in exists else ""
    import difflib
    keys = list(by)
    for r in rows:
        if r["status"]:
            continue
        canon = pending.get(r["name"])
        if canon:
            lt = local(canon)
            r["status"] = "legends (via redirect)" if lt else "canon-only"
            r["legends_title"] = lt
            r["link_target"] = canon
        else:
            r["status"] = "not-found"
            c = difflib.get_close_matches(norm(r["name"]), [k for k in keys if k[:1] == norm(r["name"])[:1]], n=2, cutoff=0.82)
            r["closest"] = " | ".join(by[x] for x in c)
    OUT.mkdir(parents=True, exist_ok=True)
    with open(OUT / "legends_check.csv", "w", newline="", encoding="utf-8") as fh:
        w = csv.DictWriter(fh, fieldnames=list(rows[0]))
        w.writeheader(); w.writerows(rows)
    summary(rows)


def summary(rows):
    """legends_check_summary.md, naming each document by the wiki page it is published as."""
    rows = [r for r in rows if r["doc"] not in C.SUPERSEDED]
    pg = lambda r: C.page_of(r["doc"])
    cnt = defaultdict(lambda: defaultdict(int))
    for r in rows:
        cnt[pg(r)][r["status"]] += 1
    md = ["# Legends check of the SL100 documents", "", "Generated by `tools/collate/legends_check.py`. Lookup only; nothing was changed in the documents.", "",
          "| Wiki page | " + " | ".join(["legends", "legends-link", "canon-link", "canon-only", "not-found"]) + " |", "|---|---|---|---|---|---|"]
    for d, c in cnt.items():
        md.append("| %s | %s |" % (d, " | ".join(str(c.get(k, 0)) for k in ["legends", "legends-link", "canon-link", "canon-only", "not-found"])))
    md += ["", "## canon-only names (exist on Wookieepedia only as canon pages)", ""]
    md += ["- %s (%s, line %s)" % (r["name"], pg(r), r["line"]) for r in rows if r["status"] == "canon-only" and pg(r) not in RULES_DOCS]
    md += ["", ("Rules pages (%s) are left out of this list: their names are game terms "
                "(e.g. Criminal, Master) that happen to match unrelated canon pages. They are still in the CSV.") % ", ".join(RULES_DOCS)]
    md += ["", "## canon links (doc links to a non-Legends page)", ""]
    md += ["- %s -> %s%s (%s, line %s)" % (r["name"], r["link_target"], "; Legends page held: " + r["legends_title"] if r["legends_title"] else "", pg(r), r["line"])
           for r in rows if r["status"] == "canon-link"]
    (OUT / "legends_check_summary.md").write_text("\n".join(md) + "\n", encoding="utf-8")
    print("\n".join(md[:6 + len(cnt)]))
    print("rows:", len(rows))


if __name__ == "__main__":
    if "--summary-only" in sys.argv:
        with open(OUT / "legends_check.csv", newline="", encoding="utf-8") as fh:
            summary(list(csv.DictReader(fh)))
    else:
        main(live="--no-live" not in sys.argv)
