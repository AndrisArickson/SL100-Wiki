#!/usr/bin/env python3
"""Cross-chapter consistency check: skills and talents referenced vs defined. Writes docs/rules-review/consistency-report.md data."""
import re, pathlib, collections, json
ROOT = pathlib.Path(__file__).resolve().parents[2]
rd = lambda f: (ROOT / f).read_text(encoding="utf-8")
def base(s):
    s = re.sub(r"`\[[^\]]*\]`", "", s).strip().strip("*").strip()
    m = re.match(r"([^(]+?)\s*\((.*)\)\s*$", s)
    return (m.group(1).strip(), m.group(2).strip()) if m else (s, "")
def split_list(s):
    s = re.sub(r"`\[[^\]]*\]`", "", s)
    items, buf = [], ""
    for p in s.split(","):
        buf = (buf + "," + p) if buf else p
        if buf.count("(") == buf.count(")"):
            items.append(buf.strip().strip("*").strip()); buf = ""
    if buf.strip(): items.append(buf.strip())
    return [i.strip(" .") for i in items if i.strip(" .")]

# --- defined skills (06)
s06 = rd("06 New Star Wars - Skills.md")
skills_def = {}
for m in re.finditer(r"^### \**([A-Z][^(\n*]+?)\s*(?:\(([^)]*)\))?\s*\(?(WS|BS|S|T|I|Ag|Dex|Int|WP|Fel)\)?\s*(basic|advanced)[^\n]*", s06, re.M):
    skills_def[m.group(1).strip()] = (m.group(3), m.group(4))
# pilot specialisations are separate headings
for k in list(skills_def):
    pass
specs = {}
for m in re.finditer(r"^### \**([A-Z][^(\n*]+?)\s*\([^\n]*?grouped\**\s*\n+(.*?)(?=\n### )", s06, re.M | re.S):
    sp = re.search(r"Specialisations?:\s*([^\n]+)", m.group(2))
    if sp: specs[m.group(1).strip()] = sp.group(1)
# --- defined talents (07)
t07 = rd("07 New Star Wars - Talents (revised).md")
talents_def = set(re.sub(r"\s*\(.*", "", m.group(1)).strip() for m in re.finditer(r"^### ([^\n]+)", t07, re.M))
talents_full = [m.group(1).strip() for m in re.finditer(r"^### ([^\n]+)", t07, re.M)]
tl = rd("Talent List (revised).md")
talent_list = set(re.sub(r"\s*\(.*", "", m.group(1)).strip() for m in re.finditer(r"^\|?\s*\*{0,2}([A-Z][A-Za-z'’!\- ]+?)\*{0,2}\s*(?:\(|\|)", tl, re.M))

# --- references
refs_sk, refs_tl = collections.defaultdict(set), collections.defaultdict(set)
def harvest(fname, tag, skill_pat, talent_pat):
    t = rd(fname)
    for m in re.finditer(skill_pat, t, re.M):
        for s in split_list(m.group(1)):
            refs_sk[s].add(tag)
    for m in re.finditer(talent_pat, t, re.M):
        for s in split_list(m.group(1)):
            refs_tl[s].add(tag)
harvest("05 New Star Wars - Careers (revised).md", "05", r"^\*\*Skills:\*\*([^\n]*)", r"^\*\*Talents:\*\*([^\n]*)")
harvest("03 New Star Wars - Origin.md", "03", r"^\*\*Starting Skills:\*\*([^\n]*)", r"^\*\*(?:Starting )?Talents:\*\*([^\n]*)")
harvest("02 New Star Wars - Species (revised).md", "02", r"^\*\*Skills:\*\*([^\n]*)", r"^\*\*Talents:\*\*([^\n]*)")
# talents' Tests lines
for m in re.finditer(r"\*\*Tests:\*\*([^\n]*)", t07):
    for s in split_list(m.group(1).split("·")[0]):
        if re.match(r"[A-Z]", s): refs_sk[s].add("07")

def known_skill(name):
    b, sp = base(name)
    b = b.replace("Any one", "").strip()
    if b in skills_def: return True
    if b == "Pilot" and sp in ("Speeder", "Starship", "Capital Ship"): return True
    return False
noise = re.compile(r"^(any|roll|none|or|and|\d|no )", re.I)
unknown_sk = sorted((k, sorted(v)) for k, v in refs_sk.items() if not known_skill(k) and not noise.match(k) and len(k) < 60)
unknown_tl = sorted((k, sorted(v)) for k, v in refs_tl.items() if base(k)[0] not in talents_def and not noise.match(k) and len(k) < 60)
spec_use = collections.defaultdict(collections.Counter)
for k, v in refs_sk.items():
    b, sp = base(k)
    if sp and b in skills_def: spec_use[b][sp] += 1
out = {"skills_defined": sorted(skills_def), "specialisations_defined": specs, "unknown_skills": unknown_sk,
       "unknown_talents": unknown_tl, "spec_use": {k: dict(v) for k, v in spec_use.items()},
       "talents_defined": len(talents_full), "talent_list_count": len(talent_list),
       "in_07_not_list": sorted(talents_def - talent_list), "in_list_not_07": sorted(talent_list - talents_def)}
(ROOT / "docs" / "rules-review" / "consistency-data.json").write_text(json.dumps(out, indent=1, ensure_ascii=False), encoding="utf-8")
print("skills defined", len(skills_def)); print("UNKNOWN SKILLS"); [print("  ", k, v) for k, v in unknown_sk]
print("UNKNOWN TALENTS"); [print("  ", k, v) for k, v in unknown_tl]
print("07 not in list:", out["in_07_not_list"]); print("list not in 07:", out["in_list_not_07"])
for b in ("Lore", "Language", "Codes", "Profession", "Entertain", "Ride", "Creature Training", "Stealth", "Art", "Perform", "Play", "Melee", "Ranged"):
    print(b, ":", sorted(spec_use.get(b, {})))
