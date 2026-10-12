#!/usr/bin/env python3
"""Parse the column-style equipment tables of the d20 Revised Core Rulebook (weapons, armour, equipment, trade goods).

  coretables.py run     writes Source_Text/tables/core_weapon.csv, core_armor.csv, core_equipment.csv, core_tradegoods.csv
Raw d20 numbers as printed; obvious OCR slips are repaired (1dé -> 1d6) and the row gets ocr_fixed=1 so you can recheck it.
Rows that do not parse cleanly are listed in tables/core_unparsed.txt.
"""
import csv, os, re, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent.parent.parent
TEXT = Path(os.environ.get("SL100_TEXT_DIR", ROOT / "Source_Text"))
SRC = TEXT / "SW_Revised_Core_Rulebook_WTC17650" / "SW_Revised_Core_Rulebook_WTC17650.txt"
OUT = TEXT / "tables"
NUM = r"\d[\d,]*"
SIZES = r"(?:Fine|Diminutive|Tiny|Small|Medium(?:-size)?|Large|Huge|Gargantuan|Colossal)"


def fix_dice(s):
    n = s
    n = re.sub(r"(\d)d[é€e]\b", r"\1d6", n)
    n = re.sub(r"(\d)d[sS]\b", r"\1d8", n)
    n = re.sub(r"(?<=\d)[°¢°¢'’]+$", "", n)
    return n, n != s


def clean(s):
    return re.sub(r"[®¢°]+", "", s).strip(" ·.|")


def find_table(lines, header, start_after=0, nth=None):
    idx = [i for i, l in enumerate(lines) if l.strip().startswith(header) and i > start_after]
    return idx


def weapons(lines):
    rows, bad = [], []
    # the second "Table 7-2: Weapons" line is the table itself
    idx = [i for i, l in enumerate(lines) if l.strip() == "Table 7-2: Weapons"]
    if not idx:
        return rows, ["table 7-2 header not found"]
    i0 = idx[-1]
    cat = ""
    for ln in lines[i0 + 1: i0 + 120]:
        s = ln.strip()
        if s.startswith("®") or s.startswith("b See") or re.match(r"^[ab€]\s+(A|See)", s):
            if cat == "Ranged Weapons" or len(rows) > 40:
                break
        if s in ("Melee Weapons", "Ranged Weapons"):
            cat = s; continue
        if not s or s.startswith(("Range", "Weapon", "Stun", "Multifire")):
            continue
        m = re.match(r"^(?P<name>.+?)\s+(?P<cost>%s|-|—)\s+(?P<rest>.+)$" % NUM, s)
        if not m or not re.search(r"k[gq]\b|\d\s?m\b", m.group("rest")):
            if len(s) < 120 and re.search(r"\d", s):
                bad.append(s)
            continue
        rest = m.group("rest")
        t = rest.split()
        dmg, fixed = fix_dice(t[0]) if t else ("", False)
        wm = re.search(r"(\d+(?:\.\d+)?)\s?k[gq]", rest)
        weight = wm.group(0).replace("kq", "kg") if wm else ""
        crit = next((x for x in t[1:3] if re.fullmatch(r"\d{2}(?:-\d{2})?|-|—", x)), "")
        rng = next((x for x in t[1:5] if re.fullmatch(r"\d+\s?[ma]{1,2}\S*|\d+m.*", x)), "")
        dc = re.search(r"DC\s?\d+(?:/\d+)?", rest)
        sz = re.search(SIZES, rest, re.I)
        typ = re.search(r"Bludgeoning|Slashing/piercing|Slashing|Piercing|Energy|Seeentry", rest)
        last = rest.split()[-1] if rest.split() else ""
        grp = next((g for g in ("Blaster pistols", "Blaster rifles", "Slugthrowers", "Simple", "Exotic", "Primitive", "Vibro", "Heavy", "None")
                    if g.lower().startswith(last.lower()[:4]) or last.lower().startswith(g.lower()[:4])), last)
        if grp == "Blaster pistols" and "rifle" in m.group("name").lower():
            grp = "Blaster rifles"
        rows.append(dict(table="7-2", category=cat, name=clean(m.group("name")), cost=m.group("cost").replace(",", ""), damage=dmg,
                         critical=crit, range_increment=rng, weight=weight, stun_fort_dc=dc.group(0) if dc else "",
                         damage_type=typ.group(0) if typ else "", size=sz.group(0).capitalize() if sz else "",
                         group=grp, ocr_fixed=int(fixed), raw=s))
    return rows, bad


def armor(lines):
    rows, bad = [], []
    idx = [i for i, l in enumerate(lines) if re.match(r"^Table 7-3: Arm\w+$", l.strip())]
    if not idx:
        return rows, ["table 7-3 header not found"]
    cat = ""
    for ln in lines[idx[-1] + 1: idx[-1] + 40]:
        s = ln.strip()
        if s.startswith("*"):
            break
        if re.fullmatch(r"(Light|Medium|Heavy|Powered) Armor", s):
            cat = s; continue
        m = re.match(r"^(?P<name>.+?)\s+(?P<cost>%s)\s+(?P<dr>\d|-|=|—)\s+(?P<dex>[+\-]\d|\+?0)\s+(?P<acp>[-=+]?\d|-)\s+(?P<s10>\w+)\s+(?P<s6>\w+)\s+(?P<wt>[\d.]+\s?kg)$" % NUM, s)
        if not m:
            if re.search(r"\d", s) and len(s) < 120 and not s.startswith(("Damage", "Armor ")):
                bad.append(s)
            continue
        acp = m.group("acp").replace("=", "-")
        rows.append(dict(table="7-3", category=cat, name=clean(m.group("name")), cost=m.group("cost").replace(",", ""),
                         damage_reduction=m.group("dr").replace("=", "-"), max_dex=m.group("dex"), check_penalty=acp,
                         speed_10m=m.group("s10"), speed_6m=m.group("s6"), weight=m.group("wt") or "", raw=s))
    return rows, bad


def simple(lines, header, name_col):
    rows, bad = [], []
    idx = [i for i, l in enumerate(lines) if l.strip() == header]
    if not idx:
        return rows, ["%s header not found" % header]
    i0 = idx[-1]
    sec = ""
    blank_run = 0
    for ln in lines[i0 + 1: i0 + 420]:
        s = ln.strip()
        if s.startswith("=== Page"):
            if header.endswith("Services") and rows:
                break
            continue
        if re.match(r"^Table \d+-\d+:", s) and rows:
            break
        if s.startswith("=== Page") and header.endswith("Services"):
            break
        m = re.match(r"^(?P<name>.+?)\s+(?P<cost>%s|-|—)(?:\s+(?P<wt>[\d.]+\s?k[gq]|[-—]))?(?:\s+credits)?\s*$" % NUM, s)
        if m and not m.group("wt") and header.endswith("Equipment"):
            m = None
        if not m:
            if s and len(s) < 60 and not re.search(r"\d", s) and not s.startswith(name_col):
                sec = s
            elif s and re.search(r"\d", s) and len(s) < 100 and not s.startswith(name_col):
                bad.append(s)
            continue
        rows.append(dict(table=header[:9], section=sec, name=clean(m.group("name")), cost=m.group("cost").replace(",", ""),
                         weight=m.group("wt") or "", raw=s))
    return rows, bad


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
    print("%-18s %3d rows" % (name, len(rows)))


def main():
    lines = SRC.read_text(encoding="utf-8", errors="replace").split("\n")
    allbad = []
    for name, fn in (("core_weapon", weapons), ("core_armor", armor),
                     ("core_equipment", lambda L: simple(L, "Table 7-4: Equipment", "Item")),
                     ("core_tradegoods", lambda L: simple(L, "Table 7-1: Trade Goods", "Item")),
                     ("core_services", lambda L: simple(L, "Table 7-5: Services", "Item"))):
        checked = OUT / (name + "_checked.csv")   # hand-transcribed from the page image (2026-10-12): wins over the OCR parse
        if checked.exists():
            import shutil
            shutil.copyfile(checked, OUT / (name + ".csv"))
            print("%-16s from %s (hand-checked)" % (name, checked.name))
            continue
        rows, bad = fn(lines)
        write(name, rows)
        allbad += ["[%s] %s" % (name, b) for b in bad]
    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / "core_unparsed.txt").write_text("\n".join(allbad) + "\n", encoding="utf-8")
    print("unparsed lines for review: %d (tables/core_unparsed.txt)" % len(allbad))


if __name__ == "__main__":
    main()
