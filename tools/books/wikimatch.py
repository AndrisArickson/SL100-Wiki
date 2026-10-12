#!/usr/bin/env python3
"""Match the d20 items extracted to Source_Text/tables/*.csv against the local Legends wiki, and copy facts from the
matched article's infobox. Purely mechanical: name/model-code/word matching, no judgement about game values.

  wikimatch.py            -> Source_Text/tables/wiki_match.csv  (+ wiki_match_summary.txt)

match column:
  exact   the item name (with or without a leading manufacturer word) equals a Legends article title
  generic only the book's "(Typical X)" label matched, so this links to the generic article for X
  code    a model code in the name (DH-17, T-65, R2, E-11...) appears in exactly one suitable article title
  words   best word-overlap title (score >= 0.6) - CHECK these by eye
  multi   several equally good titles - listed in 'candidates' for you to choose
  none    nothing suitable found
  confirmed / rejected   decided by hand on the local wiki page /match-review (stored in wiki_match_choices.csv)
Infobox facts are copied as written on Wookieepedia (refs and markup stripped), e.g. manufacturer, model, class, cost,
length, affiliation, era/introduced/retired where the infobox has them.
"""
import csv, os, re, sys
from collections import defaultdict
from pathlib import Path

HERE = Path(__file__).resolve().parent
WIKI = HERE.parent.parent                      # SL100-Wiki
ROOT = WIKI.parent                             # SL100
TEXT = Path(os.environ.get("SL100_TEXT_DIR", ROOT / "Source_Text"))
TAB = TEXT / "tables"
sys.path.insert(0, str(WIKI / "tools"))
import common as C                             # noqa: E402

SOURCES = {  # file -> kind
    "weapon.csv": "weapon", "core_weapon.csv": "weapon", "armor.csv": "armor", "core_armor.csv": "armor",
    "droid.csv": "droid", "vehicle.csv": "vehicle", "core_vehicle.csv": "vehicle", "starship.csv": "starship", "gear.csv": "gear",
    "core_equipment.csv": "gear", "species.csv": "species",
}
TEMPLATES = {  # substrings of infobox template names that suit each kind (Wookieepedia: Weapon, StarshipClass,
    # RepulsorliftVehicle, DroidSeries, Device, Species, ...)
    "weapon": ("weapon",), "armor": ("armor", "clothing", "device", "equipment", "weapon"),
    "droid": ("droid",), "vehicle": ("vehicle", "walker", "speeder", "starship"),
    "starship": ("starship", "vehicle", "station"), "gear": ("device", "equipment", "weapon", "clothing", "substance", "droid", "vehicle"),
    "species": ("species",),
}
FACTS = ["manufacturer", "designer", "line", "model", "type", "class", "degree", "cost", "length", "height", "mass", "weight",
         "range", "capacity", "crew", "passengers", "maxspeed", "hyperdrive", "armament", "affiliation", "era", "eras",
         "introduced", "retired", "culture", "homeworld", "designation", "language"]
STOP = {"the", "a", "of", "and", "series", "model", "class", "typical", "industries", "corporation", "systems", "inc"}


def norm(s):
    s = s.replace("/Legends", "").lower()
    s = re.sub(r"[’'`“”\"]", "", s)
    s = re.sub(r"[^a-z0-9]+", " ", s)
    return re.sub(r"\s+", " ", s).strip()


def codes(s):
    out = set()
    for m in re.finditer(r"\b([A-Za-z]{0,4}[- ]?\d+[A-Za-z0-9]*(?:-[A-Za-z0-9]+)*)\b", s):
        c = re.sub(r"[^A-Za-z0-9]", "", m.group(1)).upper()
        if len(c) >= 2 and not c.isdigit():
            out.add(c)
    return out


def words(s):
    return {w for w in norm(s).split() if len(w) > 1 and w not in STOP}


def strip_markup(v):
    v = re.sub(r"<ref[^>]*/>|<ref[^>]*>.*?</ref>", "", v, flags=re.S)
    v = re.sub(r"\{\{C\|([^}]*)\}\}", r"(\1)", v)
    v = re.sub(r"\{\{[^{}]*\}\}", "", v)
    v = re.sub(r"\[\[(?:[^|\]]*\|)?([^\]]*)\]\]", r"\1", v)
    v = re.sub(r"<br\s*/?>", "; ", v)
    v = re.sub(r"<[^>]+>|'''?|&mdash;", " ", v)
    v = re.sub(r"\n\*+", "; ", v).lstrip("*")
    return re.sub(r"\s+", " ", v).strip(" ;")


def infobox(text):
    m = re.search(r"\{\{\s*([A-Za-z ]+)\s*\n\|", text)
    tpl = m.group(1).strip().lower().replace(" ", "") if m else ""
    facts = {}
    if m:
        body = text[m.end() - 1:]
        for fm in re.finditer(r"\n\|\s*([a-z0-9 _]+?)\s*=(.*?)(?=\n\||\n\}\})", body[:20000], re.S):
            k = fm.group(1).strip().replace(" ", "")
            if k in FACTS and fm.group(2).strip():
                facts[k] = strip_markup(fm.group(2))[:300]
    return tpl, facts


class Wiki:
    def __init__(self):
        con = C.db_connect()
        self.path = {}
        self.by_norm = {}
        self.by_code = defaultdict(set)
        self.by_word = defaultdict(set)
        for title, path in con.execute("SELECT title, path FROM pages WHERE ns=0 AND path IS NOT NULL"):
            self.path[title] = path
            n = norm(title)
            if title.endswith("/Legends") or n not in self.by_norm:
                self.by_norm[n] = title
            for c in codes(title.replace("/Legends", "")):
                self.by_code[c].add(title)
            for w in words(title):
                self.by_word[w].add(title)
        self.cache = {}

    def info(self, title):
        if title not in self.cache:
            p = WIKI / "pages" / self.path[title]
            try:
                self.cache[title] = infobox(p.read_text(encoding="utf-8", errors="replace"))
            except OSError:
                self.cache[title] = ("", {})
        return self.cache[title]

    def suits(self, title, kind):
        tpl = self.info(title)[0]
        return bool(tpl) and any(x in tpl for x in TEMPLATES.get(kind, ()))


def variants(name, generic=False):
    m = re.match(r"^(.*?)\s*\((.*?)\)\s*$", name)
    if generic:
        v = [re.sub(r"^Typical\s+", "", m.group(2), flags=re.I)] if m else []
    else:
        v = [name] + ([m.group(1)] if m else [])
    out = []
    for x in v:
        x = x.strip(" ,")
        out.append(x)
        parts = x.split()
        for i in range(1, min(3, len(parts))):          # drop a leading manufacturer word or two
            out.append(" ".join(parts[i:]))
        if "," in x:                                    # "Blaster, heavy" -> "Heavy blaster"
            a, b = x.split(",", 1)
            out.append(b.strip() + " " + a.strip())
    seen, res = set(), []
    for x in out:
        if x and x not in seen:
            seen.add(x); res.append(x)
    return res


def match(w, name, kind):
    for v in variants(name):
        t = w.by_norm.get(norm(v))
        if t and w.suits(t, kind):
            return "exact", t, []
    cs = codes(name)
    if cs:
        hits = set()
        for c in cs:
            hits |= {t for t in w.by_code.get(c, ()) if w.suits(t, kind)}
        if len(hits) == 1:
            return "code", hits.pop(), []
        if hits:
            ws = words(name)
            ranked = sorted(hits, key=lambda t: (-len(ws & words(t)), len(t)))
            best = len(ws & words(ranked[0]))
            top = [t for t in ranked if len(ws & words(t)) == best]
            if len(top) == 1:
                return "code", top[0], ranked[1:4]
            return "multi", "", top[:5]
    for v in variants(name, generic=True):          # "(Typical Blaster Rifle)" -> the generic article
        t = w.by_norm.get(norm(v))
        if t and w.suits(t, kind):
            return "generic", t, []
    ws = words(name)
    if not ws:
        return "none", "", []
    pool = defaultdict(int)
    for x in ws:
        if len(w.by_word.get(x, ())) < 3000:
            for t in w.by_word[x]:
                pool[t] += 1
    scored = []
    for t, k in pool.items():
        if k < 2 and len(ws) > 1:
            continue
        tw = words(t)
        sc = len(ws & tw) / len(ws | tw)
        if sc >= 0.5:
            scored.append((sc, t))
    scored.sort(key=lambda x: (-x[0], len(x[1])))
    scored = [s for s in scored[:40] if w.suits(s[1], kind)][:5]
    if scored and scored[0][0] >= 0.6:
        if len(scored) > 1 and scored[1][0] == scored[0][0]:
            return "multi", "", [t for _, t in scored]
        return "words", scored[0][1], [t for _, t in scored[1:4]]
    return "none", "", [t for _, t in scored]


def load_choices():
    """Hand-confirmed matches from the local wiki's /match-review page: (source_file, name) -> chosen title ('-' = none)."""
    f = TAB / "wiki_match_choices.csv"
    if not f.exists():
        return {}
    return {(r["source_file"], r["name"]): r["chosen"] for r in csv.DictReader(open(f, encoding="utf-8"))}


def main():
    w = Wiki()
    choices = load_choices()
    rows, stats = [], defaultdict(lambda: defaultdict(int))
    for fn, kind in SOURCES.items():
        f = TAB / fn
        if not f.exists():
            continue
        for r in csv.DictReader(open(f, encoding="utf-8")):
            name = r.get("name", "").strip()
            if not name:
                continue
            how, title, cands = match(w, name, kind)
            ch = choices.get((fn, name))
            if ch:
                how, title = ("confirmed", ch) if ch != "-" else ("rejected", "")
                if title and title not in w.path:
                    how, title = "confirmed (missing)", ""
            tpl, facts = w.info(title) if title else ("", {})
            row = {"source_file": fn, "book": r.get("book", "SW_Revised_Core_Rulebook_WTC17650" if fn.startswith("core_") else ""),
                   "page": r.get("page", ""), "kind": kind, "name": name, "match": how, "wiki_title": title,
                   "wiki_template": tpl, "candidates": " | ".join(cands)}
            for k in FACTS:
                row["wiki_" + k] = facts.get(k, "")
            rows.append(row)
            stats[fn][how] += 1
    cols = list(rows[0].keys()) if rows else []
    used = [c for c in cols if not c.startswith("wiki_") or c in ("wiki_title", "wiki_template") or any(r[c] for r in rows)]
    with open(TAB / "wiki_match.csv", "w", newline="", encoding="utf-8") as fh:
        wr = csv.DictWriter(fh, fieldnames=used, extrasaction="ignore")
        wr.writeheader(); wr.writerows(rows)
    lines = ["%-20s %s" % (fn, "  ".join("%s %d" % (k, v) for k, v in sorted(s.items()))) for fn, s in stats.items()]
    tot = defaultdict(int)
    for s in stats.values():
        for k, v in s.items():
            tot[k] += v
    lines.append("TOTAL %d items: %s" % (sum(tot.values()), "  ".join("%s %d" % (k, v) for k, v in sorted(tot.items()))))
    (TAB / "wiki_match_summary.txt").write_text("\n".join(lines) + "\n", encoding="utf-8")
    print("\n".join(lines))


if __name__ == "__main__":
    main()
