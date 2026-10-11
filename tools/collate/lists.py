#!/usr/bin/env python3
"""Rebuild the SL100 talent and skill master lists from the design documents, and cross-check them. Copying and
comparing only: every name and field is taken as written; nothing is decided.

  lists.py   -> docs/collation/talents_master.csv, skills_master.csv, career_refs.csv, lists_report.md

talents_master.csv  every '### Talent' entry in 07 with Max / Tests as written, line number, and flags
skills_master.csv   every '### Skill (Char) basic|advanced[, grouped]' entry in 06
career_refs.csv     every skill and talent named in a career level of 05 (career, level, kind, name as written)
lists_report.md     differences: 07 vs Talent List, career talents/skills not defined in 06/07, duplicates, near-duplicates
"""
import csv, difflib, re
from collections import defaultdict
from pathlib import Path

WIKI = Path(__file__).resolve().parent.parent.parent
OUT = WIKI / "docs" / "collation"
F07 = WIKI / "07 New Star Wars - Talents.md"
F06 = WIKI / "06 New Star Wars - Skills.md"
F05 = WIKI / "05 New Star Wars - Careers.md"
FTL = WIKI / "Talent List.md"


def plain(s):
    s = re.sub(r"&#160;|&nbsp;| ", " ", s)
    s = re.sub(r"\[([^\]]*)\]\([^)]*\)", r"\1", s)
    return re.sub(r"\s+", " ", re.sub(r"[*_`]", "", s)).strip(" :.-")


def key(s):
    s = plain(s).lower()
    s = re.sub(r"\s*\(.*?\)", "", s)                 # Etiquette (Nobles) -> etiquette
    return re.sub(r"[^a-z0-9]+", " ", s).strip()


def talents07():
    lines = F07.read_text(encoding="utf-8", errors="replace").split("\n")
    rows = []
    for i, ln in enumerate(lines):
        m = re.match(r"^###\s*(.*)$", ln)
        if not m:
            continue
        name = plain(m.group(1))
        body = "\n".join(lines[i + 1:i + 12])
        nxt = re.search(r"^###", body, re.M)
        if nxt:
            body = body[:nxt.start()]
        mx = re.search(r"\*\*Max\*\*\s*:?\s*(.*?)(?=\*\*Tests\*\*|\n|$)", body)
        ts = re.search(r"\*\*Tests\*\*\s*:?\s*(.*?)(?=\*\*|\n|$)", body)
        text = re.sub(r"\*\*(Max|Tests)\*\*[^\n]*", "", body).strip()
        flags = []
        if not name:
            flags.append("empty heading")
        if not mx:
            flags.append("no Max")
        if not text or len(text) < 30:
            flags.append("little or no rules text")
        if re.search(r"\bxx\b|page \d+|\bTBD\b", body, re.I):
            flags.append("placeholder or page ref")
        rows.append({"name": name, "max": plain(mx.group(1)) if mx else "", "tests": plain(ts.group(1)) if ts else "",
                     "line": i + 1, "text_chars": len(text), "flags": "; ".join(flags)})
    return rows


def talent_list():
    rows, sec = [], ""
    for i, ln in enumerate(FTL.read_text(encoding="utf-8", errors="replace").split("\n"), 1):
        s = ln.strip()
        m = re.match(r"^[-*]\s+(.+?)\s+[—–-]\s+(.*)$", s)
        if m:
            rows.append({"name": plain(m.group(1)), "section": sec, "summary": plain(m.group(2)), "line": i})
        elif s and s.upper() == s and re.search(r"[A-Z]", s) and not set(s) <= set("=-"):
            sec = s.title()
    return rows


def skills06():
    rows = []
    for i, ln in enumerate(F06.read_text(encoding="utf-8", errors="replace").split("\n"), 1):
        m = re.match(r"^###\s*(.*)$", ln)
        if not m:
            continue
        h = plain(m.group(1))
        sm = re.match(r"^(.*?)\s*\((\w+)\)\s*(basic|advanced)?\s*,?\s*(grouped)?", h, re.I)
        if sm:
            rows.append({"name": sm.group(1).strip(), "characteristic": sm.group(2), "type": (sm.group(3) or "").lower(),
                         "grouped": "yes" if sm.group(4) else "", "line": i, "heading_as_written": h})
        elif h and h.lower() not in ("skills",):
            rows.append({"name": h, "characteristic": "", "type": "", "grouped": "", "line": i, "heading_as_written": h})
    return rows


def careers05():
    rows, cls, career, level = [], "", "", ""
    for i, ln in enumerate(F05.read_text(encoding="utf-8", errors="replace").split("\n"), 1):
        s = ln.strip()
        if re.match(r"^#\s", s):
            cls = plain(s.lstrip("#"))
        elif re.match(r"^##\s", s):
            career = plain(s.lstrip("#"))
        lv = re.match(r"^\*\*(\d)\.\s*(.*?)\*\*$", s)
        if lv:
            level = lv.group(1) + ". " + plain(lv.group(2))
        km = re.match(r"^\*\*(Skills|Talents)\s*:?\*\*\s*:?\s*(.*)$", s)
        if km and career:
            for n in re.split(r",(?![^()]*\))", km.group(2)):
                n = plain(n)
                if n:
                    rows.append({"class": cls, "career": career, "level": level, "kind": km.group(1)[:-1].lower(), "name": n, "line": i})
    return rows


def write(name, rows):
    if not rows:
        return
    with open(OUT / name, "w", newline="", encoding="utf-8") as fh:
        w = csv.DictWriter(fh, fieldnames=list(rows[0]))
        w.writeheader(); w.writerows(rows)


def dupes(rows):
    d = defaultdict(list)
    for r in rows:
        d[key(r["name"])].append(r)
    return {k: v for k, v in d.items() if k and len(v) > 1}


def near(names_a, names_b, cutoff=0.85):
    out = []
    for a in names_a:
        c = difflib.get_close_matches(a, names_b, n=1, cutoff=cutoff)
        if c:
            out.append((a, c[0]))
    return out


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    t7, tl, sk, cr = talents07(), talent_list(), skills06(), careers05()
    write("talents_master.csv", t7); write("talent_list_index.csv", tl); write("skills_master.csv", sk); write("career_refs.csv", cr)
    k7 = {key(r["name"]): r for r in t7 if r["name"]}
    kl = {key(r["name"]): r for r in tl}
    ks = {key(r["name"]): r for r in sk if r["name"]}
    only7 = sorted(set(k7) - set(kl)); onlyl = sorted(set(kl) - set(k7))
    ct = defaultdict(list); cs = defaultdict(list)
    for r in cr:
        (ct if r["kind"] == "talent" else cs)[key(r["name"])].append(r)
    ct_missing = sorted(k for k in ct if k not in k7)
    cs_missing = sorted(k for k in cs if k not in ks)
    md = ["# Talent and skill lists - collation report", "",
          "Generated by `tools/collate/lists.py` from 05, 06, 07 and Talent List. Names compared after removing bracketed "
          "specialisations and punctuation. Nothing here is a design decision; it only shows where the documents disagree.", "",
          "| Count | |", "|---|---|",
          "| Talent entries in 07 | %d (%d unique) |" % (len(t7), len(k7)),
          "| Talents in Talent List | %d (%d unique) |" % (len(tl), len(kl)),
          "| Skill entries in 06 | %d (%d unique) |" % (len(sk), len(ks)),
          "| Career skill/talent references in 05 | %d (%d talents, %d skills distinct) |" % (len(cr), len(ct), len(cs)), ""]
    md += ["## In 07 but not in Talent List (%d)" % len(only7), "", ", ".join(k7[k]["name"] for k in only7) or "none", ""]
    md += ["## In Talent List but not in 07 (%d)" % len(onlyl), "", "\n".join("- %s (%s)" % (kl[k]["name"], kl[k]["section"]) for k in onlyl) or "none", ""]
    md += ["## Talents used by careers (05) but not defined in 07 (%d)" % len(ct_missing), ""]
    md += ["- %s - %s" % (ct[k][0]["name"], "; ".join(sorted({"%s %s" % (r["career"], r["level"].split('.')[0]) for r in ct[k]}))[:200]) for k in ct_missing]
    md += ["", "## Skills used by careers (05) but not defined in 06 (%d)" % len(cs_missing), ""]
    md += ["- %s - %s" % (cs[k][0]["name"], "; ".join(sorted({"%s %s" % (r["career"], r["level"].split('.')[0]) for r in cs[k]}))[:200]) for k in cs_missing]
    summary = []
    for ln in F06.read_text(encoding="utf-8", errors="replace").split("\n")[:40]:
        if ln.count(",") > 10:
            summary = [plain(x) for x in ln.split(",") if plain(x)]
            break
    md += ["", "## Skills named in 06's opening list but with no entry of their own (%d)" % len([x for x in summary if key(x) not in ks]), "",
           ", ".join(x for x in summary if key(x) not in ks) or "none"]
    md += ["", "## Talents defined in 07 that no career grants (%d)" % len([k for k in k7 if k not in ct]), "",
           ", ".join(k7[k]["name"] for k in sorted(k7) if k not in ct), ""]
    md += ["## Duplicates", ""]
    for label, rows in (("07 Talents", t7), ("Talent List", tl), ("06 Skills", sk)):
        d = dupes([r for r in rows if r["name"]])
        md.append("- %s: %s" % (label, "; ".join("%s (lines %s)" % (v[0]["name"], ", ".join(str(x["line"]) for x in v)) for v in d.values()) or "none"))
    md += ["", "## Near-duplicate spellings (possible typos or renames)", ""]
    for a, b in near(only7, onlyl) + near(ct_missing, list(k7)) + near(cs_missing, list(ks)):
        md.append("- '%s' ~ '%s'" % (a, b))
    md += ["", "## 07 entries with flags", ""]
    md += ["- line %d %s: %s" % (r["line"], r["name"] or "(blank)", r["flags"]) for r in t7 if r["flags"]]
    md += ["", "## 06 headings that are not in 'Skill (Char) basic/advanced' form", ""]
    md += ["- line %d: %s" % (r["line"], r["heading_as_written"] or "(blank)") for r in sk if not r["characteristic"]]
    (OUT / "lists_report.md").write_text("\n".join(md) + "\n", encoding="utf-8")
    print("\n".join(md[:14]))
    print("only07 %d, onlyList %d, career talents undefined %d, career skills undefined %d" % (len(only7), len(onlyl), len(ct_missing), len(cs_missing)))


if __name__ == "__main__":
    main()
