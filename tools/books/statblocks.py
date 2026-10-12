#!/usr/bin/env python3
"""Pull labelled stat blocks (weapons, armour, vehicles/starships, gear) out of extracted d20 book text.

  statblocks.py run [SLUG ...]     default: Arms and Equipment Guide
  statblocks.py check SLUG         print 8 random parsed entries for eyeballing
  STATBLOCK_PREFIX=core_ statblocks.py run SW_Revised_Core_Rulebook_WTC17650   -> tables/core_vehicle.csv (keeps other books' files)

Output (copyrighted data, stays outside git): Source_Text/tables/<kind>.csv  with columns
book, page, name, kind, then one column per label found; plus tables/_unparsed.txt (suspect entries).
Pure standard library. Values are kept as printed (raw d20 numbers); conversion to SL100 is a later step.
"""
import csv, os, random, re, sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
ROOT = HERE.parent.parent.parent                        # .../SL100
TEXT = Path(os.environ.get("SL100_TEXT_DIR", ROOT / "Source_Text"))
OUT = TEXT / "tables"

LABELS = ["Weapon Type", "Armor Type", "Proficiency Group", "Cost", "Damage", "Critical", "Weight", "Type", "Fort DC", "Size",
          "Hardness", "WP", "Break DC", "Availability", "Era", "Range Increment", "Rate of Fire", "Multifire/Autofire", "Special", "Class", "Classification",
          "Equipment Bonus", "Maximum Dex Bonus", "Max Dex Bonus", "Armor Check Penalty", "Speed", "Damage Reduction", "Defense",
          "Crew", "Passengers", "Cargo Capacity", "Consumables", "Hull Points", "Shield Points", "Maneuver", "Initiative",
          "Max Velocity", "Atmospheric Speed", "Altitude", "Move", "Max Load", "Arc", "Attack Bonus", "Increment", "Strength Augmentation",
          "Computerized Targeting", "Hyperdrive", "Maximum Speed in Space", "Weapon", "Weapons", "Fire Arc", "Range Modifiers", "Repulsorlift", "Comlink", "Powerlamp", "Sensors", "Life Support", "Bonus", "Skills", "Feats", "Equipment"]
LABELS.sort(key=len, reverse=True)
LAB_RE = re.compile(r"(?<![A-Za-z])(%s)\s*:" % "|".join(re.escape(l) for l in LABELS))
ANCHORS = {"Weapon Type": "weapon", "Armaor Type": "armor", "Armor Type": "armor"}
ERA_NOISE = re.compile(r"\bEra\s*:.*$")


def kind_of(zone):
    if re.search(r"Class\s*:\s*The (starship|vehicle)", zone):   # the book's own "how to read a stat block" key
        return None
    keys = set(m.group(1) for m in LAB_RE.finditer(zone))
    if "Weapon Type" in keys:
        return "weapon"
    if "Armor Type" in keys or "Damage Reduction" in keys and "Maximum Dex Bonus" in keys:
        return "armor"
    if keys & {"Hull Points", "Shield Points", "Classification", "Cargo Capacity", "Max Velocity"}:
        return "vehicle"
    if "Cost" in keys and ("Availability" in keys or "Weight" in keys):
        return "gear"
    return None


def is_heading(line):
    s = line.strip()
    return bool(s) and len(s) < 70 and ":" not in s and not s.endswith((".", ",")) and len(s.split()) <= 9 and not s.isdigit()


def parse_zone(zone):
    zone = zone.replace("\n", "  ")
    pos = [(m.start(), m.end(), m.group(1)) for m in LAB_RE.finditer(zone)]
    out = {}
    weps, cur = [], None                             # every 'Weapon:' line of a vehicle, not just the first (2026-10-12)
    WEP_KEYS = ("Fire Arc", "Arc", "Attack Bonus", "Bonus", "Damage", "Range Increment", "Increment", "Range Modifiers")
    for i, (s, e, lab) in enumerate(pos):
        val = zone[e:pos[i + 1][0] if i + 1 < len(pos) else len(zone)]
        val = re.sub(r"\s{2,}", " ", val)
        val = re.sub(r"\s*\bEra\w{0,3}\W{0,3}.*$", "", val) if lab != "Era" else ""   # era icons do not OCR; drop them and what follows
        val = val.strip(" ;,|")
        if lab == "Era":
            continue
        if lab == "Weapons":
            lab = "Weapon"
        if lab == "Weapon":
            cur = {"weapon": re.sub(r"\s*[;*].*$", "", val)}
            weps.append(cur)
        elif cur is not None and lab in WEP_KEYS:
            k = {"Arc": "Fire Arc", "Bonus": "Attack Bonus", "Increment": "Range Increment"}.get(lab, lab)
            cur.setdefault(k, re.sub(r"\s*\*(Provides|These|When).*$|;\s*Range$", "", val))
        if lab not in out:
            out[lab] = clean_value(lab, val)
    # A&E vehicles print 'Cost: 20,000 (new)' then the used price at the end of the next line, which follows
    # 'Shield Points: 0' in the OCR: move it back to Cost.
    if weps:
        out["_weapons"] = [w for w in weps if w["weapon"] and not w["weapon"].lower().startswith("none")]
    m = re.match(r"(.*?)\s*\((poor|clumsy|average|good|perfect)\)$", out.get("Weight", ""))
    if m and "fly" in out.get("Speed", "") and "(" not in out.get("Speed", ""):     # fly manoeuvrability wrapped under Weight
        out["Weight"], out["Speed"] = m.group(1), out["Speed"] + " (%s)" % m.group(2)
    m = re.match(r"([\d,]+|None)\s+([\d,]+\s*\(used\))", out.get("Shield Points", ""))
    if m:
        out["Shield Points"] = m.group(1)
        out["Cost"] = (out.get("Cost", "") + ", " + m.group(2)).strip(", ")
    m = re.match(r"(.*?\(DR\s*\d+\))\s*(\w+)$", out.get("Hull Points", ""))
    if m and m.group(2) in ("restricted", "licensed", "military", "illegal"):
        out["Hull Points"] = m.group(1)
        out["Availability"] = (out.get("Availability", "") + ", " + m.group(2)).strip(", ")
    return out


# Values that are short by nature: keep the leading valid part, drop what OCR ran on into (era icons such as
# 'era® P @', the start of the next paragraph). Added 2026-10-12 with tools/books/equipcheck.py.
SHORT = {"Cost": r"[\d,]+(?:\s*\((?:new|used)[^)]*\))?(?:,?\s*[\d,]+\s*\(used\))?(?:;\s*\+[\d,]+ for [a-z ]+)?|Not available for sale(?: \([^)]*\))?|Varies by load|varies|—",
         "Weight": r"\d+(?:\.\d+)?\s*kg?(?:\s*\([^)]*\))?|—|negligible",
         "Break DC": r"\d+|—", "WP": r"\d+|—", "Hardness": r"\d+|—", "Fort DC": r"\d+(?:/\d+)?(?:\s*\([^)]*\))?(?: or \d+ \([^)]*\))?|—",
         "Critical": r"\d\d(?:-20)?(?: \(see text\)| and special| for [A-Z0-9-]+, \d\d-20 for [A-Z0-9-]+)?|x\d|—|Varies|By grenade type",
         "Size": r"(?:Fine|Diminutive|Tiny|Small|Medium(?:-size)?|Large|Huge|Gargantuan|Colossal)(?:\s*\([^)\[]*\)?)?",
         "Availability": r"(?:Prevalent|Common|Specialized|Rare|Military|Illegal|lllegal|Restricted|Licensed|Unique)(?:,\s*(?:licensed|restricted|military|illegal|milita\w*))*",
         "Multifire/Autofire": r"M/A only|M/A|A/M|M|A|—|Single"}


def clean_value(lab, val):
    rx = SHORT.get(lab)
    if not rx:
        return val
    m = re.match(r"\s*(%s)" % rx, val)
    v = m.group(1).strip() if m else val
    if lab == "Weight":
        v = re.sub(r"(?<=\d)\s*k$", " kg", v)
    if lab == "Availability":
        v = v.replace("lllegal", "Illegal").replace("milita,", "military,")
        v = re.sub(r"milita\w*$", "military", v)
    if lab == "Size":
        v = re.sub(r"\s*\($", "", v)
        if v.count("(") > v.count(")"):
            v += ")"
    return v


def fix_name(n):
    for a, b in (("Armaor", "Armor"), ("Maodel", "Model"), ("Madel", "Model"), ("|", "-")):
        n = n.replace(a, b)
    import ocrfix                                   # shared OCR name repairs (Pistaol, lon, lkas-Adno, ...)
    return ocrfix.fix_name(re.sub(r"\s{2,}", " ", n).strip())


def kind_final(kind, zone):
    if kind == "vehicle" and re.search(r"Classification\s*:", zone) and not re.search(r"Hull Points|Shield Points", zone):
        return "droid"
    return kind


def num(v):
    m = re.search(r"\d[\d,]*(?:\.\d+)?", v or "")
    return m.group(0).replace(",", "") if m else ""


KEYS = {"weapon": ["Damage", "Cost"], "armor": ["Cost", "Damage Reduction"], "vehicle": ["Cost"], "droid": ["Cost", "Classification"], "gear": ["Cost"]}


def entries(slug):
    d = TEXT / slug / "pages"
    res = []
    for pf in sorted(d.glob("*.txt")):
        page = int(pf.stem)
        lines = pf.read_text(encoding="utf-8", errors="replace").split("\n")
        # first stat label line of each block = a line starting with a known label, preceded by a heading
        starts = []
        for i, ln in enumerate(lines):
            m = LAB_RE.match(ln.strip())
            if not m:
                continue
            if m.group(1) in ("Weapon Type", "Armor Type", "Armaor Type", "Classification", "Class") or (
                    m.group(1) == "Cost" and (i == 0 or not LAB_RE.search(lines[i - 1]))) or m.group(1) in ("Proficiency Group",):
                # heading = nearest previous heading-looking line within 3 lines
                h = None
                for j in range(i - 1, max(-1, i - 4), -1):
                    if is_heading(lines[j]):
                        h = j; break
                    if lines[j].strip() and LAB_RE.search(lines[j]):
                        break
                if h is not None and (not starts or h > starts[-1][0] + 0):
                    if not starts or starts[-1][0] != h:
                        starts.append((h, i))
        def full_heading(h):
            parts = [lines[h].strip()]
            while h > 0 and len(parts) < 3 and is_heading(lines[h - 1]) and not LAB_RE.search(lines[h - 1]):
                h -= 1
                parts.insert(0, lines[h].strip())
            if len(parts) > 1 and len(parts[0].split()) > 6:    # earlier line was likely prose
                parts = parts[1:]
            return " ".join(parts)
        for k, (h, i) in enumerate(starts):
            end = starts[k + 1][0] if k + 1 < len(starts) else len(lines)
            block = lines[i:end]
            zone_lines = []
            for ln in block:
                s = ln.strip()
                if s and not LAB_RE.search(s) and len(s.split()) >= 9 and zone_lines:
                    seen = LAB_RE.findall("\n".join(zone_lines))
                    if ("Cost" in seen and "Availability" in seen) or len(zone_lines) > 16:
                        break
                zone_lines.append(ln)
            zone = "\n".join(zone_lines)
            kind = kind_of(zone)
            if kind:
                res.append((page, fix_name(full_heading(h)), kind_final(kind, zone), parse_zone(zone)))
    return res


# item names the heading detection gets wrong, checked against the page image: (book, page, parsed name) -> name
NAME_FIX = {("SW_Arms_and_Equipment_Guide_WTC88664", 79, "Cargo Capacity; 250 kg"): "KAAC Freerunner",
            ("SW_Arms_and_Equipment_Guide_WTC88664", 78, "Trast A-AS Speeder Truck"): "Trast A-A5 Speeder Truck"}


def run(slugs):
    OUT.mkdir(parents=True, exist_ok=True)
    rows = {}
    for slug in slugs:
        for page, name, kind, f in entries(slug):
            name = NAME_FIX.get((slug, page, name), name)
            extra = {"cost_cr": num(f.get("Cost")), "weight_num": num(f.get("Weight")),
                     "check": ",".join("missing " + k for k in KEYS.get(kind, []) if not f.get(k))}
            weps = f.pop("_weapons", [])
            rows.setdefault(kind, []).append(dict(book=slug, page=page, name=name, kind=kind, **f, **extra))
            if kind == "vehicle":
                for w in weps:
                    rows.setdefault("vehicle_weapons", []).append(dict(book=slug, page=page, vehicle=name, **w))
    if "armor" in rows:  # powered armour: 'Proficiency Group:' wraps to a line 'Powered' that was read as a new item
        merged = []
        for r in rows["armor"]:
            prev = merged[-1] if merged else None
            if r["name"] == "Powered" and prev and prev["page"] == r["page"] and not prev.get("Cost"):
                for k, v in r.items():
                    if v and not prev.get(k) and k not in ("name",):
                        prev[k] = v
                prev["Proficiency Group"] = prev.get("Proficiency Group") or "Powered"
                prev["check"] = ""
                continue
            merged.append(r)
        rows["armor"] = merged
    if "gear" in rows:   # drop prose fragments caught by the Cost anchor
        rows["gear"] = [r for r in rows["gear"] if r["name"][:1].isupper() and len(r["name"].split()) <= 8 and not r["name"].endswith((".", ","))]
    for kind, rs in rows.items():
        cols = ["book", "page", "vehicle", "weapon"] if kind == "vehicle_weapons" else ["book", "page", "name", "kind"]
        for r in rs:
            for c in r:
                if c not in cols:
                    cols.append(c)
        with open(OUT / (os.environ.get("STATBLOCK_PREFIX", "") + kind + ".csv"), "w", newline="", encoding="utf-8") as fh:
            w = csv.DictWriter(fh, fieldnames=cols)
            w.writeheader()
            w.writerows(rs)
        print("%-8s %4d entries -> tables/%s%s.csv" % (kind, len(rs), os.environ.get("STATBLOCK_PREFIX", ""), kind))
    return rows


if __name__ == "__main__":
    a = sys.argv[1:]
    if not a or a[0] not in ("run", "check"):
        print(__doc__); sys.exit()
    slugs = a[1:] or ["SW_Arms_and_Equipment_Guide_WTC88664"]
    rows = run(slugs)
    if a[0] == "check":
        for kind, rs in rows.items():
            for r in random.sample(rs, min(8, len(rs))):
                print(kind, r)
