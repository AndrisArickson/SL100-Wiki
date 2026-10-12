#!/usr/bin/env python3
"""Parse run-in starship stat blocks ("Craft: X-wing; Class: Starfighter; Cost: ...; Hull Points: 90; DR: 5.") and their
following "Weapon: ...; Fire Arc: ...; Attack Bonus: ...; Damage: ...; Range Modifiers: ..." paragraphs from every
extracted book.

  starships.py run [SLUG ...]     default: every book that contains "Craft:"

v2 (2026-10-12): a block runs from "Craft:" to its "DR: n", across blank lines, page and column breaks (v1 stopped at
the first blank line and lost 13 Starships of the Galaxy ships). Every row gets arithmetic checks (Defense, Initiative,
Maneuver, Attack Bonus = sum of the printed modifiers; size modifier matches the size; crew bonus matches its label).
Pages whose OCR interleaved a stat block with a neighbouring column can be replaced by hand-checked text in
Source_Text/<slug>/<slug>.blocks.txt ('=== Page n ===' sections; checked against the page image). Hand corrections checked against the page images live in tables/starship_fixes.csv (book, page, name, weapon, field,
value, note) and are applied on every run, so they survive re-parsing; corrected cells are listed in the 'fixed' column.

Writes Source_Text/tables/starship.csv, starship_weapons.csv and starship_check.csv (one line per failed check).
"""
import csv, os, re, sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent))

ROOT = Path(__file__).resolve().parent.parent.parent.parent
TEXT = Path(os.environ.get("SL100_TEXT_DIR", ROOT / "Source_Text"))
OUT = TEXT / "tables"
FIXES = OUT / "starship_fixes.csv"
LABELS = ["Craft", "Class", "Cost", "Size", "Initiative", "Crew", "Passengers", "Cargo Capacity", "Consumables", "Hyperdrive",
          "Nav Computer", "Maximum Speed", "Atmospheric Speed", "Max Speed", "Maneuver", "Defense", "Shield Points", "Hull Points", "DR",
          "Availability", "Type", "Weapon", "Fire Arc", "Attack Bonus", "Damage", "Range Modifiers", "Range Modifier", "Range Increment", "Speed", "Altitude",
          "Range", "Maximum Range", "Max Velocity", "Maximum Velocity", "Missile Quality"]
LABELS.sort(key=len, reverse=True)
FIELD_RE = re.compile(r"(?<![A-Za-z])(%s)(?:\s*[:;]\s*|\s+(?=[+-–]?\s*\d))" % "|".join(re.escape(l) for l in LABELS))   # some books drop the colon
SHIP_KEYS = ["Cost", "Hull Points", "Maneuver", "Shield Points", "Defense", "Initiative"]
SIZE_MOD = {"fine": 8, "diminutive": 4, "tiny": 2, "small": 1, "medium": 0, "large": -1, "huge": -2, "gargantuan": -4, "colossal": -8}
CREW_MOD = {"untrained": -4, "normal": 2, "skilled": 4, "highly skilled": 6, "expert": 8, "master expert": 12, "ace": 12, "very skilled": 6}


def stream(txt):
    """Whole book as one string: page markers become ' \x00PAGE n\x00 ', hyphenated breaks repaired, whitespace collapsed."""
    txt = re.sub(r"=== Page (\d+) ===", lambda m: " \x00%s\x00 " % m.group(1), txt)
    txt = re.sub(r"(?<=[a-z])-\s*\n\s*(?=[a-z])", "", txt)
    txt = re.sub(r"\s+", " ", txt)
    for pat, rep in OCR_LABELS:
        txt = re.sub(pat, rep, txt)
    return txt


# OCR misreadings of field labels seen in the scanned books
OCR_LABELS = [(r"Range [Mm][a-z]{0,3}d[a-z]{1,4}ers", "Range Modifiers"), (r"[FP]ire [Aa]r[ceo](?=\s*[:;])", "Fire Arc"),
              (r"Shield P[a-z]{2,4}ts", "Shield Points"), (r"Hull P[a-z]{2,4}ts", "Hull Points"),
              (r"Man[aec]u?v[ce]rs?(?=\s*[:;])", "Maneuver"), (r"[Il1]nitiative|(?<= )nitiative", "Initiative"),
              (r"Att?ack [Bb]onh?[uo]s", "Attack Bonus"), (r"(?<=[;:] )Cast(?=\s*:)", "Cost"), (r"\bWeapons(?=\s*[:;])", "Weapon"), (r"Dam[ae]ge(?=\s*[:;])", "Damage")]


def page_at(s, pos):
    m = None
    for m in re.finditer(r"\x00(\d+)\x00", s[:pos]):
        pass
    return int(m.group(1)) if m else 0


def clean(v):
    return re.sub(r"\s+", " ", re.sub(r"\x00\d+\x00", " ", v)).strip(" ;:.,")


CAPTION = re.compile(r"(?:\b[A-Z][A-Z0-9'’%-]+\b[ .,:;-]*){2,}|\b[A-Z]{5,}\b")   # ship-art captions ("TIE BOMBER")
JUNK = re.compile(r"(?:(?<=\s)|^)(?:(?![+-]\d)\S{1,2}\s+){6,}")                    # runs of 1-2 char OCR noise from artwork
RANGE = re.compile(r"(?:PB|S|M|L|S/M/L|M/L)\s*(?:[+-]\s*\d+|n/a)(?:\s*[,;:]?\s*(?:S|M|L|S/M/L|M/L)\s*(?:[+-]\s*\d+|n/a))*")


def tidy(k, v):
    """Remove OCR noise from one field value. Book errata are left as printed (see starship_fixes.csv notes)."""
    if not v:
        return v
    v = re.sub(r"(crew|bonus|control)\s*[®”™°\"*]+", r"\1*", v)
    v = re.sub(r"(?<=\+\d)%|(?<=\+\d\d)%|(?<=\d)°", "*", v)                     # 'Skilled +8%' / 'Normal +2°' = footnote *          # footnote asterisk read as ® or ”
    v = v.replace("®", "").replace("™", "").replace("”", "").replace("“", "")
    if k not in ("weapon",):
        v = CAPTION.sub(" ", v) if k not in ("Craft", "name") else v
        v = JUNK.sub(" ", v)
    v = re.sub(r"[\[{]", "(", v); v = re.sub(r"[\]}]", ")", v)
    v = re.sub(r"(?<=\d)\s*%\s*(?=x)", "", v)                               # 4d10%x2
    v = re.sub(r"(?<=[(\s])%(?=\d)", "x", v)                                  # backup %8
    v = re.sub(r"\bx\s*[|lI](?![A-Za-z0-9])", "x1", v)                                     # x| -> x1
    v = re.sub(r"^\s*[|lI](?=\s)", "1", v)                                     # Crew: | (Normal +2)
    v = re.sub(r"(?<=[\s(,])=\s*(?=\d)", "-", v); v = v.replace("—", "-").replace("–", "-")
    v = re.sub(r"(?<=[\s(,])4(?=[01]\b)", "+", v) if k in ("Range Modifiers",) else v
    if k == "DR":
        v = v.strip("() ")
    if k in ("Initiative", "Maneuver", "Defense", "Attack Bonus"):
        v = re.sub(r"(?<=[\s(,])4(?=\d size)", "+", v)
        v = re.sub(r"(\d)size", r"\1 size", v)
    if k == "Range Modifiers":
        v = re.sub(r"\bS\s*5\b|\b5S\b|§|\$", "S", v); v = re.sub(r"(?<=[,;]\s)5(?=\s*[+-])|(?<=,)5(?=\s*[+-])", "S", v)
        v = re.sub(r"\bPR\b", "PB", v); v = re.sub(r"\bnfa\b|\bnia\b", "n/a", v); v = re.sub(r"\+O0|\+O\b", "+0", v)
        m = RANGE.search(v)
        v = m.group(0) if m else v
    v = re.sub(r"\blon\b", "Ion", v)
    if k == "Damage":
        v = v.lstrip("‘’'\" ")
        v = re.sub(r"(\d)\s*d\s*(\d)", r"\1d\2", v); v = re.sub(r"(\d)\s*[x×X]\s*(\d)", r"\1x\2", v)
    v = v.replace("Fronl", "Front").replace("armoar", "armor").replace("guality", "quality")
    return re.sub(r"\s+", " ", v).strip(" ;:.,")


def fields(text):
    pos = [(m.start(), m.end(), m.group(1).strip()) for m in FIELD_RE.finditer(text)]
    out = {}
    for i, (s, e, k) in enumerate(pos):
        v = clean(text[e: pos[i + 1][0] if i + 1 < len(pos) else len(text)])
        if k not in out:
            out[k] = tidy(k, v)
    return out


def num(v):
    m = re.search(r"\d[\d,]*", v or "")
    return m.group(0).replace(",", "") if m else ""


def sint(v):
    m = re.match(r"\s*([+-]?)\s*(\d+)", (v or "").replace("=", "-").replace("–", "-"))
    return None if not m else int(m.group(2)) * (-1 if m.group(1) == "-" else 1)


def mods(v):
    """'+6 (+4 size, +2 crew)' -> (6, [4, 2])"""
    m = re.match(r"\s*([+-]?\s*\d+)\**\s*[\(\[\{]([^)\]\}]*)", (v or "").replace("=", "-").replace("–", "-"))
    if not m:
        return None, []
    parts = [sint(x) for x in re.findall(r"[+-]\s*\d+", m.group(2))]
    return sint(m.group(1)), [p for p in parts if p is not None]


def lab(v, label):
    m = re.search(r"([+-]\s*\d+)\s*%s" % label, (v or "").replace("=", "-"))
    return sint(m.group(1)) if m else None


def checks(r):
    out = []
    size = (r.get("Size") or "").lower()
    smod = next((v for k, v in SIZE_MOD.items() if size.lstrip("'\" ").startswith(k)), None)
    crew = (r.get("Crew") or "").lower()
    cm = re.search(r"(untrained|normal|highly skilled|very skilled|skilled|master expert|expert|ace)\s*([+-]?\s*\d+)", crew)
    yam = "*" in crew and cm and sint(cm.group(2)) == (CREW_MOD.get(cm.group(1)) or 0) + 4   # NJO: '*Includes +4 competence bonus from yammosk'
    old_untrained = cm and cm.group(1) == "untrained" and sint(cm.group(2)) == 0     # pre-2002 books: Untrained +0
    if cm and CREW_MOD.get(cm.group(1)) != sint(cm.group(2)) and not yam and not old_untrained:
        out.append("crew label %s but bonus %s" % (cm.group(1), cm.group(2)))
    d = r.get("Defense", "")
    tot, parts = mods(d)
    if d and tot is not None and parts and tot != 10 + sum(parts):
        out.append("Defense %s != 10 + %s" % (tot, sum(parts)))
    if d and smod is not None and lab(d, "size") is not None and lab(d, "size") != smod:
        out.append("Defense size mod %s, size says %s" % (parts[0], smod))
    for k in ("Initiative", "Maneuver"):
        tot, parts = mods(r.get(k))
        if r.get(k) and tot is None and not re.match(r"\s*([+-]\s*\d+|n/a|nfa)", r.get(k).lower()):
            out.append("%s unreadable" % k)
        elif tot is not None and parts and tot != sum(parts):
            out.append("%s %s != sum %s" % (k, tot, sum(parts)))
        if tot is not None and smod is not None and lab(r.get(k), "size") not in (None, smod):
            out.append("%s size mod %s, size says %s" % (k, lab(r.get(k), "size"), smod))
    for k in ("Shield Points", "Hull Points", "DR"):
        if r.get(k) and not re.fullmatch(r"(\d[\d,]*\**( \([^)]*\)?)?(, \d[\d,]* \([^)]*\))*|None|n/a)", r[k]):
            out.append("%s not a plain number: %r" % (k, r[k]))
    keys = SHIP_KEYS
    if not re.search(r"starfighter|space|capital|station|^transport$", (r.get("Class") or "").lower().strip()):
        keys = [k for k in keys if k != "Shield Points"]                       # ground/air vehicles have no shields
    if not r.get("Initiative") and not r.get("Maneuver"):
        keys = [k for k in keys if k not in ("Initiative", "Maneuver")]   # original (2000) core-rules format has neither
    for k in keys:
        if not r.get(k):
            out.append("missing " + k)
    return out


def wchecks(w):
    out = []
    tot, parts = mods(w.get("Attack Bonus"))
    if tot is not None and parts and tot != sum(parts):
        out.append("Attack Bonus %s != sum %s" % (tot, sum(parts)))
    dmg = w.get("Damage", "")
    if dmg and not re.fullmatch(r"(\d+d\d+(\s*[x×]\s*\d+)?([+-]\d+)?([a-z ]+)?(/\d\d-20)?|Special|special|.*\(.*\).*)", dmg.replace(" ", "")):
        out.append("Damage odd: %r" % dmg)
    for k in ("Fire Arc", "Attack Bonus", "Damage"):
        if k == "Attack Bonus" and (w.get("Missile Quality") or "Missile Quality" in w.get("Damage", "")):
            continue                                   # missiles roll with Missile Quality instead of an attack bonus
        if not w.get(k):
            out.append("missing " + k)
    return out


def parse_book(slug):
    f = TEXT / slug / (slug + ".raw.txt")         # reading-order text (tools/books/rawtext.py) when the -layout text interleaves columns
    if not f.exists():
        f = TEXT / slug / (slug + ".txt")
    if not f.exists():
        return [], []
    txt = f.read_text(encoding="utf-8", errors="replace")
    ov = TEXT / slug / (slug + ".blocks.txt")      # hand-checked stat-block text for pages whose OCR mixed in other columns
    if ov.exists():
        pages = dict(re.findall(r"=== Page (\d+) ===\n(.*?)(?==== Page \d+ ===|\Z)", ov.read_text(encoding="utf-8"), re.S))
        txt = re.sub(r"(=== Page (\d+) ===\n)(.*?)(?==== Page \d+ ===|\Z)",
                     lambda m: m.group(1) + pages[m.group(2)] if m.group(2) in pages else m.group(0), txt, flags=re.S)
    s = stream(txt)
    ships, weps = [], []
    starts = [m.start() for m in re.finditer(r"(?<![A-Za-z])Craft\s*[:;](?=\s*[A-Z])", s)
              if not s[m.end():m.end() + 8].lstrip().startswith("Class")]   # "... Patrol Craft; Class:" is part of a name
    for i, st in enumerate(starts):
        lim = starts[i + 1] if i + 1 < len(starts) else len(s)
        lim = min(lim, st + 3000)
        e = re.search(r"(?<![A-Za-z(])DR\s*[:;.]?\s*\d+\s*[.,:]?(?!\s*\))", s[st:lim])   # not the '(DR 20)' after shields
        e2 = re.search(r"Hull P[a-z]{2,4}ts\s*[:;]?\s*[\d,]+\s*\(DR\s*\d+\)\.?", s[st:lim])   # '... Hull Points: 180 (DR 20).'
        if e2 and (not e or e2.end() < e.end()):
            e = e2
        if not e:
            continue
        end = st + e.end()
        d = fields(s[st:end])
        if "Hull Points" not in d and "Defense" not in d and "Maneuver" not in d:
            continue                       # not a d20 stat block (e.g. West End Games d6 entry)
        nm = re.match(r"Craft\s*[:;]\s*(.*?)\s*[:;.,]?\s*Class\s*[:;]", s[st:end])
        name = clean(nm.group(1)) if nm else d.get("Craft", "")
        for k in ("Hull Points", "Shield Points"):
            m2 = re.search(r"\(?\s*DR\s*(\d+)\)?", d.get(k, ""))
            if m2:
                d["DR"] = d.get("DR") or m2.group(1)
                d[k] = d[k][:m2.start()].strip(" ;,(")
        if re.fullmatch(r"(?i)none|o", d.get("Shield Points", "")):
            d["Shield Points"] = "0" if d["Shield Points"] == "O" else "None"
        row = dict(book=slug, page=page_at(s, st), name=name, **{k: v for k, v in d.items() if k != "Craft"})
        row["cost_cr"] = num(d.get("Cost"))
        ships.append(row)
        # weapons: consecutive "Weapon:" blocks, each ending at its Range Modifiers / Range Increment value
        pos = end
        while True:
            m = re.search(r"(?<![A-Za-z])Weapons?\s*[:;]", s[pos:lim])
            if not m or m.start() > 400:
                break
            ws = pos + m.start()
            r = re.search(r"Range (Modifiers?|Increment)\s*[:;]\s*(.{0,90}?)(\.\s|\.$|$)|(?<![A-Za-z])Range\s*[:;]\s*[\d,]+\s*(m|km)\b\.?|Maximum Range\s*[:;]\s*\w+\.?", s[ws:lim])
            if re.match(r"Weapons?\s*[:;]\s*None\b", s[ws:ws + 20]):
                break
            if not r and not re.search(r"Fire Arc|Attack Bonus|Damage", s[ws:ws + 200]):
                r = re.search(r"\.(\s|$)", s[ws:lim])                         # 'Weapon: 25-kg rocks (2).' - no stat line
            we = ws + (r.end() if r else min(400, lim - ws))
            wd = fields(s[ws:we])
            weps.append(dict(book=slug, page=page_at(s, ws), ship=name, weapon=wd.get("Weapon", ""),
                             **{k: v for k, v in wd.items() if k != "Weapon"}))
            pos = we
    return ships, weps


def load_fixes():
    if not FIXES.exists():
        return []
    return list(csv.DictReader(open(FIXES, encoding="utf-8")))


def apply_fixes(rows, fixes, kind):
    for fx in sorted(fixes, key=lambda f: f["field"] == "name"):      # renames last, so other fixes can use the parsed name
        is_w = bool(fx.get("weapon"))
        if is_w != (kind == "w"):
            continue
        hit = [r for r in rows if r["book"] == fx["book"] and (r["name"] if kind == "s" else r["ship"]) == fx["name"]
               and (not fx.get("page") or str(r["page"]) == str(fx["page"]))
               and (kind == "s" or r["weapon"] == fx["weapon"])]
        if fx["field"] == "__add__" and not hit:        # a block the text lost entirely: value is 'k=v|k=v'
            new = dict(book=fx["book"], page=fx["page"])
            new.update(dict(kv.split("=", 1) for kv in fx["value"].split("|")))
            new.setdefault("name" if kind == "s" else "ship", fx["name"])
            new["fixed"] = "added"
            rows.append(new)
            continue
        for r in hit:
            if fx["field"] == "__delete__":
                r["__delete__"] = 1
                continue
            r[fx["field"]] = fx["value"]
            if fx["field"] != "erratum":
                r["fixed"] = ";".join(x for x in [r.get("fixed", ""), fx["field"]] if x)
    rows[:] = [r for r in rows if not r.get("__delete__")]


def write(name, rows, first=None):
    if not rows:
        return
    OUT.mkdir(parents=True, exist_ok=True)
    cols = list(first or [])
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
                 and (re.search(r"Craft\s*[:;]", (d / (d.name + ".txt")).read_text(encoding="utf-8", errors="replace"))
                      or (d / (d.name + ".blocks.txt")).exists())]
    S, W = [], []
    for s in slugs:
        a, b = parse_book(s)
        if a:
            print("%-60s %3d ships %3d weapons" % (s, len(a), len(b)))
        S += a; W += b
    fixes = load_fixes()
    renamed = {(f["book"], f["name"]): f["value"] for f in fixes if f["field"] == "name" and not f.get("weapon")}
    apply_fixes(S, fixes, "s"); apply_fixes(W, fixes, "w")
    for w in W:                                   # weapons follow a corrected ship name
        w["ship"] = renamed.get((w["book"], w["ship"]), w["ship"])
    import ocrfix                                 # common OCR name slips (Maodified, lon cannon, ...), after the fixes file
    for r in S:
        r["name"] = ocrfix.fix_name(r["name"])
    for w in W:
        w["ship"], w["weapon"] = ocrfix.fix_name(w["ship"]), ocrfix.fix_name(w["weapon"])
    for r in S:
        r["cost_cr"] = num(r.get("Cost"))
    C = []
    for r in S:
        c = checks(r)
        if r.get("erratum"):                     # confirmed against the page image: the book itself prints this
            c = ["as printed in book: " + x for x in c] or ["note: " + r["erratum"]]
        r["check"] = "; ".join(c)
        C += [dict(book=r["book"], page=r["page"], name=r["name"], weapon="", problem=p) for p in c]
    for w in W:
        c = wchecks(w)
        if w.get("erratum"):
            c = ["as printed in book: " + x for x in c] or ["note: " + w["erratum"]]
        w["check"] = "; ".join(c)
        C += [dict(book=w["book"], page=w["page"], name=w["ship"], weapon=w["weapon"], problem=p) for p in c]
    write("starship", S, ["book", "page", "name"]); write("starship_weapons", W, ["book", "page", "ship", "weapon"])
    write("starship_check", C, ["book", "page", "name", "weapon", "problem"])
    # The Revised Core Rulebook prints its vehicles as tables; its hand-checked blocks (…/<slug>.blocks.txt) are parsed
    # here like any other book. core_vehicle.csv keeps the RCR subset under its old name for wikimatch/ships_compare.
    space = re.compile(r"(?i)starfighter|space|capital")
    core = [r for r in S if r["book"] == "SW_Revised_Core_Rulebook_WTC17650" and not space.search(r.get("Class", ""))]
    if core:                                     # RCR ground and air vehicles; its spacecraft stay in starship.csv
        write("core_vehicle", core, ["book", "page", "name"])
        cw = [w for w in W if w["book"] == "SW_Revised_Core_Rulebook_WTC17650" and w["ship"] in {r["name"] for r in core}]
        write("core_vehicle_weapons", cw, ["book", "page", "ship", "weapon"])
        keep = {id(r) for r in core}
        S2 = [r for r in S if id(r) not in keep]
        W2 = [w for w in W if w not in cw]
        write("starship", S2, ["book", "page", "name"]); write("starship_weapons", W2, ["book", "page", "ship", "weapon"])


if __name__ == "__main__":
    a = sys.argv[1:]
    main(a[1:] if a and a[0] == "run" else a)
