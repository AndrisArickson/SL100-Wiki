#!/usr/bin/env python3
"""Collate how an SL100 character is assembled, layer by layer, from the design documents - as written, no new rules.

  assembly.py -> docs/collation/species.csv, origins.csv, factions.csv, careers_l1.csv, character_assembly.md

Layers (in the order the documents give them): Characteristics -> Species -> Origin (world upbringing)
-> Career (class, career, level) -> Faction (background / Patron / flavour).
"""
import csv, re
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
import common as C   # noqa: E402

WIKI = Path(__file__).resolve().parent.parent.parent
OUT = WIKI / "docs" / "collation"
D = {k: C.RULES_DIR / v for k, v in {"01": "01 New Star Wars - Introduction & Characteristics.md", "02": "02 New Star Wars - Species (revised).md",
                               "03": "03 New Star Wars - Origin.md", "04": "04 New Star Wars - Faction.md",
                               "05": "05 New Star Wars - Careers (revised).md"}.items()}
NAME = {k: C.page_of(v) for k, v in D.items()}
REVISED05 = "(revised)" in str(D["05"])
REVISED02 = "(revised)" in str(D["02"])
CHAR = r"(WS|BS|S|STR|T|TOU|I|INI|AG|AGI|AGL|DEX|INT|WP|WIL|WILL|FEL)"


def txt(k):
    return D[k].read_text(encoding="utf-8", errors="replace")


def plain(s):
    s = re.sub(r"&#\d+;|&nbsp;| ", " ", s)
    s = re.sub(r"\[([^\]]*)\]\([^)]*\)", r"\1", s)
    s = re.sub(r"\[\[(?:[^\]|]*\|)?([^\]]*)\]\]", r"\1", s)   # [[Page|label]] -> label
    s = re.sub(r"<br\s*/?>", " ", s)
    return re.sub(r"\s+", " ", re.sub(r"[*_`]", "", s)).strip(" |")


def species():
    rows, cur = [], None
    for i, ln in enumerate(txt("02").split("\n"), 1):
        m = re.match(r"^(?:#{1,6}\s*)?\[([^\]]+)\]\((https?://[^)]+)\)\s*$", ln.strip())
        h = re.match(r"^#{2,6}\s*([A-Z][^\[\]]{1,40})$", ln.strip())
        # 02 (revised) gives every species a linked heading; its other headings are sections.
        if m or (h and not REVISED02 and plain(h.group(1)).upper() != "SPECIES"):
            cur = {"species": plain(m.group(1) if m else h.group(1)), "wookieepedia": m.group(2) if m else "", "line": i,
                   "characteristics": "", "talents": "", "movement": "", "fate": "", "resilience": "", "extra_points": "",
                   "size": "", "natural_weapons": "", "other": ""}
            rows.append(cur); continue
        if cur is None:
            continue
        p = plain(ln)
        if not p:
            continue
        mods = re.findall(r"\b%s\s*([+\-−]\s?\d+)" % CHAR, p.replace("Characteristics:", ""), re.I)
        if mods and not cur["characteristics"]:
            cur["characteristics"] = " ".join("%s %s" % (a.upper(), b.replace(" ", "")) for a, b in mods)
        t = re.search(r"Talents\s*:?\s*(.*?)(?=$|Mv\b|Movement)", p, re.I)
        if t and not cur["talents"]:
            cur["talents"] = t.group(1).strip(" ,.")
        for key, rx in (("movement", r"(?:Mv|Movement)\s*:?\s*(\d+)"), ("fate", r"(?:Destiny|Fate)\s*:?\s*(\d+)"),
                        ("resilience", r"Resilience\s*:?\s*(\d+)"), ("extra_points", r"Extra [Pp]oints\s*:?\s*(\d+)"),
                        ("size", r"Size\s*:?\s*(\w+)"), ("natural_weapons", r"Natural Weapons?\s*:?\s*(.*)$")):
            v = re.search(rx, p, re.I)
            if v and not cur[key]:
                cur[key] = v.group(1).strip()
    for r in rows:
        missing = [k for k in ("characteristics", "talents", "movement", "fate", "resilience") if not r[k]]
        r["other"] = ("missing: " + ", ".join(missing)) if missing else ""
    return rows


def origins():
    """03 Origin: the d100 table (D100 | Origin | +5 to | and +5 to one of) and one ### section per world."""
    t = txt("03")
    table = {}
    for m in re.finditer(r"^\|\s*([\d\-–]+)\s*\|\s*\*\*(.+?)\*\*\s*\|\s*(.*?)\s*\|\s*(.*?)\s*\|\s*$", t, re.M):
        table[plain(m.group(2))] = (m.group(1), plain(m.group(3)), plain(m.group(4)))
    rows = []
    for m in re.finditer(r"^### (.+?)\s*$(.*?)(?=^##|\Z)", t, re.M | re.S):
        name, body = plain(m.group(1)), m.group(2)
        sk = re.search(r"Starting Skills:\*\*\s*(.*)", body)
        if not sk:
            continue
        ch = re.search(r"Starting Characteristics:\*\*\s*(.*)", body)
        ex = re.search(r"Example worlds:\*\*\s*(.*)", body)
        desc = plain(body.strip().split("\n")[0])
        short = re.sub(r"\s+Worlds?$", "", name)
        d100, fixed, choice = table.get(short, ("", "", ""))
        rows.append({"origin": name, "d100": d100, "fixed_plus5": fixed, "choice_plus5": choice,
                     "characteristics": plain(ch.group(1)) if ch else "", "starting_skills": plain(sk.group(1)),
                     "examples": plain(ex.group(1)) if ex else "", "description": desc[:300]})
    return rows


def factions():
    rows, sec, sub = [], "", ""
    for ln in txt("04").split("\n"):
        s = ln.strip()
        if s.startswith("## "):
            sec, sub = plain(s[3:]), ""
        elif sec in ("How Factions work", "FACTIONS"):
            continue
        elif s.startswith("### "):
            sub = plain(s[4:])
        elif s.startswith("|"):
            c = [plain(x) for x in s.strip("|").split("|")]
            if len(c) >= 2 and c[0] and not re.fullmatch(r"[-: ]+", c[0]) and c[0] not in ("Tradition", "Organisation", "Organization", "Corporation", "Faction", "Name"):
                rows.append({"section": sec, "group": sub, "faction": c[0], "description": c[1] if len(c) > 1 else "", "era": c[2] if len(c) > 2 else ""})
    return rows


def careers():
    rows, cls, career, take = [], "", "", False
    for ln in txt("05").split("\n"):
        s = ln.strip()
        if re.match(r"^###\s", s):
            career = plain(s[3:])
        elif re.match(r"^##\s", s):
            if REVISED05:
                cls, career = ("" if plain(s[2:]) == "Index" else plain(s[2:])), ""
            else:
                career = plain(s[2:])
        elif re.match(r"^#\s", s):
            cls = plain(s[1:])
        m = re.match(r"^\*\*(\d)\.\s*(.*?)\*\*(?:\s*`\[[^\]]*\]`)?$", s)
        if m:
            take = m.group(1) == "1"
            if take and career:
                rows.append({"class": cls, "career": career, "level_1": plain(m.group(2)), "skills": "", "talents": "", "trappings": ""})
            continue
        f = re.match(r"^\*\*(Skills|Talents|Trappings)\s*:?\*\*\s*:?\s*(.*)$", s)
        if f and take and rows:
            rows[-1][f.group(1).lower()] = plain(f.group(2))
    return rows


def write(name, rows):
    if rows:
        with open(OUT / name, "w", newline="", encoding="utf-8") as fh:
            w = csv.DictWriter(fh, fieldnames=list(rows[0]))
            w.writeheader(); w.writerows(rows)


def quote(k, rx, n=1):
    m = re.search(rx, txt(k), re.M | re.S)
    if not m:
        return "(not found on %s)" % NAME[k]
    q = plain(m.group(n))
    return q if len(q) < 260 else q[:q.rfind(" ", 0, 250)] + " ..."


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    sp, og, fa, ca = species(), origins(), factions(), careers()
    write("species.csv", sp); write("origins.csv", og); write("factions.csv", fa); write("careers_l1.csv", ca)
    md = ["# How an SL100 character is assembled (as the documents describe it today)", "",
          "Collated by `tools/collate/assembly.py` from the Characteristics, Species, Origin, Faction and Careers pages. Everything below is quoted or tabulated from the documents; "
          "nothing has been added or decided. Where a document is silent, that is shown as a gap. Full tables: "
          "`species.csv`, `origins.csv`, `careers_l1.csv`, `factions.csv`.", "",
          "| Step | Layer (wiki page) | What it gives the character, as written | Where the detail is |", "|---|---|---|---|",
          "| 1 | Characteristics | %s | Characteristics, 'Creating a Character' |" % quote("01", r"Step 1:\s*(.*?)(?:\s+If you feel|\n)"),
          "| 2 | Species | characteristic modifiers, talents (some 'roll 3 random talents'), Movement, Fate, Resilience, Extra Points; some list Size and natural weapons | species.csv (%d species) |" % len(sp),
          "| 3 | Origin - world upbringing | %s | origins.csv (%d world types) |" % (quote("03", r"- \*\*Skills:\*\* (.*?)$"), len(og)),
          "| 4 | Careers | class, career and four levels; each level lists Skills, Talents, Trappings and a Status; the Advance Scheme opens characteristics | careers_l1.csv (level 1 of %d careers); Careers |" % len(ca),
          "| 5 | Faction | %s | factions.csv (%d entries) |" % (quote("04", r"## CAREER PATH & FACTION\s*(.*?)\n"), len(fa)), "",
          "## What each layer says about the next (cross-references in the text)", "",
          "- Characteristics -> Origin: \"%s\"" % quote("01", r"(Your \*\*Origin\*\* world grants.*?Advances\.)"),
          "- Characteristics step order: \"%s\"" % quote("01", r"(move on to 2\) Origin on page \d+)"),
          "- Origin -> Faction: \"%s\"" % quote("03", r"(The circumstances of your early life.*?Faction\.)"),
          "- Faction -> Patron / Force traditions: \"%s\"" % quote("04", r"(Your Faction describes.*?)\n"), "",
          "## Gaps the collation found (for the rules discussion)", ""]
    gaps = []
    gaps += ["- Species with missing fields: " + "; ".join("%s (%s)" % (r["species"], r["other"][9:]) for r in sp if r["other"])]
    if "nine characteristics" in txt("01").lower():
        gaps.append("- Characteristics says 'nine Characteristics'; the Careers Advance Schemes and the Roll20 sheet have ten (with Dex).")
    if "Origin" in txt("01") and not re.search(r"Species", txt("01")):
        gaps.append("- Characteristics sends you straight to '2) Origin'; Species is not mentioned in its steps.")
    gaps.append("- Origin's d100 table: values as printed are %s." % ", ".join(r["d100"] or "?" for r in og))
    if "How Factions work" not in txt("04"):
        gaps.append("- Faction gives lore and eras but no game effects (no skills, talents, characteristics or Patron rules are written).")
        gaps.append("- The documents do not say where Faction sits in the creation order or how Origin changes the chance of a Faction.")
    md += gaps + ["", "## Species at a glance", "", "| Species | Characteristics | Talents | Mv | Fate | Res | Extra |", "|---|---|---|---|---|---|---|"]
    md += ["| %s | %s | %s | %s | %s | %s | %s |" % (r["species"], r["characteristics"], r["talents"][:90], r["movement"], r["fate"], r["resilience"], r["extra_points"]) for r in sp]
    md += ["", "## Origins at a glance", "", "| d100 | Origin | Characteristics | 12 starting skills |", "|---|---|---|---|"]
    md += ["| %s | %s | %s | %s |" % (r["d100"], r["origin"], r["characteristics"], r["starting_skills"]) for r in og]
    md += ["", "## Careers (level 1) at a glance", "", "| Class | Career | Level 1 | Skills | Talents |", "|---|---|---|---|---|"]
    md += ["| %s | %s | %s | %s | %s |" % (r["class"], r["career"], r["level_1"], r["skills"], r["talents"]) for r in ca]
    (OUT / "character_assembly.md").write_text("\n".join(md) + "\n", encoding="utf-8")
    print("species %d, origins %d, factions %d, careers %d" % (len(sp), len(og), len(fa), len(ca)))
    print("\n".join(md[5:12])); print("\n".join(gaps))


if __name__ == "__main__":
    main()
