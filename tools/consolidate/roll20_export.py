#!/usr/bin/env python3
"""Roll20 hand-off: rules/roll20/{skills,talents,careers}.csv built from the live chapters (06, 07 revised, 05 revised).
Run after tools/consolidate/consolidate.py."""
import re, csv, pathlib
ROOT = pathlib.Path(__file__).resolve().parents[2]
OUT = ROOT / "rules" / "roll20"
OUT.mkdir(parents=True, exist_ok=True)
rd = lambda f: (ROOT / f).read_text(encoding="utf-8")


def skills():
    s06 = rd("06 New Star Wars - Skills.md")
    rows = []
    for m in re.finditer(r"^### \**([A-Z][^(\n*]+?)\s*(?:\(([^)]*)\))?\s*\(?(WS|BS|S|T|I|Ag|Dex|Int|WP|Fel)\)?\s*(basic|advanced)(,\s*grouped)?[^\n]*\n+(.*?)(?=\n### |\Z)", s06, re.M | re.S):
        name = m.group(1).strip() + (" (%s)" % m.group(2) if m.group(2) else "")
        sp = re.search(r"Specialisations?:\s*([^\n]+)", m.group(6))
        spec = sp.group(1).strip() if sp else ""
        if name in ("Melee", "Ranged"):
            spec = re.sub(r"\s*\([^)]*\)", "", spec.split(". ")[0]).replace("\\*", "*")
        rows.append({"skill": name, "characteristic": m.group(3), "type": m.group(4), "grouped": "yes" if m.group(5) else "", "specialisations": spec.rstrip(".")})
    write("skills.csv", rows, ["skill", "characteristic", "type", "grouped", "specialisations"])
    return rows


def talents():
    t7 = rd("07 New Star Wars - Talents (revised).md")
    fs = t7.index("## Force Talents")
    rows = []
    for m in re.finditer(r"^### ([^\n]+)\n\*\*Max:\*\*\s*([^·\n]+?)(?:\s*·\s*\*\*Tests:\*\*\s*([^\n]*))?\s*\n+(.*?)(?=\n### |\n## |\Z)", t7, re.M | re.S):
        rows.append({"talent": m.group(1).strip(), "max": m.group(2).strip(), "tests": (m.group(3) or "").strip(),
                     "section": "Force" if m.start() > fs else "General", "description": re.sub(r"\s+", " ", m.group(4)).strip()})
    write("talents.csv", rows, ["talent", "max", "tests", "section", "description"])
    return rows


def careers():
    t5 = rd("05 New Star Wars - Careers (revised).md")
    cl = lambda s: re.sub(r"`\[[^\]]*\]`", "", s).strip()
    rows, cls = [], ""
    for b in re.split(r"\n(?=## |### )", t5):
        if b.startswith("## "):
            cls = b.split("\n")[0][3:].strip(); continue
        if not b.startswith("### "):
            continue
        name = b.split("\n")[0][4:].strip()
        for m in re.finditer(r"\*\*(\d)\. ([^\n]*?)\s*[—-]\s*([A-Z][a-z]+ \d)\*\*[^\n]*\n+(?:[^*\n][^\n]*\n+)*?\*\*Skills:\*\*([^\n]*)\n+\*\*Talents:\*\*([^\n]*)\n+\*\*Trappings:\*\*([^\n]*)", b):
            rows.append({"class": cls, "career": name, "level": m.group(1), "title": m.group(2).strip(), "status": m.group(3),
                         "skills": cl(m.group(4)), "talents": cl(m.group(5)), "trappings": cl(m.group(6))})
    write("careers.csv", rows, ["class", "career", "level", "title", "status", "skills", "talents", "trappings"])
    return rows


def write(name, rows, fields):
    with open(OUT / name, "w", newline="", encoding="utf-8") as fh:
        w = csv.DictWriter(fh, fieldnames=fields)
        w.writeheader(); w.writerows(rows)


if __name__ == "__main__":
    s, t, c = skills(), talents(), careers()
    print("skills %d, talents %d, career levels %d (%d careers)" % (len(s), len(t), len(c), len({r['career'] for r in c})))
