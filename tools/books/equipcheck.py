#!/usr/bin/env python3
"""Check (and correct) the d20 equipment tables made by statblocks.py and coretables.py.

  equipcheck.py            apply tables/equipment_fixes.csv to the tables, then write tables/equipment_check.csv

Checks: every value looks like what its column should hold (dice, critical range, metres, kg, DC, damage type, size,
availability, cost), vehicle arithmetic (Defense = 10 + modifiers, Initiative/Maneuver = sum of modifiers), and that
every stat block in the book text made it into a table. Book errata confirmed against the page image go in the fixes
file with field 'erratum' (kept as printed, check line marked 'as printed in book').
Run after statblocks.py / coretables.py (./wiki.sh collate does this).
"""
import csv, re, sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import starships as SS                                   # noqa: E402  (shared arithmetic checks)

TAB = SS.TEXT / "tables"
FIXES = TAB / "equipment_fixes.csv"
AE = "SW_Arms_and_Equipment_Guide_WTC88664"
DICE = r"\d+d\d+(?:[+-]\d+)?(?:\s*[x×]\s*\d+)?"
SIZE = r"(Fine|Diminutive|Tiny|Small|Medium(-size)?|Large|Huge|Gargantuan|Colossal)"
AVAIL = r"(Prevalent|Common|Specialized|Rare|Military|Illegal|Restricted|Licensed|Unique|Black market)"
DTYPE = r"(Energy|Slashing|Piercing|Bludgeoning|Fire|Sonic|Ion|Acid|Cold|Electricity|Special|Varies|Energy/Ion|Slashing/Piercing|Piercing/Slashing|Bludgeoning/Piercing)"

SPEC = {   # column -> regex the whole value must match (case-insensitive); blank values are not checked here
    "weapon": {"Damage": r"(%s|Special|Varies|By grenade type|—|-)(\s*\(.*\))?(\s*(or|/)\s*(%s|special))?(\s*and special(\s*\(see text\))?)?" % (DICE, DICE),
               "Critical": r"(\d\d(-20)?(/x\d)?|x\d|—|-|n/a|Special|Varies|By grenade type)(\s*\(see text\)| and special| for .*)?",
               "Range Increment": r"(\d+(\.\d+)?\s*m|—|-|n/a|Special|Touch)(\s*\(.*\))?",
               "Weight": r"(\d+(\.\d+)?\s*kg|—|-|n/a|negligible|varies)(\s*\(.*\))?",
               "Fort DC": r"(\d+(/\d+)?|—|-|n/a)(\s*\([^)]*\))?( or \d+ \([^)]*\))?", "Type": "(By grenade type|" + DTYPE + r"(\s*(or|and|/|,)\s*%s)*(\s*\(.*\))?)" % DTYPE,
               "Size": SIZE + r"(\s*\(.*\))?", "Multifire/Autofire": r"(M|A|M/A|A/M|—|-|n/a|Single|S)( only)?",
               "Hardness": r"\d+|—|-", "WP": r"\d+|—|-", "Break DC": r"\d+|—|-",
               "Availability": r"%s(\s*,?\s*%s)*(\s*\(.*\))?" % (AVAIL, AVAIL),
               "Cost": r"([\d,]+(\s*\(.*\))?|Not available for sale|n/a|—|-|varies|Varies( by load)?)(\s*\(.*\))?(;\s*\+[\d,]+ for .*)?"},
    "armor": {"Damage Reduction": r"(\d+|—)(\s*\(.*\)| or \d+ against .*)?", "Maximum Dex Bonus": r"(\+\d+|—|-|n/a)", "Armor Check Penalty": r"(-?\d+|—|n/a)",
              "Speed": r"\d+\s*m\s*/\s*\d+\s*m(, fly \d+ m)?(\s*\((poor|clumsy|average|good|perfect)\))?", "Weight": r"\d+(\.\d+)?\s*kg", "Cost": r"[\d,]+(\s*\(.*\))?",
              "Availability": r"%s(\s*,?\s*%s)*" % (AVAIL, AVAIL)},
    "droid": {"Cost": r"[\d,]+(\s*\(.*\))?|Not available for sale.*", "Availability": r"%s(\s*,?\s*%s)*" % (AVAIL, AVAIL),
              "Classification": SIZE + r"\s+(first|second|third|fourth|fifth)-degree\s+.+"},
    "gear": {"Cost": r"[\d,]+(\s*\(.*\))?.*", "Weight": r"(\d+(\.\d+)?\s*kg|—|-|n/a|negligible)(\s*\(.*\))?",
             "Availability": r"%s(\s*,?\s*%s)*(\s*\(.*\))?" % (AVAIL, AVAIL)},
    "vehicle": {"Cost": r"([\d,]+(\s*\((new|used)[^)]*\))?(,?\s*[\d,]+\s*\((new|used)\))?|Not available for sale.*)",
                "Hull Points": r"[\d,]+(\s*\(DR\s*\d+\))?", "Shield Points": r"[\d,]+\*?|None|0",
                "Availability": r"%s(\s*,?\s*%s)*" % (AVAIL, AVAIL), "Size": SIZE + r"(\s*\(.*\))?"},
}
CORE = {"core_weapon": {"damage": r"(%s|\+\d+|See entry|Special|—|-)(/%s)?" % (DICE, DICE), "critical": r"(\d\d(-20)?|x\d|—|-)",
                        "range_increment": r"(\d+\s*m\*?(\s*\(\d+\s*m\))?|—|-)", "weight": r"(\d+(\.\d+)?\s*kg|—|-)",
                        "stun_fort_dc": r"((DC\s*)?\d+(/\d+)?|—|-|)", "damage_type": "(See entry|—|" + DTYPE + ")",
                        "size": SIZE + "|—", "cost": r"[\d,]+|—|-"},
        "core_armor": {"damage_reduction": r"\d+", "max_dex": r"\+\d+|—|-", "check_penalty": r"-?\d+|—",
                       "speed_10m": r"\d+", "speed_6m": r"\d+", "weight": r"\d+(\.\d+)?\s*kg", "cost": r"[\d,]+"},
        "core_equipment": {"cost": r"[\d,]+", "weight": r"(\d+(\.\d+)?\s*kg|—|-|)"},
        "core_tradegoods": {"cost": r"[\d,]+"}, "core_services": {"cost": r"[\d,]+"}}


def load(name):
    f = TAB / (name + ".csv")
    if not f.exists():
        return None, []
    with open(f, encoding="utf-8") as fh:
        r = csv.DictReader(fh)
        return r.fieldnames, list(r)


def save(name, cols, rows):
    for r in rows:
        for c in r:
            if c not in cols:
                cols.append(c)
    with open(TAB / (name + ".csv"), "w", newline="", encoding="utf-8") as fh:
        w = csv.DictWriter(fh, fieldnames=cols)
        w.writeheader(); w.writerows(rows)


def apply_fixes(name, rows):
    if not FIXES.exists():
        return
    for fx in sorted(csv.DictReader(open(FIXES, encoding="utf-8")), key=lambda f: f["field"] == "name"):   # renames last
        if fx["table"] != name:
            continue
        hit = [r for r in rows if r.get("name") == fx["name"] and (not fx.get("page") or str(r.get("page", "")) == fx["page"]
                                                                  or "page" not in r)]
        if fx["field"] == "__add__" and not hit:
            new = dict(kv.split("=", 1) for kv in fx["value"].split("|"))
            new.update(name=fx["name"], fixed="added")
            if "page" in rows[0]:
                new["page"] = fx["page"]
            if "book" in rows[0]:
                new.setdefault("book", AE)
            rows.append(new)
            continue
        for r in hit:
            if fx["field"] == "__delete__":
                r["__delete__"] = 1
            elif fx["field"] == "erratum":
                r["erratum"] = fx["value"]
            else:
                r[fx["field"]] = fx["value"]
                r["fixed"] = ";".join(x for x in [r.get("fixed", ""), fx["field"]] if x)
    rows[:] = [r for r in rows if not r.get("__delete__")]


NEED = {"weapon": ["Cost", "Damage", "Critical", "Weight", "Type", "Size", "Availability"],
        "armor": ["Cost", "Damage Reduction", "Maximum Dex Bonus", "Armor Check Penalty", "Speed", "Weight", "Availability"],
        "droid": ["Cost", "Classification", "Availability"], "gear": ["Cost", "Availability"],
        "vehicle": ["Cost", "Class", "Size", "Crew", "Defense", "Hull Points"]}


def check_row(kind, r, spec):
    out = ["missing " + k for k in NEED.get(kind, []) if not (r.get(k) or "").strip()]
    for col, rx in spec.items():
        v = (r.get(col) or "").strip()
        if v and not re.fullmatch(rx, v, re.I):
            out.append("%s odd: %r" % (col, v[:80]))
    if kind == "vehicle":
        out += [p for p in SS.checks(r) if not p.startswith("missing ") or p in ("missing Cost",)]
    return out


KEY_PAGES = {"weapon": (5,), "armor": (39,)}       # checked 2026-10-12: these pages explain the stat lines


def completeness():
    """Stat blocks in the A&E text that no table row came from."""
    out = []
    t = (SS.TEXT / AE / (AE + ".txt")).read_text(encoding="utf-8", errors="replace")
    p = re.split(r"=== Page (\d+) ===", t)
    pages = {int(p[i]): p[i + 1] for i in range(1, len(p), 2)}
    for name, lab in (("weapon", r"Weapon Type"), ("armor", r"Arm\w{1,2}r Type"), ("droid", r"Classification")):
        _, rows = load(name)
        have = {}
        for r in rows:
            if r.get("book") == AE:
                have[int(r["page"])] = have.get(int(r["page"]), 0) + 1
        for pg, tx in sorted(pages.items()):
            n = len(re.findall(r"(?<![A-Za-z])%s\s*[:;]" % lab, tx))
            if pg in KEY_PAGES.get(name, ()):
                continue                                   # the book's own 'how to read an entry' key
            if n > have.get(pg, 0):
                out.append(dict(table=name, book=AE, page=pg, name="", problem="page has %d '%s' blocks, table has %d"
                                % (n, lab.replace("\\w{1,2}", "o"), have.get(pg, 0))))
    return out


def main():
    C = []
    for name in ("weapon", "armor", "droid", "gear", "vehicle", "core_vehicle"):
        cols, rows = load(name)
        if not rows:
            continue
        apply_fixes(name, rows)
        kind = "vehicle" if name == "core_vehicle" else name
        for r in rows:
            probs = check_row(kind, r, SPEC.get(kind, {}))
            if r.get("erratum"):
                probs = ["as printed in book: " + x for x in probs] or ["note: " + r["erratum"]]
            r["check"] = "; ".join(probs)
            C += [dict(table=name, book=r.get("book", ""), page=r.get("page", ""), name=r.get("name", ""), problem=x) for x in probs]
        save(name, cols, rows)
    for name, spec in CORE.items():
        cols, rows = load(name)
        if not rows:
            continue
        apply_fixes(name, rows)
        for r in rows:
            probs = check_row(name, r, spec)
            if r.get("ocr_fixed") == "1":
                probs.append("OCR-repaired value: recheck (%s)" % (r.get("raw", "")[:60].strip()))
            if r.get("erratum"):
                probs = ["as printed in book: " + x for x in probs] or ["note: " + r["erratum"]]
            r["check"] = "; ".join(probs)
            C += [dict(table=name, book="SW_Revised_Core_Rulebook_WTC17650", page=r.get("table", ""), name=r.get("name", ""),
                       problem=x) for x in probs]
        save(name, cols, rows)
    C += completeness()
    with open(TAB / "equipment_check.csv", "w", newline="", encoding="utf-8") as fh:
        w = csv.DictWriter(fh, fieldnames=["table", "book", "page", "name", "problem"])
        w.writeheader(); w.writerows(C)
    print("equipment_check.csv %d lines" % len(C))


if __name__ == "__main__":
    main()
