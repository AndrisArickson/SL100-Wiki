#!/usr/bin/env python3
"""Pull d20 creature stat lines out of every extracted book (2026-10-12).

  creatures.py            -> Source_Text/tables/d20_creatures.csv + creature_check.csv

A creature line starts 'Name: <Size> <description> <HD>; Init +n (...); Defense n (...); Spd ...; VP/WP a/b; Atk ...;
... SV Fort +n, Ref +n, Will +n; SZ x; ... Str n, Dex n, Con n, Int n, Wis n, Cha n. Challenge Code X.'
(Character and droid lines name a class instead of a size and are skipped.) Raw d20 values, OCR slips repaired in the
numbers ('|' or 'l' for 1, 'O' for 0, '=' or '~' for minus). Checks: all six abilities present and plausible,
VP/WP present, Defense = 10 + its listed modifiers, size code matches the size word.
"""
import csv, re, sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import starships as SS                                    # noqa: E402

TAB = SS.TEXT / "tables"
SIZES = "Fine|Diminutive|Tiny|Small|Medium-size|Medium|Large|Huge|Gargantuan|Colossal"
SZ = {"Fine": "F", "Diminutive": "D", "Tiny": "T", "Small": "S", "Medium-size": "M", "Medium": "M", "Large": "L",
      "Huge": "H", "Gargantuan": "G", "Colossal": "C"}
CTYPE = r"(?:predator|herd animal|scavenger|vermin|parasite|beast|animal|mount|pet|avian|herbivore|omnivore|insect|creature|monster|dragon|worm|serpent|carnivore|grazer|forager|crustacean)"
HEAD = re.compile(r"(?:(?<=[.\s])|^)(?:(?:SQ|SA|SV|B)\s+[A-Za-z]+\s+)?([A-Z][A-Za-z'’ -]{2,40}?)\s*[:;]\s*(?:(%s)\s+)?([A-Za-z][a-z /,()-]{0,50}?%s[a-z]*)\s+(\d{1,2})\s*[;:,]\s*Init"
                  % (SIZES, CTYPE))


def fixnum(s):
    s = re.sub(r"\blnt\b", "Int", s)
    s = re.sub(r"(?<=[\s(+/-])[|lI](?=[\d\s,;)/])", "1", s)
    s = re.sub(r"(?<=\d)O|O(?=\d)", "0", s)
    return re.sub(r"(?<=[\s(,])[=~—–](?=\s*\d)", "-", s)


def grab(rx, s):
    m = re.search(rx, s)
    return m.group(1).strip(" ;,.") if m else ""


def parse(slug):
    d = SS.TEXT / slug
    f = d / (slug + ".raw.txt") if (d / (slug + ".raw.txt")).exists() else d / (slug + ".txt")
    if not f.exists():
        return []
    s = SS.stream(f.read_text(encoding="utf-8", errors="replace"))
    out = []
    for m in HEAD.finditer(s):
        end = s.find("Challenge Code", m.end())
        if end < 0 or end - m.end() > 1500:
            continue
        b = fixnum(SS.clean(s[m.start():end + 17]))
        r = dict(book=slug, page=SS.page_at(s, m.start()), name=m.group(1).strip(), size=m.group(2) or "",
                 type=m.group(3).strip(), level=m.group(4),
                 init=grab(r"Init\s*([+-]?\s*\d+[^;]*)", b), defense=grab(r"Defense\s*(\d+[^;]*)", b),
                 speed=grab(r"Spd\s*([^;]+)", b), vp_wp=grab(r"VP\s*/\s*WP\s*([\d—-]+\s*/\s*\d+)", b),
                 attack=grab(r"Atk\s*([^;]+)", b), special=grab(r"S[AQ]\s+([^;]+(?:;\s*SQ[^;]+)?)", b),
                 saves=grab(r"SV\s*(Fort[^;]+)", b), sz=grab(r"SZ\s*([A-Z])\b", b),
                 face_reach=grab(r"Face\s*/\s*Reach\s*([^;]+)", b), challenge=grab(r"Challenge Code\s*:?\s*([A-Z])", b + " "))
        for a in ("Str", "Dex", "Con", "Int", "Wis", "Cha"):
            r[a] = grab(r"\b%s\s*(\d+|—|-)" % a, b)
        out.append(r)
    return out


def check(r):
    p = []
    for a in ("Str", "Dex", "Con", "Int", "Wis", "Cha"):
        v = r[a]
        if not v:
            p.append("missing " + a)
        elif v.isdigit() and not 1 <= int(v) <= 60:
            p.append("%s out of range: %s" % (a, v))
    if not r["vp_wp"]:
        p.append("missing VP/WP")
    tot, parts = SS.mods(r["defense"])
    if tot is not None and parts and tot != 10 + sum(parts):
        p.append("Defense %s != 10 + %s" % (tot, sum(parts)))
    if not r["size"] and r["sz"]:
        r["size"] = {v: k for k, v in SZ.items() if k != "Medium"}.get(r["sz"], "")
    if r["sz"] and r["size"] and SZ.get(r["size"]) != r["sz"]:
        p.append("SZ %s but size %s" % (r["sz"], r["size"]))
    if not r["challenge"]:
        p.append("missing Challenge Code")
    return p


def main():
    rows = []
    for d in sorted(SS.TEXT.glob("SW_*")):
        rows += parse(d.name)
    fx = TAB / "creature_fixes.csv"
    for f in (csv.DictReader(open(fx, encoding="utf-8")) if fx.exists() else []):
        for r in rows:
            if r["book"] == f["book"] and r["name"] == f["name"]:
                if f["field"] == "erratum":
                    r["erratum"] = f["value"]
                else:
                    r[f["field"]] = f["value"]
                    r["fixed"] = ";".join(x for x in [r.get("fixed", ""), f["field"]] if x)
    seen, C = set(), []
    for r in rows:
        r["dup_of"] = "" if (r["name"].lower(), r["level"]) not in seen else "yes"
        seen.add((r["name"].lower(), r["level"]))
        p = check(r)
        if r.get("erratum"):
            p = ["as printed in book: " + x for x in p] or ["note: " + r["erratum"]]
        r["check"] = "; ".join(p)
        C += [dict(book=r["book"], page=r["page"], name=r["name"], problem=x) for x in p]
    cols = []
    for r in rows:
        cols += [c for c in r if c not in cols]
    with open(TAB / "d20_creatures.csv", "w", newline="", encoding="utf-8") as fh:
        w = csv.DictWriter(fh, fieldnames=cols); w.writeheader(); w.writerows(rows)
    with open(TAB / "creature_check.csv", "w", newline="", encoding="utf-8") as fh:
        w = csv.DictWriter(fh, fieldnames=["book", "page", "name", "problem"]); w.writeheader(); w.writerows(C)
    import collections
    for b, n in collections.Counter(r["book"] for r in rows).most_common():
        print("%-60s %3d" % (b, n))
    print("d20_creatures.csv %d rows; creature_check.csv %d lines" % (len(rows), len(C)))


if __name__ == "__main__":
    main()
