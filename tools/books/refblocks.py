#!/usr/bin/env python3
"""Pull reference blocks out of the extracted d20 books: species traits, Force skills and Force feats.
Raw text as printed (OCR slips included), with book and page, for use as reference when filling gaps in the SL100 pages.

  refblocks.py [species|force|all]   ->  Source_Text/tables/d20_species.csv, d20_force_skills.csv, d20_force_feats.csv
                                         + Source_Text/reference/species/<Name>.txt, force/<Name>.txt (full entries)
Copyrighted book text: everything stays in Source_Text (outside git).
"""
import csv, os, re, sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent.parent.parent
TEXT = Path(os.environ.get("SL100_TEXT_DIR", ROOT / "Source_Text"))
OUT, REF = TEXT / "tables", TEXT / "reference"
BULLET = r"[@®©•●*Bb8e]?"
ITEM = re.compile(r"^\s*%s\s*([A-Z][A-Za-z'’\-/ ()]{2,45}?):\s*(.*)$" % BULLET)
ABIL = r"(Strength|Dexterity|Constitution|Intelligence|Wisdom|Charisma|Str|Dex|Con|Int|Wis|Cha)"


def books():
    for d in sorted(TEXT.glob("SW_*")):
        f = d / (d.name + ".raw.txt")          # reading-order text, made for two-column books whose -layout text interleaves
        if not f.exists():
            f = d / (d.name + ".txt")
        if f.exists():
            yield d.name, f


def lines_with_pages(f):
    page, out = 0, []
    for ln in f.read_text(encoding="utf-8", errors="replace").split("\n"):
        m = re.match(r"^=== Page (\d+) ===", ln)
        if m:
            page = int(m.group(1)); continue
        out.append((page, ln.rstrip()))
    return out


def clean_name(s):
    s = re.sub(r"[^A-Za-z0-9'’\- ()]", "", s).strip(" -")
    return re.sub(r"\s+", " ", s)


def safe(s):
    return re.sub(r"[^A-Za-z0-9_\-]+", "_", s).strip("_")[:80] or "unnamed"


# ------------------------------------------------------------------ species
SP_CONTEXT = ("Homeworld", "Homeworlds", "Language", "Languages", "Example Names", "Age in Years", "Personality", "Physical Description",
              "Relations", "Adventurers", "Society", "Description", "Commoner")


def species():
    rows = []
    for slug, f in books():
        L = lines_with_pages(f)
        heads = [i for i, (_, ln) in enumerate(L) if re.search(r"Species Traits\s*$", ln.strip()) and len(ln.strip()) < 60]
        for n, i in enumerate(heads):
            page, ln = L[i]
            name = clean_name(re.sub(r"Species Traits\s*$", "", ln.strip()))
            if not name or name.lower() in ("the", "all"):
                # name from a nearby short heading line above
                for j in range(i - 1, max(-1, i - 220), -1):
                    s = L[j][1].strip()
                    prev = L[j - 1][1].strip() if j else ""
                    if (s and len(s) < 40 and len(s.split()) <= 4 and ":" not in s and not s.endswith((".", ",")) and s[:1].isupper()
                            and not prev and not re.match(r"^(Species Traits|CR|Size|Init)", s)):
                        name = clean_name(s); break
            # trait items after the heading
            items, cur, blank, end = [], None, False, i + 1
            for j in range(i + 1, min(len(L), i + 160)):
                s = L[j][1].strip()
                if not s:
                    blank = True; continue
                if heads and n + 1 < len(heads) and j >= heads[n + 1]:
                    break
                m = ITEM.match(s)
                if m and "Commoner" in m.group(1):
                    break
                if m:
                    cur = [m.group(1).strip(), m.group(2).strip()]; items.append(cur); blank = False; end = j; continue
                b = re.match(r"^[@®©•●]\s*(.+)$", s)
                if b:
                    cur = ["", b.group(1).strip()]; items.append(cur); blank = False; end = j; continue
                if cur and (not blank or s[:1].islower()):
                    cur[1] += " " + s; blank = False; end = j; continue
                if blank and cur:
                    break
            # context paragraphs before the heading (back to previous species' end or 120 lines)
            ctx, start = {}, max(0, i - 120)
            if n and heads[n - 1] < i:
                start = max(start, heads[n - 1] + 1)
            cur = None
            for j in range(start, i):
                s = L[j][1].strip()
                m = re.match(r"^(%s):\s*(.*)$" % "|".join(SP_CONTEXT), s)
                if m:
                    cur = m.group(1); ctx[cur] = m.group(2); continue
                if cur and s:
                    ctx[cur] += " " + s
                elif not s:
                    cur = None
            d = {k.lower(): v for k, v in items if k}
            alltxt = " ".join("%s %s" % (k, v) for k, v in items)
            mm = re.findall(r"([+\-−]\s?\d+)\s+%s\b" % ABIL, alltxt)
            sp = re.search(r"speed (?:is )?(\d+) ?m", alltxt, re.I)
            other = [k for k, _ in items if k and k.lower() not in ("ability modifiers", "ability adjustments", "speed", "skill bonuses", "free language skills",
                                                               "automatic languages", "bonus feats", "bonus feat", "level adjustment")]
            size = next((k for k, _ in items if re.match(r"(Fine|Diminutive|Tiny|Small|Medium|Large|Huge|Gargantuan)", k)), "")
            mods = d.get("ability modifiers") or d.get("ability adjustments") or ", ".join("%s %s" % (a.replace(" ", ""), b) for a, b in mm)
            rows.append({"book": slug, "page": page, "species": name, "ability_modifiers": mods, "size": size,
                         "speed": (sp.group(1) + " m") if sp else d.get("speed", ""), "kind": "creature" if ("Adversaries" in slug and not mm) else "species", "skill_bonuses": d.get("skill bonuses", ""),
                         "languages": d.get("free language skills", d.get("automatic languages", "")),
                         "bonus_feats": d.get("bonus feats", d.get("bonus feat", "")),
                         "other_traits": "; ".join(k for k in other if k != size),
                         "homeworld": ctx.get("Homeworld", ctx.get("Homeworlds", ""))[:300], "language_note": ctx.get("Language", "")[:200],
                         "age": ctx.get("Age in Years", "")[:200],
                         "traits_text": " | ".join("%s: %s" % (k, v) for k, v in items)})
            body = "\n".join(L[k][1] for k in range(start, end + 1))
            p = REF / "species" / ("%s__%s_p%d.txt" % (safe(name), slug[3:40], page))
            p.parent.mkdir(parents=True, exist_ok=True)
            p.write_text(body + "\n", encoding="utf-8")
    write("d20_species", rows)
    return rows


# ------------------------------------------------------------------ Force skills and feats
FS_HEAD = re.compile(r"^([A-Za-z][A-Za-z'’ \-]{2,30}?)\s*[(\[]([A-Za-z][a-z]{2})[^)\]]{0,30}[)\]]\s*[*†]?\s*$")
FEAT_HEAD = re.compile(r"^([A-Z][A-Za-z'’ \-]{2,40}?)\s*(?:\((?:Force|Dark Side|Light Side) Feat\)|\[(?:Force|Dark Side|Light Side)\])\s*$")


def entries(L, starts, maxlen=90):
    for n, (i, m) in enumerate(starts):
        end = starts[n + 1][0] if n + 1 < len(starts) else min(len(L), i + maxlen)
        end = min(end, i + maxlen)
        # stop early at a chapter-like break (3+ blank lines)
        blanks = 0
        for j in range(i + 1, end):
            blanks = blanks + 1 if not L[j][1].strip() else 0
            if blanks >= 4:
                end = j; break
        yield i, m, "\n".join(L[k][1] for k in range(i, end)).strip()


def field(text, label):
    m = re.search(r"(?:^|\n)\s*%s\s*:\s*(.*?)(?=\n\s*\n|\n\s*[A-Z][A-Za-z ]{2,25}:|\Z)" % label, text, re.S)
    return re.sub(r"\s+", " ", m.group(1)).strip() if m else ""


def force():
    skills, feats = [], []
    for slug, f in books():
        L = lines_with_pages(f)
        st = []
        for i, (_, ln) in enumerate(L):
            m = FS_HEAD.match(ln.strip())
            if m and any(re.search(r"Force Skill|^(Light|Dark) Side;|Requires the Force-Sensitive", L[k][1].strip())
                         for k in range(i + 1, min(len(L), i + 7))):
                st.append((i, m))
        for i, m, body in entries(L, st):
            name = clean_name(m.group(1))
            req = next((L[k][1].strip() for k in range(i + 1, min(len(L), i + 7))
                        if re.search(r"Force Skill|^(Light|Dark) Side;|Requires the Force", L[k][1].strip())), "")
            skills.append({"book": slug, "page": L[i][0], "force_skill": name, "key_ability": m.group(2), "requirements": req,
                           "vitality_cost": field(body, "Vitality Point Cost"), "dark_side": "yes" if re.search(r"Dark Side Point", body) else "",
                           "check": field(body, "Check")[:400], "time": field(body, "Time")[:200], "special": field(body, "Special")[:300]})
            p = REF / "force" / ("skill__%s__%s_p%d.txt" % (safe(name), slug[3:40], L[i][0]))
            p.parent.mkdir(parents=True, exist_ok=True); p.write_text(body + "\n", encoding="utf-8")
        st = [(i, FEAT_HEAD.match(ln.strip())) for i, (_, ln) in enumerate(L) if FEAT_HEAD.match(ln.strip())]
        seen = {i for i, _ in st}
        for i, (_, ln) in enumerate(L):         # unlabeled feats whose prerequisites name a Force feat (e.g. Power of the Jedi)
            t = ln.strip()
            if i in seen or not t or len(t) > 40 or len(t.split()) > 5 or ":" in t or t.endswith((".", ",")) or not t[:1].isupper():
                continue
            for k in range(i + 1, min(len(L), i + 9)):
                pm = re.match(r"^Prerequisites?:\s*(.*)$", L[k][1].strip())
                if pm:
                    pre = pm.group(1) + " " + L[k + 1][1] if k + 1 < len(L) else pm.group(1)
                    if re.search(r"Force-Sensitive|\bAlter\b|\bControl\b|\bSense\b|Force level|Force Point", pre):
                        st.append((i, re.match(r"^(.*)$", t)))
                    break
                if re.match(r"^[A-Z][A-Za-z ]{2,25}:", L[k][1].strip()):
                    break
        st.sort(key=lambda x: x[0])
        for i, m, body in entries(L, st, 40):
            name = clean_name(m.group(1))
            feats.append({"book": slug, "page": L[i][0], "force_feat": name,
                          "kind": (re.search(r"(Force|Dark Side|Light Side)", L[i][1]) or re.search("()", "")).group(1) or "Force (by prerequisite)",
                          "prerequisite": field(body, "Prerequisites?"), "benefit": field(body, "Benefit")[:500],
                          "normal": field(body, "N[ao]rmal")[:200], "special": field(body, "Special")[:300]})
            p = REF / "force" / ("feat__%s__%s_p%d.txt" % (safe(name), slug[3:40], L[i][0]))
            p.parent.mkdir(parents=True, exist_ok=True); p.write_text(body + "\n", encoding="utf-8")
    write("d20_force_skills", skills); write("d20_force_feats", feats)
    return skills, feats


def write(name, rows):
    OUT.mkdir(parents=True, exist_ok=True)
    if not rows:
        print(name, 0); return
    with open(OUT / (name + ".csv"), "w", newline="", encoding="utf-8") as fh:
        w = csv.DictWriter(fh, fieldnames=list(rows[0]))
        w.writeheader(); w.writerows(rows)
    print("%-18s %4d rows" % (name, len(rows)))


if __name__ == "__main__":
    what = sys.argv[1] if len(sys.argv) > 1 else "all"
    if what in ("species", "all"):
        species()
    if what in ("force", "all"):
        force()
