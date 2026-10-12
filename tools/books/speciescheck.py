#!/usr/bin/env python3
"""Tidy and check tables/d20_species.csv (made by refblocks.py) - 2026-10-12.

  speciescheck.py        normalise OCR slips, fill size/speed from the trait text, apply tables/species_fixes.csv,
                         write tables/species_check.csv

- ability_modifiers: '=2'/'~2'/'—2' -> '-2', '42 Charisma' -> '+2 Charisma', misspelt ability names repaired
  (Counstitution, Stiength, fntelligence ...), 'Nome'/'None,' -> 'None'; a new column ability_sum is added.
- size / speed: taken from the trait lines ('Medium-size: As Medium-size creatures ...', 'base speed is 10 meters')
  when the column is empty; speed OCR slips ('is 1) meters', '15 10 meters') are flagged, not guessed.
- Rows from Ultimate Adversaries are creature write-ups, not playable species: kind becomes 'creature traits' and they
  are left to tools/books/creatures.py (full creature stat blocks).
"""
import csv, difflib, re, sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import starships as SS                                    # noqa: E402  (paths)

TAB = SS.TEXT / "tables"
FIXES = TAB / "species_fixes.csv"
ABIL = ["Strength", "Dexterity", "Constitution", "Intelligence", "Wisdom", "Charisma"]
SIZES = r"(Fine|Diminutive|Tiny|Small|Medium-size|Medium|Large|Huge|Gargantuan|Colossal)"
NOT_SPECIES = {"Reading the Entries", "Species", "Individual Creatures", "Era Notes", "Core Worlds"}


def norm_abil(v):
    v = (v or "").strip()
    if re.fullmatch(r"(?i)(nome|none)[,.]?|no ability modifiers\.?", v):
        return "None"
    v = v.split(". ")[0]                                   # 'Vodrans who l...' run-on prose
    v = re.sub(r"(\w)-\s+(\w)", r"\1\2", v)                  # 'Con- stitution'
    v = re.sub(r"(?<![\w+-])[=~—–]\s*(?=\d)", "-", v)
    v = re.sub(r"(?<![\w+-])4(?=\d\s+[A-Za-z])", "+", v)    # '42 Charisma' -> '+2 Charisma'
    out = []
    for sign, n, word in re.findall(r"([+-])\s*(\d+)\s+([A-Za-z]+)", v):
        w = difflib.get_close_matches(word.capitalize().replace("Ntelligence", "Intelligence"), ABIL, n=1, cutoff=0.6)
        out.append("%s%s %s" % (sign, n, w[0] if w else word))
    return ", ".join(out) if out else v


def abil_sum(v):
    return sum(int(s + n) for s, n in re.findall(r"([+-])(\d+) ", v + " ")) if v and v != "None" else 0


FUZZY_SIZE = r"(Fine|Diminutive|Tiny|Small|Medi\w{1,3}-\s?size|Medium|Large|Huge|Gargantuan|Colossal)"
_BOOKTEXT = {}


def book_text(slug):
    """Whole book (reading-order text if there is one), whitespace collapsed - for traits the table row lost."""
    if slug not in _BOOKTEXT:
        d = SS.TEXT / slug
        f = d / (slug + ".raw.txt") if (d / (slug + ".raw.txt")).exists() else d / (slug + ".txt")
        _BOOKTEXT[slug] = re.sub(r"\s+", " ", f.read_text(encoding="utf-8", errors="replace")) if f.exists() else ""
    return _BOOKTEXT[slug]


def page_text(slug, page):
    f = SS.TEXT / slug / "pages" / ("%04d.txt" % int(page))
    return re.sub(r"\s+", " ", f.read_text(encoding="utf-8", errors="replace")) if f.exists() else ""


def near_text(r):
    """Trait text, then the species' own page and the next one from the first trait line after its name."""
    t = r.get("traits_text", "")
    try:
        pt = page_text(r["book"], r["page"]) + " " + page_text(r["book"], int(r["page"]) + 1)
    except ValueError:
        return t
    i = pt.find(r["species"])
    j = pt.find("Ability M", i if i >= 0 else 0)
    if j >= 0:
        t += " | " + pt[j:j + 3000]
    return t


def abil_near(r):
    m = re.search(r"Ability M\w*ifiers\s*:\s*(.{0,120}?)(?:\.\s|\s[@&®•G]\s)", near_text(r))
    if not m:
        return ""
    v = m.group(1)
    if re.match(r"(?i)(none|nome)\b", v):
        return "None"
    words = re.findall(r"[+=~—–-]\s*\d+\s+([A-Za-z]{3,})", re.sub(r"(\w)-\s+(\w)", r"\1\2", v))
    return norm_abil(v) if words and all(is_abil(w) for w in words) else ""


def is_abil(word):
    return bool(difflib.get_close_matches(word.capitalize(), ABIL, n=1, cutoff=0.7))


def abil_from(r):
    for seg in re.split(r" \| |\s{2,}", r.get("traits_text", "")):
        seg = re.sub(r"(?i)^\W*ability m\w*ifiers\s*:\s*", "", seg.strip(" :"))
        head = seg.split(":")[0]
        words = re.findall(r"[+=~—–-]\s*\d+\s+([A-Za-z]{3,})", re.sub(r"(\w)-\s+(\w)", r"\1\2", head))
        if words and all(is_abil(w) for w in words):
            return norm_abil(head)
        if re.fullmatch(r"(?i)\W*ability m\w*ifiers\s*:\s*(none|nome)\W*", r.get("traits_text", "")[:40] + " ") or \
                re.match(r"(?i)\W*(none|nome)[.,]", seg) and "ability" in r.get("traits_text", "")[:60].lower():
            return "None"
    return ""


def size_from(r):
    m = re.search(r"(?:^|\| |: |[@&®•] )%s(?: \([^)]*\))?\s*[:.]" % FUZZY_SIZE, near_text(r))
    if not m:
        return ""
    s = m.group(1)
    return "Medium-size" if s.lower().startswith("medi") and "size" in s else s


def speed_from(r):
    m = re.search(r"base speed (?:on land )?(?:is |of |s )?(\d+) (?:me|m\b)", near_text(r) + " " + r.get("speed", ""))
    return (m.group(1) + " m") if m else ""


def main():
    rows = list(csv.DictReader(open(TAB / "d20_species.csv", encoding="utf-8")))
    cols = list(rows[0].keys())
    for c in ("ability_sum", "check", "fixed"):
        if c not in cols:
            cols.append(c)
    fixes = list(csv.DictReader(open(FIXES, encoding="utf-8"))) if FIXES.exists() else []
    C = []
    for r in rows:
        if "Ultimate_Adversaries" in r["book"]:
            r["kind"] = "creature traits"
        derived = abil_from(r) or abil_near(r)      # the trait line itself beats the parsed column (lost 'Consti- tution')
        r["ability_modifiers"] = derived or norm_abil(r["ability_modifiers"])
        if not re.fullmatch(SIZES + r"( \(.*\))?", r.get("size") or ""):
            r["size"] = size_from(r) or r.get("size", "")
        if not re.fullmatch(r"\d+ m.*", r.get("speed") or ""):
            r["speed"] = speed_from(r) or r.get("speed", "")
        orig = r["species"]
        for fx in sorted(fixes, key=lambda f: f["field"] == "species"):          # renames last
            if fx["book"] == r["book"] and fx["page"] == r["page"] and fx["species"] == orig:
                if fx["field"] == "erratum":
                    r["erratum"] = fx["value"]
                elif fx["field"] == "__delete__":
                    r["__delete__"] = 1
                else:
                    r[fx["field"]] = fx["value"]
                    r["fixed"] = ";".join(x for x in [r.get("fixed", ""), fx["field"]] if x)
        r["ability_sum"] = abil_sum(r["ability_modifiers"])
        p = []
        if r.get("__delete__"):
            continue
        if r["kind"] == "species":
            if r["species"] in NOT_SPECIES:
                p.append("not a species entry (book heading)")
            if not r["ability_modifiers"]:
                p.append("missing ability modifiers")
            elif r["ability_modifiers"] != "None" and not re.fullmatch(
                    r"([+-]\d+ (%s))(, [+-]\d+ (%s))*" % ("|".join(ABIL), "|".join(ABIL)), r["ability_modifiers"]):
                p.append("ability modifiers odd: %r" % r["ability_modifiers"][:60])
            if not re.fullmatch(SIZES + r"( \(.*\))?", r.get("size") or ""):
                p.append("missing size")
            if not re.fullmatch(r"\d+ m.*", r.get("speed") or ""):
                p.append("missing speed")
            if r.get("erratum"):
                p = ["as printed in book: " + x for x in p] or ["note: " + r["erratum"]]
        r["check"] = "; ".join(p)
        C += [dict(book=r["book"], page=r["page"], species=r["species"], problem=x) for x in p]
    rows = [r for r in rows if not r.get("__delete__")]
    for r in rows:
        r.pop("__delete__", None)
    if any("erratum" in r for r in rows) and "erratum" not in cols:
        cols.append("erratum")
    with open(TAB / "d20_species.csv", "w", newline="", encoding="utf-8") as fh:
        w = csv.DictWriter(fh, fieldnames=cols, extrasaction="ignore"); w.writeheader(); w.writerows(rows)
    with open(TAB / "species_check.csv", "w", newline="", encoding="utf-8") as fh:
        w = csv.DictWriter(fh, fieldnames=["book", "page", "species", "problem"]); w.writeheader(); w.writerows(C)
    print("d20_species.csv %d rows (%d species); species_check.csv %d lines"
          % (len(rows), sum(r["kind"] == "species" for r in rows), len(C)))


if __name__ == "__main__":
    main()
