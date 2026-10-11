#!/usr/bin/env python3
"""Parse run-in starship stat blocks ("Craft: X-wing; Class: Starfighter; Cost: ...; Hull Points: 90; DR: 5.") and their
following "Weapon: ...; Fire Arc: ...; Attack Bonus: ...; Damage: ..." paragraphs from every extracted book.

  starships.py run [SLUG ...]     default: every book that contains "Craft:"
Writes Source_Text/tables/starship.csv and starship_weapons.csv (raw d20 values; typos from OCR left as printed,
rows with missing key fields get a 'check' note).
"""
import csv, os, re, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent.parent.parent
TEXT = Path(os.environ.get("SL100_TEXT_DIR", ROOT / "Source_Text"))
OUT = TEXT / "tables"
LABELS = ["Craft", "Class", "Cost", "Size", "Initiative", "Crew", "Passengers", "Cargo Capacity", "Consumables", "Hyperdrive",
          "Nav Computer", "Maximum Speed", "Atmospheric Speed", "Max Speed", "Maneuver", "Defense", "Shield Points", "Hull Points", "DR",
          "Availability", "Type", "Weapon", "Fire Arc", "Attack Bonus", "Damage", "Range Modifiers", "Range Increment", "Speed", "Altitude"]
LABELS.sort(key=len, reverse=True)
FIELD_RE = re.compile(r"(?<![A-Za-z])(%s)\s*:\s*" % "|".join(re.escape(l) for l in LABELS))
SHIP_KEYS = ["Cost", "Hull Points", "Maneuver", "Shield Points"]


def paragraphs(txt):
    """Yield (page, paragraph_text) with hyphenated line breaks repaired."""
    page = 0
    for block in re.split(r"\n\s*\n", txt):
        m = re.search(r"=== Page (\d+) ===", block)
        if m:
            page = int(m.group(1))
            block = re.sub(r"=== Page \d+ ===\n?", "", block)
        b = re.sub(r"-\n(?=[a-z])", "", block)
        b = re.sub(r"\s*\n\s*", " ", b).strip()
        if b:
            yield page, b


def fields(text):
    pos = [(m.start(), m.end(), m.group(1).strip()) for m in FIELD_RE.finditer(text)]
    out = {}
    for i, (s, e, k) in enumerate(pos):
        v = text[e: pos[i + 1][0] if i + 1 < len(pos) else len(text)].strip(" ;:.,")
        if k not in out:
            out[k] = re.sub(r"\s+", " ", v)
    return out


def num(v):
    m = re.search(r"\d[\d,]*", v or "")
    return m.group(0).replace(",", "") if m else ""


def parse_book(slug):
    f = TEXT / slug / (slug + ".txt")
    if not f.exists():
        return [], []
    ships, weps = [], []
    cur = None
    for page, p in paragraphs(f.read_text(encoding="utf-8", errors="replace")):
        if p.startswith("Craft:"):
            d = fields(p)
            d["Craft"] = re.sub(r"\s+", " ", d.get("Craft", ""))
            row = dict(book=slug, page=page, name=d.get("Craft", ""), **{k: v for k, v in d.items() if k != "Craft"})
            row["cost_cr"] = num(d.get("Cost"))
            if "Hull Points" not in d and "Defense" not in d and "Maneuver" not in d:
                continue                       # not a d20 stat block (e.g. West End Games d6 entry)
            miss = [k for k in SHIP_KEYS if not d.get(k)]
            row["check"] = ",".join("missing " + k for k in miss)
            ships.append(row); cur = d.get("Craft")
        elif p.startswith("Weapon:") and cur:
            d = fields(p)
            w = dict(book=slug, page=page, ship=cur, weapon=d.get("Weapon", ""), **{k: v for k, v in d.items() if k != "Weapon"})
            weps.append(w)
        else:
            if cur and not p.startswith("Weapon"):
                cur = None if len(p) > 80 else cur
    return ships, weps


def write(name, rows):
    if not rows:
        return
    OUT.mkdir(parents=True, exist_ok=True)
    cols = []
    for r in rows:
        for c in r:
            if c not in cols:
                cols.append(c)
    with open(OUT / (name + ".csv"), "w", newline="", encoding="utf-8") as fh:
        w = csv.DictWriter(fh, fieldnames=cols)
        w.writeheader(); w.writerows(rows)
    print("%-20s %4d rows" % (name, len(rows)))


def main(slugs):
    if not slugs:
        slugs = [d.name for d in sorted(TEXT.glob("SW_*")) if (d / (d.name + ".txt")).exists()
                 and "Craft:" in (d / (d.name + ".txt")).read_text(encoding="utf-8", errors="replace")]
    S, W = [], []
    for s in slugs:
        a, b = parse_book(s)
        if a:
            print("%-60s %3d ships %3d weapons" % (s, len(a), len(b)))
        S += a; W += b
    write("starship", S); write("starship_weapons", W)


if __name__ == "__main__":
    a = sys.argv[1:]
    main(a[1:] if a and a[0] == "run" else a)
