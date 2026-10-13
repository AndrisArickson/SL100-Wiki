"""Build the SL100 equipment catalogue.   python3 tools/convert/equipment.py

Merges three sources by item name:
  1. chapter 08 (08 New Star Wars - Equipment.md) and Special Materials.md   - authoritative SL100 values and traits
  2. the d20 stat tables in ../Source_Text/tables/*.csv                        - item list, cost, weight, era, text
  3. ../Source_Text/tables/wiki_match.csv                                       - the Legends article for each item
and writes converted SL100 statistics (nothing d20-mechanical survives) to rules/equipment/{weapons,armour,gear}.csv,
a conflicts/review report to rules/equipment/REVIEW.md, and the wiki pages SL100:Weapons, SL100:Armour, SL100:Gear.

Conversion rules (decided 2026-10-12):
  damage   d20 dice compressed to the WFRP scale: SL100 damage = round(2.5 * sqrt(average d20 damage))
           -> 3d6 = 8 (a blaster pistol equals a WFRP pistol), 3d8 = 9, 3d10 = 10, 4d8 = 11, 5d8 = 12, 8d6 = 14.
           melee = +SB + (that value - 3), minimum +2 (knife +2, vibroblade +4, vibro-axe +5).
  range    band from the d20 range increment: <=4 m Short, 6-12 m Medium, 15-30 m Long, >=40 m Extreme;
           Range in metres = increment x 2 (blaster pistol 20 m, rifle 60 m), WFRP bands R/10, R/2, 2R, 3R apply.
  enc      SL100 scale (12 Oct): 0 anything not decently big (grenades, hold-outs, knives, medpacs, datapads);
           1 a blaster pistol, a sword, anything arm- or leg-sized, a small worn bag (carries 2); 2 a blaster rifle,
           a two-handed melee weapon, a backpack (carries 4); 3 a heavy weapon, an oversized pack (carries 6+), a
           sensor backpack, a large armour piece; 5 a crew-served weapon; 10 a whole person or a full suit of heavy
           armour. Worn items drop 1 Enc (WFRP); limit = SB + TB. Gear by weight band when no rule names it.
  cost     d20 credits are the price even where 08 differs (ruling 12 Oct), except items that are not sold openly.
  avail    Prevalent -> Common, Common -> Uncommon, Specialized -> Scarce, Rare -> Rare; licensed/restricted/
           military/illegal kept as a Legality column (L/R/M/I).
  armour   item, cost and weight from d20; AP and Resist ONLY from the material (Special Materials table).
Items that came only from d20 are marked status=converted and should be reviewed; 08 values always win.
"""
import csv
import math
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT.parent / "Source_Text" / "tables"
OUT = ROOT / "rules" / "equipment"
sys.path.insert(0, str(ROOT / "tools"))


# ---------------------------------------------------------------- helpers
def clean(s):
    s = (s or "").replace("—", "-").replace("’", "'").replace("“", '"').replace("”", '"')
    s = re.sub(r"\s+", " ", s).strip()
    return s


def norm(name):
    n = clean(name).lower()
    n = re.sub(r"^[\\*]+", "", n)
    n = re.sub(r'["“”]', "", n)
    n = re.sub(r"\(.*?\)", "", n)
    n = re.sub(r"[^a-z0-9 ]", " ", n)
    return re.sub(r"\s+", " ", n).strip()


MAKERS = ("blastech", "merr sonn", "merr-sonn", "sorosuub", "czerka", "baktoid", "arakyd", "golan arms",
          "imperial munitions", "tenloss", "drearian", "ayelixe/krongbing textiles", "ayelixe krongbing textiles",
          "corellian arms", "kuat", "aratech", "neuro saav", "neuro-saav", "fabritech", "koensayr", "mon calamari",
          "prax arms", "adostic arms", "sienar", "cryoncorp", "briletto", "locris syndicates")


def short(name):
    n = clean(name).replace('""', '"').replace("lon ", "Ion ").replace("lon-", "Ion-")
    n = re.sub(r'\s+"[A-Z]?[^"]*$', "", n)          # OCR tail after an unbalanced quote
    for m in MAKERS:
        n = re.sub(r"(?i)^" + re.escape(m) + r"\s+", "", n)
    return n


def num(s):
    m = re.search(r"-?\d+(?:\.\d+)?", (s or "").replace(",", ""))
    return float(m.group()) if m else None


def kg(s, size=""):
    """Weight in kg with OCR repair: '05kg' -> 0.5, '45 kg' on a hand weapon -> 4.5."""
    t = clean(s)
    if re.match(r"^0\d", t):
        t = "0." + t[1:]
    v = num(t)
    if v is None:
        return None
    big = clean(size).lower().startswith(("large", "huge"))
    if v >= 20 and not big and "." not in t:
        v = v / 10
    return v


def dice_avg(s):
    s = clean(s)
    m = re.match(r"(\d+)d(\d+)\s*([+-]\s*\d+)?", s)
    if not m:
        return None
    n, d = int(m.group(1)), int(m.group(2))
    k = int(m.group(3).replace(" ", "")) if m.group(3) else 0
    return n * (d + 1) / 2 + k


def dmg_ranged(s):
    a = dice_avg(s)
    return None if a is None or a <= 0 else int(round(2.5 * math.sqrt(a)))


def dmg_melee(s):
    v = dmg_ranged(s)
    return None if v is None else "+SB+%d" % max(2, v - 3)


def range_band(inc):
    v = num(inc)
    if v is None:
        return "", ""
    band = "S" if v <= 4 else "M" if v <= 12 else "L" if v <= 30 else "E"
    return band, "%d" % int(v * 2)


def enc_weapon(skill, group, name, size, weight, bulky):
    n = name.lower()
    g = (group or "").lower()
    sk = (skill or "").lower()
    if not sk or re.search(r"\(\d+\)|arrows|quarrels|bullets|energy balls|power pack|ammunition|cartridge", n):
        return "0"
    if re.search(r"grenade|detonator|hold-?out|knife|dagger|dart|razor|garrote|glove|knuckle|sling\b", n + " " + g):
        return "0"
    if (weight or 0) >= 25 or re.search(r"e-web|cannon|tripod|emplacement", n):
        return "5"
    if ("carbine" in g or "carbine" in n) and not re.search(r"flame|rotary|repeat", n + " " + g):
        return "1"
    if "ordnance" in sk or re.search(r"heavy blaster|heavy weapon|repeat|flame|launcher|bowcaster|e-web", n + " " + g):
        return "3"
    if "pistol" in n or "pistol" in g or "hold-out" in n:
        return "1"
    if "rifle" in g or "archaic" in sk or "2h" in sk or bulky or "two-handed" in n or "long gun" in g:
        return "2"
    return "1"


SUIT_ENC = {"Light": "2", "Medium": "6", "Heavy": "10", "Powered": "14"}


def enc_armour(form, atype, name):
    if form == "suit":
        return SUIT_ENC.get(atype, "6")
    n = name.lower()
    if re.search(r"breast|chest|torso|cuirass", n):
        return "3"
    if re.search(r"helm|hat|cap|glove|gauntlet|boot|visor|mask", n):
        return "0"
    return "1"


def enc_gear(weight, name):
    n = name.lower()
    if re.search(r"jet ?pack|jetpack|rocket pack|repulsor pack|glider|jump boots", n):
        return "3"
    if re.search(r"sensor pack|sensor backpack", n):
        return "2"
    if re.search(r"medpac|breath mask|comlink|datapad|glow rod|binocular|holoproj|recorder|power pack|rod\b|kit\b|mask|goggles|rations|canteen|cable|rope|tool", n):
        return "0" if (weight or 0) < 6 else "1"
    if weight is None:
        return ""
    if weight < 2:
        return "0"
    if weight < 6:
        return "1"
    if weight < 12:
        return "2"
    if weight < 25:
        return "3"
    return str(int(math.ceil(weight / 8)))


def enc_armour_form(atype, locations, name):
    return "suit" if (locations or "").strip().lower() in ("all", "full", "all locations") or re.search(r"suit|armor$|armour$", name.lower()) and not re.search(r"vest|helm|plate|jacket", name.lower()) else "piece"


AVAIL = {"prevalent": "Common", "common": "Uncommon", "specialized": "Scarce", "specialised": "Scarce",
         "rare": "Rare", "unique": "Unique"}
LEGAL = {"licensed": "L", "restricted": "R", "military": "M", "illegal": "I"}


def avail(s):
    s = clean(s).lower()
    a = ""
    for k, v in AVAIL.items():
        if s.startswith(k):
            a = v
            break
    leg = ""
    for k, v in LEGAL.items():
        if re.search(r"\b" + k[:6], s):
            leg = v
    return a, leg


# weapon type -> (SL100 skill, 08 baseline name, traits, bulky)
WTYPE = [   # (pattern on d20 weapon type, (SL100 skill, baseline 08 item, traits, bulky)) - 13 Oct 2026 consolidated skills
    (r"hold-?out", ("Ranged (Blaster)", "Hold-out Blaster", "", False)),
    (r"^blaster, (heavy|lt\. repeat)", ("Ranged (Blaster)", "Repeating Blaster", "Rapid Fire", True)),
    (r"^blaster, sporting|ion gun", ("Ranged (Blaster)", "Sporting Blaster Pistol", "", False)),
    (r"sporting blaster pistol", ("Ranged (Blaster)", "Sporting Blaster Pistol", "", False)),
    (r"blaster pistol|heavy blaster pistol", ("Ranged (Blaster)", "Blaster Pistol", "", False)),
    (r"heavy blaster(?! pistol)", ("Ranged (Blaster)", "Heavy Blaster Rifle", "Rapid Fire", True)),
    (r"light repeating|repeating blaster", ("Ranged (Blaster)", "Repeating Blaster", "Rapid Fire", True)),
    (r"blaster carbine", ("Ranged (Blaster)", "Blaster Carbine", "", False)),
    (r"sporting blaster rifle", ("Ranged (Blaster)", "Sporting Blaster Rifle", "", False)),
    (r"blaster rifle", ("Ranged (Blaster)", "Blaster Rifle", "", False)),
    (r"slugthrower pistol", ("Ranged (Archaic)", "Autopistol", "Solid Projectile", False)),
    (r"slugthrower rifle|slugthrower", ("Ranged (Archaic)", "Slugthrower Rifle", "Solid Projectile", False)),
    (r"disruptor pistol", ("Ranged (Blaster)", "Disruptor Pistol", "Penetrating, Damaging", False)),
    (r"disruptor", ("Ranged (Blaster)", "Disruptor Rifle", "Penetrating, Damaging", False)),
    (r"[il]on pistol", ("Ranged (Blaster)", "Ion Pistol", "Damages Electrics, Undamaging (living)", False)),
    (r"[il]on rifle", ("Ranged (Blaster)", "Ion Rifle", "Damages Electrics, Undamaging (living)", False)),
    (r"flame", ("Ranged (Exotic)", "Hand Flamer", "Ablaze, Spread", True)),
    (r"sonic", ("Ranged (Blaster)", "Sonic Blaster", "Stun, Spread", False)),
    (r"grenade launcher", ("Ranged (Ordnance)", "Grenade Launcher", "Blast (3)", True)),
    (r"grenade|detonator", ("Ranged (Thrown)", "Grenade", "Blast (3), Thrown", False)),
    (r"wrist-mounted rocket|mini-?rocket|wrist rocket", ("Ranged (Exotic)", "Wrist Rocket", "Blast (3)", False)),
    (r"missile|rocket", ("Ranged (Ordnance)", "Missile Launcher", "Blast (5)", True)),
    (r"flechette", ("Ranged (Exotic)", "Flechette Launcher", "Spread, Solid Projectile", False)),
    (r"dart", ("Ranged (Exotic)", "Dart Shooter", "Solid Projectile, Poison", False)),
    (r"wrist-mounted|glue|adhesive|tensor|magna caster|magnetic accelerator", ("Ranged (Exotic)", "", "", False)),
    (r"bowcaster", ("Ranged (Archaic)", "Bowcaster", "Impact", True)),
    (r"crossbow|bow|sling", ("Ranged (Archaic)", "Bow", "", False)),
    (r"thrown|throwing", ("Ranged (Thrown)", "", "", False)),
    (r"melee|vibro|sword|blade|axe|pike|staff|whip|knife|club|mace|spear|garrote|razor", ("MELEE", "", "", False)),
]

MELEE_SPEC = [   # (pattern on name, SL100 skill, traits) - Melee (1H) / (2H) / (Brawling) / (Lightsaber) only
    (r"vibro-?axe|vibroaxe", "Melee (2H)", "Damaging"), (r"force pike|pike", "Melee (2H)", "Impact, Shock"),
    (r"electrostaff|quarterstaff|staff", "Melee (2H)", "Shock"), (r"lightsaber|lightwhip", "Melee (\\*Lightsaber)", "Penetrating, Damaging, Hack"),
    (r"stun baton|baton", "Melee (1H)", "Pummel, Undamaging"), (r"knuckle|glove|gauntlet|claw", "Melee (Brawling)", ""),
    (r"whip", "Ranged (Exotic)", "Entangle, Wrap"), (r"vibro", "Melee (1H)", "Damaging"),
    (r"knife|dagger|razor|garrote", "Melee (1H)", ""),
    (r"axe|sword|blade|spear|club|mace|hammer", "Melee (1H)", ""),
]


def classify_weapon(wtype, name, size):
    t = clean(wtype).lower()
    if re.search(r"\(\d+\)|arrows|quarrels|bullets|energy balls|power pack|ammunition|cartridge", name.lower()):
        return "", "", "", False, False
    if re.search(r"detonator|grenade", name.lower()) and "launcher" not in name.lower():
        return "Ranged (Thrown)", "Grenade", "Blast (3), Thrown", False, False
    if re.search(r"^net$|electro-net|\bnet\b|net launcher|whip", name.lower()):
        return "Ranged (Exotic)", "", "Entangle", False, False
    for pat, val in WTYPE:
        if re.search(pat, t) or (val[0] == "MELEE" and re.search(pat, name.lower()) and not t.startswith(("blaster", "slug"))):
            if val[0] == "MELEE":
                for p2, skill, traits in MELEE_SPEC:
                    if re.search(p2, name.lower()):
                        two = clean(size).lower().startswith("large")
                        if two and skill == "Melee (1H)":
                            skill = "Melee (2H)"
                        return skill, "", traits + (", Two-Handed" if two else ""), two, True
                return "Melee (1H)", "", "", False, True
            return val[0], val[1], val[2], val[3], False
    return "review", "", "", False, False


# ---------------------------------------------------------------- read 08 and materials
def md_tables(path):
    lines = path.read_text(encoding="utf-8").splitlines()
    sec, tables, cur = None, [], None
    for i, l in enumerate(lines):
        m = re.match(r"^#+\s*\**(.+?)\**\s*$", l) or re.match(r"^\*\*([^*]+)\*\*\s*$", l)
        if m:
            sec = clean(m.group(1))
            if cur:
                tables.append(cur)
                cur = None
            continue
        if l.startswith("|"):
            if re.match(r"^\|\s*-", l):
                continue
            cells = [clean(c.replace("<br/>", " ")) for c in l.strip().strip("|").split("|")]
            if cur is None:
                cur = {"sec": sec, "line": i + 1, "head": [c.strip("*").strip() for c in cells], "rows": []}
            else:
                cur["rows"].append(dict(zip(cur["head"], cells)))
        elif cur:
            tables.append(cur)
            cur = None
    if cur:
        tables.append(cur)
    return tables


def read_08():
    weapons, armour, gear = [], [], []
    for t in md_tables(ROOT / "08 New Star Wars - Equipment.md"):
        h = t["head"]
        if "Dam" in h and "Name" in h:
            for r in t["rows"]:
                if not r.get("Name"):
                    continue
                weapons.append({"name": clean(r["Name"]).lstrip("\\*").strip(), "group": t["sec"], "skill": r.get("Skill", ""),
                                "damage": r.get("Dam", ""), "range": r.get("Range", ""), "range_m": "", "mag": r.get("Mag", ""),
                                "enc": r.get("Enc", ""), "cost": r.get("Cost", ""), "avail": r.get("Avail", ""), "legality": "",
                                "traits": r.get("Traits", ""), "legends": "", "source": "08 Equipment", "status": "sl100",
                                "notes": r.get("Description", "")})
        elif h[0] in ("ARMOUR",) or (h[0] == "Name" and "Location" in h):
            for r in t["rows"]:
                nm = r.get("ARMOUR") or r.get("Name")
                if not nm:
                    continue
                apr = r.get("AP - resist", "") or r.get("Armour", "")
                m = re.match(r"(\d+)\s*-\s*(\d+)", apr)
                armour.append({"name": clean(nm), "type": "", "form": enc_armour_form("", r.get("Loc", "") or r.get("Location", ""), clean(nm)), "locations": r.get("Loc", "") or r.get("Location", ""),
                               "material": r.get("Material", ""), "ap": m.group(1) if m else num(apr) and str(int(num(apr))) or "",
                               "resist": m.group(2) if m else "", "enc": r.get("Enc", ""), "cost": r.get("Price", "") or r.get("Cost", ""),
                               "avail": r.get("Avail", ""), "legality": "", "traits": r.get("Qual / Flaw", "") or r.get("Traits", ""),
                               "legends": "", "source": "08 Equipment", "status": "sl100", "notes": ""})
        elif h[:3] == ["Name", "Cost", "Enc"]:
            for r in t["rows"]:
                if r.get("Name"):
                    gear.append({"name": clean(r["Name"]), "class": t["sec"], "carries": "", "enc": r.get("Enc", ""), "cost": r.get("Cost", ""),
                                 "avail": "", "legality": "", "traits": r.get("Traits", ""), "legends": "", "source": "08 Equipment",
                                 "status": "sl100", "notes": ""})
    return weapons, armour, gear


def read_materials():
    mats = {}
    for t in md_tables(ROOT / "Special Materials.md"):
        if t["head"] and t["head"][0] == "Material" and "Armour Points - Resist" in t["head"]:
            for r in t["rows"]:
                m = re.search(r"(\d+)\s*-\s*(?:Resist\s*)?(\d+)", r.get("Armour Points - Resist", ""))
                if r.get("Material") and m:
                    mats[norm(r["Material"])] = (m.group(1), m.group(2), r.get("Weight", ""))
    return mats


# ---------------------------------------------------------------- read d20
def read_csv(name):
    p = SRC / name
    return list(csv.DictReader(open(p, encoding="utf-8"))) if p.exists() else []


def legends_index():
    idx = {}
    for r in read_csv("wiki_match.csv"):
        if r.get("match") in ("exact", "code", "words") and r.get("wiki_title"):
            idx[norm(r["name"])] = r
    return idx


def d20_weapons(legends):
    out = []
    for r in read_csv("weapon.csv"):
        name = clean(r["name"])
        wtype = clean(r.get("Weapon Type", "")).split(" A ")[0]
        skill, base, traits, bulky, melee = classify_weapon(wtype, name, r.get("Size", ""))
        dmg = dmg_melee(r.get("Damage", "")) if melee else dmg_ranged(r.get("Damage", ""))
        band, metres = ("", "") if melee else range_band(r.get("Range Increment", ""))
        a, leg = avail(r.get("Availability", ""))
        if clean(r.get("Multifire/Autofire", "")).upper().startswith("A") and "Rapid Fire" not in traits:
            traits = (traits + ", Rapid Fire").strip(", ")
        if num(r.get("Fort DC", "")) and not melee and "Stun" not in traits:
            traits = (traits + ", Stun setting").strip(", ")
        lg = legends.get(norm(name)) or legends.get(norm(short(name)))
        out.append({"name": short(name), "group": wtype or ("Melee weapon" if melee else ""), "skill": skill,
                    "damage": "" if dmg is None else str(dmg), "range": band, "range_m": metres, "mag": "",
                    "enc": enc_weapon(skill, wtype, short(name), r.get("Size", ""), kg(r.get("Weight") or r.get("weight_num"), r.get("Size", "")), bulky),
                    "cost": str(int(num(r.get("cost_cr") or r.get("Cost")) or 0)) if num(r.get("cost_cr") or r.get("Cost")) else "",
                    "avail": a, "legality": leg, "traits": traits, "legends": lg["wiki_title"] if lg else "",
                    "source": "d20 A&E p.%s" % r.get("page", ""), "status": "converted",
                    "notes": ("%s; " % clean(lg["wiki_manufacturer"]) if lg and lg.get("wiki_manufacturer") else "") + ("baseline: %s" % base if base else "")})
    for r in read_csv("core_weapon.csv"):
        name = clean(r["name"])
        if not name or name.lower().startswith(("see", "table")):
            continue
        melee = r.get("category", "").startswith("Melee")
        grp = clean(r.get("group", ""))
        wtype = ("Blaster pistol" if re.match(r"pi", grp) else "Blaster rifle" if grp.startswith("ri") else
                 "Heavy blaster" if grp == "Heavy" else "Slugthrower" if grp == "Slugthrowers" else name)
        skill, base, traits, bulky, melee2 = classify_weapon(wtype if not melee else "melee", name, r.get("size", ""))
        dmg = dmg_melee(r.get("damage", "")) if melee else dmg_ranged(r.get("damage", ""))
        band, metres = ("", "") if melee else range_band(r.get("range_increment", ""))
        lg = legends.get(norm(name))
        out.append({"name": name, "group": wtype if not melee else "Melee weapon", "skill": skill,
                    "damage": "" if dmg is None else str(dmg), "range": band, "range_m": metres, "mag": "",
                    "enc": enc_weapon(skill, wtype if not melee else "melee", name, r.get("size", ""), kg(r.get("weight"), r.get("size", "")), bulky), "cost": str(int(num(r.get("cost")) or 0)) if num(r.get("cost")) else "",
                    "avail": "", "legality": "", "traits": traits, "legends": lg["wiki_title"] if lg else "",
                    "source": "d20 Core table %s" % r.get("table", ""), "status": "converted", "notes": "baseline: %s" % base if base else ""})
    return out


ARMOUR_MAT = [(r"weave|climbsuit|shadowsuit|bodyglove|cloth|suit|vest|jacket", "armour weave", "Light"),
              (r"plastoid|stormtrooper|scout|clone", "plastoid", "Medium"), (r"durasteel|battle|heavy", "durasteel", "Heavy"),
              (r"power|exoskeleton", "durasteel", "Powered")]
TYPE_DEFAULT = {"Light": ("armour weave", "2", "1"), "Medium": ("plastoid", "3", "1"), "Heavy": ("durasteel", "4", "2"), "Powered": ("durasteel", "5", "3")}


def d20_armour(legends, mats):
    out = []
    rows = [(r, clean(r["name"]), clean(r.get("Armor Type", "")).replace(" armor", "").title(), r.get("cost_cr") or r.get("Cost"), r.get("weight_num") or r.get("Weight"), r.get("Availability", ""), "d20 A&E p.%s" % r.get("page", "")) for r in read_csv("armor.csv")]
    rows += [(r, clean(r["name"]), clean(r.get("category", "")).replace(" Armor", "").title(), r.get("cost"), r.get("weight"), "", "d20 Core table %s" % r.get("table", "")) for r in read_csv("core_armor.csv")]
    for r, name, atype, cost, weight, av, src in rows:
        if not name:
            continue
        material, t2 = "", atype or "Light"
        for pat, mat, typ in ARMOUR_MAT:
            if re.search(pat, name.lower()):
                material, t2 = mat, atype or typ
                break
        t2 = t2 if t2 in TYPE_DEFAULT else "Light"
        mat_default, ap, resist = TYPE_DEFAULT[t2]
        material = material or mat_default
        MAT_DEFAULT = {"armour weave": ("2", "1"), "plastoid": ("3", "1"), "durasteel": ("4", "2")}
        if material in MAT_DEFAULT:
            ap, resist = MAT_DEFAULT[material]
            if t2 == "Powered":
                ap = str(int(ap) + 1)
        if norm(material).replace(" ", "") in {k.replace(" ", ""): v for k, v in mats.items()}:
            ap, resist, _ = {k.replace(" ", ""): v for k, v in mats.items()}[norm(material).replace(" ", "")]
        a, leg = avail(av)
        loc = "Head" if re.search(r"helm", name.lower()) else "Body" if re.search(r"vest|jacket|breastplate", name.lower()) else "All"
        lg = legends.get(norm(name)) or legends.get(norm(short(name)))
        form = enc_armour_form(t2, loc, name)
        out.append({"name": short(name), "type": t2, "form": form, "locations": loc, "material": material.title(), "ap": ap, "resist": resist,
                    "enc": enc_armour(form, t2, name), "cost": str(int(num(cost) or 0)) if num(cost) else "",
                    "avail": a, "legality": leg, "traits": "Powered" if t2 == "Powered" else "", "legends": lg["wiki_title"] if lg else "",
                    "source": src, "status": "converted", "notes": "AP/Resist from material %s (review)" % material})
    return out


def d20_gear(legends):
    out = []
    for r in read_csv("gear.csv"):
        name = clean(r["name"])
        if len(name) > 45 or re.search(r"writeup|chapter|includes the", name.lower()):
            continue                                   # OCR noise, not an item
        a, leg = avail(r.get("Availability", ""))
        lg = legends.get(norm(name)) or legends.get(norm(short(name)))
        out.append({"name": short(name), "class": clean(r.get("Class", "")) or "General", "carries": "", "enc": enc_gear(kg(r.get("Weight") or r.get("weight_num"), "large"), short(name)),
                    "cost": str(int(num(r.get("cost_cr") or r.get("Cost")) or 0)) if num(r.get("cost_cr") or r.get("Cost")) else "", "avail": a, "legality": leg,
                    "traits": "", "legends": lg["wiki_title"] if lg else "", "source": "d20 A&E p.%s" % r.get("page", ""), "status": "converted", "notes": ""})
    for r in read_csv("core_equipment.csv"):
        name = clean(r["name"])
        if not name:
            continue
        lg = legends.get(norm(name))
        out.append({"name": name, "class": clean(r.get("section", "")) or "General", "carries": "", "enc": enc_gear(kg(r.get("weight"), "large"), name),
                    "cost": str(int(num(r.get("cost")) or 0)) if num(r.get("cost")) else "", "avail": "", "legality": "", "traits": "",
                    "legends": lg["wiki_title"] if lg else "", "source": "d20 Core table %s" % r.get("table", ""), "status": "converted", "notes": ""})
    return out


# ---------------------------------------------------------------- merge
def merge(sl, d20, fields, enc_rule="08"):
    """08 rows win except: cost comes from d20 when both have one (ruling 12 Oct); Enc follows enc_rule
    ('08' keeps the chapter value, 'computed' takes the converted value). Remaining disagreements are reported."""
    conflicts, by = [], {norm(x["name"]): x for x in sl}
    for d in d20:
        k = norm(d["name"])
        if k in by:
            s = by[k]
            for f in fields:
                if not s.get(f) and d.get(f) and d[f] != "review":
                    s[f] = d[f]
                elif s.get(f) and d.get(f) and clean(s[f]) != clean(d[f]):
                    if f == "cost" and num(d[f]):
                        s["notes"] = (s.get("notes", "") + " cost: d20 %s used instead of 08 %s;" % (d[f], s[f])).strip()
                        s[f] = d[f]
                    elif f == "enc" and enc_rule == "computed":
                        s["notes"] = (s.get("notes", "") + " enc: SL100 scale %s instead of 08 %s;" % (d[f], s[f])).strip()
                        s[f] = d[f]
                    elif f in ("cost", "enc"):
                        conflicts.append((s["name"], f, s[f], d[f], d["source"]))
            s["status"] = "merged"
            if d.get("legends") and not s.get("legends"):
                s["legends"] = d["legends"]
            s["source"] += "; " + d["source"]
        else:
            by[k] = d
    rows = sorted(by.values(), key=lambda x: (x.get("group") or x.get("type") or x.get("class") or "", x["name"].lower()))
    return rows, conflicts


def containers():
    base = {"avail": "Common", "legality": "", "legends": "", "source": "SL100 (Enc scale 12 Oct)", "status": "sl100", "notes": "worn container: its own Enc counts, its contents up to Carries do not"}
    rows = [("Belt pouch", "0", "1", "10"), ("Satchel / small bag", "1", "2", "25"), ("Backpack", "2", "4", "60"),
            ("Large pack (oversized)", "3", "6", "120"), ("Sensor backpack", "3", "2", "1500")]
    return [dict(base, name=n, **{"class": "Containers", "enc": e, "carries": c, "cost": p, "traits": "Carries %s Enc" % c}) for n, e, c, p in rows]


def apply_overrides(*tables):
    """rules/equipment/overrides.csv: name,table,field,value,note - hand rulings applied last on every run."""
    p = OUT / "overrides.csv"
    if not p.exists():
        return
    idx = {t: {norm(r["name"]): r for r in rows} for t, rows in zip(("weapons", "armour", "gear"), tables)}
    for o in csv.DictReader(open(p, encoding="utf-8")):
        r = idx.get(o["table"], {}).get(norm(o["name"]))
        if r is not None:
            r[o["field"]] = o["value"]
            if o.get("note"):
                r["notes"] = (r.get("notes", "") + " " + o["note"]).strip()


def add_worn(weapons, armour, gear):
    """Worn Enc: a worn or holstered item counts 1 less; a suit covers head, arms, torso and legs so counts 4 less;
    a powered suit is 10 worn and 14 carried, and counts nothing against its wearer while it has power."""
    for r in weapons + gear:
        e = num(r.get("enc"))
        r["worn"] = "" if e is None or e >= 100 else str(max(0, int(e) - 1))
    for r in armour:
        e = num(r.get("enc"))
        if e is None:
            r["worn"] = ""
        elif r.get("type") == "Powered" and r.get("form") == "suit":
            r["worn"] = "10 (0 while powered)"
        elif r.get("form") == "suit":
            r["worn"] = str(max(0, int(e) - 4))
        else:
            r["worn"] = str(max(0, int(e) - 1))


def write_csv(path, rows, fields):
    with open(path, "w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=fields, extrasaction="ignore")
        w.writeheader()
        w.writerows(rows)


# ---------------------------------------------------------------- wiki pages
def link(row):
    n = row["name"]
    return "[[%s|%s]]" % (row["legends"], n) if row.get("legends") else n


def mark(row):
    return {"sl100": "", "merged": "", "converted": " ''(converted)''"}.get(row["status"], "")


def table(rows, cols, labels):
    out = ['{| class="wikitable sortable"', "! " + " !! ".join(labels)]
    for r in rows:
        cells = []
        for c in cols:
            v = link(r) + mark(r) if c == "name" else (r.get(c) or "")
            cells.append(v)
        out.append("|-\n| " + " || ".join(cells))
    out.append("|}")
    return "\n".join(out)


def group_of(w):
    g = (w.get("group") or "").lower()
    s = (w.get("skill") or "").lower()
    n = w["name"].lower()
    if not s or re.search(r"\(\d+\)|arrows|quarrels|bullets|energy balls|power pack", n):
        return "Ammunition and power"
    if s == "review":
        return "Unclassified (review)"
    if "lightsaber" in s or "lightsaber" in n or "lightwhip" in n:
        return "Lightsabers"
    if s.startswith("melee") or "melee" in g:
        return "Melee weapons"
    if "exotic" in s:
        return "Exotic ranged weapons"
    if "ordnance" in s:
        return "Launchers"
    if "thrown" in s or "grenade" in g or "detonator" in n:
        return "Grenades and explosives"
    if "heavy" in g or "repeating" in g or "e-web" in n or "cannon" in n:
        return "Heavy weapons"
    if "archaic" in s or "slugthrower" in g or "bow" in g or "sling" in g:
        return "Slugthrowers and archaic weapons"
    if "rifle" in g or "carbine" in g or "long gun" in g:
        return "Blaster rifles and carbines"
    return "Blaster pistols and sidearms"


ENC_NOTE = """== Encumbrance ==
Encumbrance (Enc) measures bulk as much as weight. A character carries '''Strength Bonus + Toughness Bonus''' Enc without penalty (about 6 for an average human); up to double that is -1 Movement and -10 Agility with +1 Travel Fatigue, up to triple is -2 Movement and -20 Agility with +2 Travel Fatigue, and beyond that you are not moving. Wearing something reduces its Enc: a holstered pistol, a slung rifle, a worn jetpack or a single armour piece counts 1 less, and a full suit of armour counts 4 less (head, arms, torso and legs each -1). A powered suit is Enc 14 carried and 10 worn, and counts nothing against its wearer while it has power. The '''Worn''' column on each table gives the worn value. You can normally carry only one oversized item (Enc 4 or more) and it takes both hands.

{| class="wikitable"
! Enc !! Examples
|-
| 0 || Anything that is not decently big: a grenade, a hold-out blaster, a knife, a medpac, a comlink, a datapad, a power pack, a breath mask
|-
| 1 || A blaster pistol or carbine, a vibroblade, anything the size of an arm or a leg, a small bag worn on the body (carries 2 Enc that do not count against you)
|-
| 2 || A blaster rifle, a two-handed melee weapon (vibro-axe, force pike), a backpack (carries 4 Enc), a light armour suit
|-
| 3 || A heavy weapon, a bowcaster, a jetpack or glider (2 worn), a large oversized pack (carries 6 Enc or more), a sensor backpack, a large armour piece such as a chest plate
|-
| 5 || A crew-served weapon such as an E-Web or a blaster cannon, carried by two
|-
| 6 || A full suit of medium battle armour
|-
| 10 || A whole person, or a full suit of heavy armour
|-
| 14 || A powered suit carried rather than worn (10 worn, 0 while powered)
|}
"""

ART = {   # SL100 original artwork shown at the top of a section (images/generated/originals; see meta/generated_images.tsv)
    "Blaster pistols and sidearms": ("SL100 Gear Blaster Pistol.jpg", "Blaster pistol"),
    "Blaster rifles and carbines": ("SL100 Gear Blaster Rifle.jpg", "Blaster rifle"),
    "Heavy weapons": ("SL100 Gear Heavy Blaster and Slugthrower.jpg", "Heavy blaster and slugthrower"),
    "Grenades and explosives": ("SL100 Gear Grenade.jpg", "Grenade"),
    "Melee weapons": ("SL100 Gear Vibroblade.jpg", "Vibroblade"),
}
GEAR_ART = [("SL100 Gear Datapad.jpg", "Datapad"), ("SL100 Gear Comlink.jpg", "Comlink"), ("SL100 Gear Medpac.jpg", "Medpac"),
            ("SL100 Gear Macrobinoculars.jpg", "Macrobinoculars"), ("SL100 Gear Breath Mask and Glow Rod.jpg", "Breath mask and glow rod"),
            ("SL100 Gear Utility Belt.jpg", "Utility belt and credit chips"), ("SL100 Gear Jetpack.jpg", "Jetpack"), ("SL100 Gear Speeder Bike.jpg", "Speeder bike")]
MELEE_ART = [("SL100 Gear Vibro-Axe.jpg", "Vibro-axe"), ("SL100 Gear Force Pike.jpg", "Force pike"), ("SL100 Gear Stun Baton.jpg", "Stun baton")]


def art(f, cap, w=200):
    return "[[File:%s|thumb|right|%dpx|%s (SL100 original art)]]" % (f, w, cap)


def art_strip(items):
    return "\n".join("[[File:%s|frameless|150px|%s]]" % (f, c) for f, c in items)


def weapons_page(rows, n_conv):
    cols = ["name", "skill", "damage", "range", "range_m", "mag", "enc", "worn", "cost", "avail", "legality", "traits", "source"]
    labels = ["Weapon", "Skill", "Dam", "Band", "Range (m)", "Mag", "Enc", "Worn", "Cost", "Avail", "Legal", "Traits", "Source"]
    order = ["Blaster pistols and sidearms", "Blaster rifles and carbines", "Heavy weapons", "Slugthrowers and archaic weapons",
             "Grenades and explosives", "Exotic ranged weapons", "Launchers", "Melee weapons", "Lightsabers", "Ammunition and power", "Unclassified (review)"]
    parts = ["__NOTOC__\n{{SL100 Rules|chapter=Weapons|status=Catalogue: %d items, %d converted from d20 and awaiting review|source=08 Equipment + Source_Text/tables (tools/convert/equipment.py)}}" % (len(rows), n_conv),
             "Every '''weapon''' a character can buy, with its SL100 statistics. Items marked ''(converted)'' were built from the d20 books by the conversion rules in [[SL100:Equipment]] and have not yet been reviewed; items without the mark are from chapter 08. Each name links to its Legends article where one is matched. Damage for ranged weapons is a flat value; melee damage adds your Strength Bonus. Range bands: Point Blank = Range/10, Short = Range/2, Long = 2 x Range, Extreme = 3 x Range (see Combat).",
             "Legality: L licensed, R restricted, M military, I illegal. Availability: Common, Uncommon, Scarce, Rare, Exotic, Unique (see [[SL100:Special Materials]] for the stock chances by settlement)."]
    for g in order:
        sub = [r for r in rows if group_of(r) == g]
        if sub:
            pic = art(*ART[g]) + "\n" if g in ART else ""
            if g == "Melee weapons":
                pic += art_strip(MELEE_ART) + "\n\n"
            parts.append("== %s (%d) ==\n%s%s" % (g, len(sub), pic, table(sub, cols, labels)))
    parts.append("[[Category:SL100]]\n[[Category:SL100 rules]]\n[[Category:SL100 weapons]]")
    return "\n\n".join(parts)


def armour_page(rows, n_conv):
    cols = ["name", "type", "form", "locations", "material", "ap", "resist", "enc", "worn", "cost", "avail", "legality", "traits", "source"]
    labels = ["Armour", "Type", "Suit / piece", "Locations", "Material", "AP", "Resist", "Enc", "Worn", "Cost", "Avail", "Legal", "Qualities / Flaws", "Source"]
    parts = ["__NOTOC__\n{{SL100 Rules|chapter=Armour|status=Catalogue: %d items, %d converted from d20 and awaiting review|source=08 Equipment + Special Materials + Source_Text/tables (tools/convert/equipment.py)}}" % (len(rows), n_conv),
             "'''Armour''' carries two values: '''AP''' (Armour Points) against blasters, slugs and blows, and '''Resist''' against lightsabers. Both come from the material the piece is made of (see [[SL100:Special Materials]]), never from the d20 books. Items marked ''(converted)'' took their AP and Resist from the default material for their type and need checking. A '''suit''' covers all locations and carries the whole-suit Enc (light 2, medium 6, heavy 10, powered 14 carried / 10 worn); a '''piece''' covers the locations listed and its Enc alone. Worn armour counts 1 Enc less (see [[SL100:Gear#Encumbrance|Encumbrance]]).",
             art("SL100 Gear Combat Armour.jpg", "Light combat armour", 220), table(rows, cols, labels), "[[Category:SL100]]\n[[Category:SL100 rules]]\n[[Category:SL100 armour]]"]
    return "\n\n".join(parts)


def gear_page(rows, n_conv):
    cols = ["name", "class", "enc", "worn", "carries", "cost", "avail", "legality", "traits", "source"]
    labels = ["Item", "Class", "Enc", "Worn", "Carries", "Cost", "Avail", "Legal", "Effect / Traits", "Source"]
    parts = ["__NOTOC__\n{{SL100 Rules|chapter=Gear|status=Catalogue: %d items, %d converted from d20 and awaiting review|source=08 Equipment + Source_Text/tables (tools/convert/equipment.py)}}" % (len(rows), n_conv),
             art_strip(GEAR_ART), ENC_NOTE, "'''General equipment''': tools, medical supplies, communications, survival gear, security and slicing kit, and the rest of a character's trappings. Items marked ''(converted)'' have cost, Encumbrance and availability from the d20 books and still need their SL100 effect written.",
             table(rows, cols, labels), "[[Category:SL100]]\n[[Category:SL100 rules]]\n[[Category:SL100 equipment]]"]
    return "\n\n".join(parts)


def save_pages(pages):
    import sqlite3
    try:
        import serve
        from common import db_connect
        con = db_connect()
        serve.load_index()
        for title, text in pages:
            serve.save_page(con, title, text, "Equipment catalogue (tools/convert/equipment.py)")
        con.close()
        return "saved and registered"
    except sqlite3.OperationalError as e:
        from common import PAGES_DIR, page_relpath, title_ns, write_atomic
        for title, text in pages:
            ns = title_ns(title) or 3000
            write_atomic(PAGES_DIR / page_relpath(title, ns), text)
        return "written as files only (%s); restart ./wiki.sh serve to register new pages" % e


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    legends = legends_index()
    mats = read_materials()
    w08, a08, g08 = read_08()
    wf = ["name", "group", "skill", "damage", "range", "range_m", "mag", "enc", "worn", "cost", "avail", "legality", "traits", "legends", "source", "status", "notes"]
    af = ["name", "type", "form", "locations", "material", "ap", "resist", "enc", "worn", "cost", "avail", "legality", "traits", "legends", "source", "status", "notes"]
    gf = ["name", "class", "carries", "enc", "worn", "cost", "avail", "legality", "traits", "legends", "source", "status", "notes"]
    weapons, cw = merge(w08, d20_weapons(legends), wf, enc_rule="computed")
    armour, ca = merge(a08, d20_armour(legends, mats), af)
    gear, cg = merge(g08, d20_gear(legends), gf, enc_rule="computed")
    gear += containers()
    apply_overrides(weapons, armour, gear)
    add_worn(weapons, armour, gear)
    write_csv(OUT / "weapons.csv", weapons, wf)
    write_csv(OUT / "armour.csv", armour, af)
    write_csv(OUT / "gear.csv", gear, gf)
    rep = ["# Equipment catalogue: review report", "", "Generated by tools/convert/equipment.py. 08 values win; every disagreement between 08 and a d20 source is listed here for a ruling.", ""]
    for title, conf in (("Weapons", cw), ("Armour", ca), ("Gear", cg)):
        rep.append("## %s: %d conflicts" % (title, len(conf)))
        rep.append("| Item | Field | 08 value | d20 value | d20 source |\n| --- | --- | --- | --- | --- |")
        rep += ["| %s | %s | %s | %s | %s |" % c for c in conf]
        rep.append("")
    nc = lambda rows: sum(1 for r in rows if r["status"] == "converted")
    rep.append("## Counts\n\n| Table | Items | From 08 | Merged | Converted (unreviewed) | With Legends link |\n| --- | --- | --- | --- | --- | --- |")
    for title, rows in (("Weapons", weapons), ("Armour", armour), ("Gear", gear)):
        rep.append("| %s | %d | %d | %d | %d | %d |" % (title, len(rows), sum(r["status"] == "sl100" for r in rows), sum(r["status"] == "merged" for r in rows), nc(rows), sum(bool(r["legends"]) for r in rows)))
    rep.append("\n## Materials read from Special Materials\n\n" + ", ".join("%s (%s-%s)" % (k, v[0], v[1]) for k, v in sorted(mats.items())))
    (OUT / "REVIEW.md").write_text("\n".join(rep) + "\n", encoding="utf-8")
    how = save_pages([("SL100:Weapons", weapons_page(weapons, nc(weapons))), ("SL100:Armour", armour_page(armour, nc(armour))), ("SL100:Gear", gear_page(gear, nc(gear)))])
    print("weapons %d, armour %d, gear %d; conflicts %d/%d/%d; pages %s" % (len(weapons), len(armour), len(gear), len(cw), len(ca), len(cg), how))


if __name__ == "__main__":
    main()
