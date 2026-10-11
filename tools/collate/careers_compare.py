#!/usr/bin/env python3
"""Compare the WFRP 4e careers (from the extracted rulebook text) with the SL100 careers in '05 New Star Wars - Careers.md'.
Copying and comparing only. Career names are matched by name (bracketed parts ignored); skill and talent names are
compared after applying the renames that the SL100 documents themselves state (RENAMES below - edit to taste).

  careers_compare.py -> Source_Text/collation/wfrp_careers.csv      every WFRP career level (class, career, level, status, skills, talents, trappings)
                        Source_Text/collation/sl100_careers.csv     the same for 05
                        Source_Text/collation/careers_compare.md    missing careers, renamed/new careers, per-level differences
WFRP text is copyrighted, so all output stays in Source_Text (outside git).
"""
import csv, re, sys
from collections import OrderedDict, defaultdict
from pathlib import Path

WIKI = Path(__file__).resolve().parent.parent.parent
ROOT = WIKI.parent
SRC = ROOT / "WFRP_Text" / "WFRP4_Rulebook.txt"
F05 = WIKI / "05 New Star Wars - Careers.md"
OUT = ROOT / "Source_Text" / "collation"
RENAMES = {  # WFRP name -> SL100 name, as stated in the SL100 documents (06 Skills and the design summary)
    "heal": "medicine", "trade": "profession", "secret signs": "codes", "pick lock": "slice security system",
    "set trap": "demolitions", "pray": "meditate", "channelling": "use the force", "drive": "pilot", "row": "pilot",
    "sail": "pilot", "animal care": "creature care", "animal training": "creature training", "charm animal": "charm creature",
    "consume alcohol": "consume intoxicant", "read write": "datapad literate", "language magick": "language the force",
}


def key(s):
    s = re.sub(r"\(.*?\)", "", s.lower())
    s = re.sub(r"[^a-z0-9]+", " ", s).strip()
    return RENAMES.get(s, s)


def split_list(s):
    return [x.strip(" .") for x in re.split(r",(?![^()]*\))", s) if x.strip(" .")]


def wfrp():
    lines = SRC.read_text(encoding="utf-8", errors="replace").split("\n")
    rows, cls, career = [], "", ""
    i = 0
    while i < len(lines):
        ln = lines[i]
        h = re.search(r"C\s?l\s?a\s?s\s?s\s+a\s?n\s?d\s+C\s?a\s?r\s?e\s?e\s?r\s?s\s*-\s*(.+?)\s{2,}", ln + "  ")
        if h:
            cls = re.sub(r"\s+", "", h.group(1)).strip()
            cls = re.sub(r"(?<=[a-z])(?=[A-Z])", " ", cls).title()
        a = re.match(r"^\s*(\S.*?)\s+Advance Scheme\s*$", ln)
        if a and len(a.group(1)) < 40:
            career = a.group(1).strip()
        if career and re.match(r"^\s*Career Path\s*$", ln):
            lvl, cur, field = 0, None, None
            j = i + 1
            while j < len(lines) and j < i + 60:
                if "Advance Scheme" in lines[j]:
                    break                                         # next career starts; do not swallow it
                s = lines[j].strip()
                s = re.sub(r"\s{3,}.*$", "", s)                     # drop a second text column if present
                m = re.match(r"^(?:[h✓•]\s+)?(.+?)\s+[—–-]\s+(Brass|Silver|Gold)\s+(\d)", s)
                if m:
                    lvl += 1
                    cur = OrderedDict(source="WFRP", cls=cls, career=career, level=lvl, title=m.group(1).strip(),
                                      status="%s %s" % (m.group(2), m.group(3)), skills="", talents="", trappings="")
                    rows.append(cur); field = None
                elif cur is not None:
                    f = re.match(r"^(Skills|Talents|Trappings):\s*(.*)$", s)
                    if f:
                        field = f.group(1).lower(); cur[field] = f.group(2)
                    elif s and field and not re.match(r"^\d+$", s):
                        cur[field] += " " + s
                    elif not s and field == "trappings":
                        field = None
                        if lvl >= 4:
                            break
                j += 1
            for r in rows[-lvl:] if lvl else []:
                for k in ("skills", "talents", "trappings"):
                    r[k] = re.sub(r"\s+", " ", r[k]).strip()
            career = ""
            i = j if j > i + 1 else i + 1
            continue
        i += 1
    return rows


def sl100():
    rows, cls, career, cur = [], "", "", None
    for ln in F05.read_text(encoding="utf-8", errors="replace").split("\n"):
        s = re.sub(r"&#160;| ", " ", ln).strip()
        plain = re.sub(r"[*_`]", "", s).strip()
        if re.match(r"^#\s", s):
            cls = plain.lstrip("# ").strip()
        elif re.match(r"^##\s", s):
            career = plain.lstrip("# ").strip()
        m = re.match(r"^\*\*(\d)\.\s*(.*?)\s*[—–-]\s*(.*?)\*\*$", s)
        if m and career:
            cur = OrderedDict(source="SL100", cls=cls, career=career, level=int(m.group(1)), title=m.group(2).strip(),
                              status=m.group(3).strip(), skills="", talents="", trappings="")
            rows.append(cur)
            continue
        f = re.match(r"^\*\*(Skills|Talents|Trappings)\s*:?\*\*\s*:?\s*(.*)$", s)
        if f and cur is not None:
            cur[f.group(1).lower()] = re.sub(r"[*_`]", "", f.group(2)).strip()
    return rows


def write(name, rows):
    with open(OUT / name, "w", newline="", encoding="utf-8") as fh:
        w = csv.DictWriter(fh, fieldnames=list(rows[0]))
        w.writeheader(); w.writerows(rows)


def by_career(rows):
    d = OrderedDict()
    for r in rows:
        d.setdefault(r["career"], []).append(r)
    return d


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    W, S = wfrp(), sl100()
    write("wfrp_careers.csv", W); write("sl100_careers.csv", S)
    wc, sc = by_career(W), by_career(S)
    wk = {key(c): c for c in wc}
    sk = {key(c): c for c in sc}
    both = [k for k in sk if k in wk]
    md = ["# WFRP 4e careers compared with SL100 careers (05)", "",
          "Generated by `tools/collate/careers_compare.py`. Careers are matched by name only (bracketed parts ignored); "
          "a career that was renamed in SL100 will appear in both 'not in SL100' and 'SL100 only' - pair them up by hand. "
          "Skill and talent names are compared after the renames the SL100 documents state (Heal->Medicine, Trade->Profession, "
          "Secret Signs->Codes, Drive/Row/Sail->Pilot, Consume Alcohol->Consume Intoxicant, Read/Write->Datapad Literate, ...).", "",
          "| | count |", "|---|---|",
          "| WFRP careers found in the rulebook text | %d (%d levels) |" % (len(wc), len(W)),
          "| SL100 careers in 05 | %d (%d levels) |" % (len(sc), len(S)),
          "| same name in both | %d |" % len(both), ""]
    cls_w = defaultdict(list)
    for c, rs in wc.items():
        cls_w[rs[0]["cls"]].append(c)
    md += ["## WFRP careers by class, and whether SL100 has a career of the same name", ""]
    for cl, cs in cls_w.items():
        md.append("- **%s**: %s" % (cl or "(class not read)", ", ".join(("%s ✔" % c) if key(c) in sk else c for c in cs)))
    md += ["", "## WFRP careers with no SL100 career of the same name (%d)" % len([k for k in wk if k not in sk]), ""]
    md += ["- %s (%s): levels %s" % (wk[k], wc[wk[k]][0]["cls"], "; ".join("%s (%s)" % (r["title"], r["status"]) for r in wc[wk[k]])) for k in wk if k not in sk]
    md += ["", "## SL100 careers with no WFRP career of the same name (%d)" % len([k for k in sk if k not in wk]), ""]
    md += ["- %s (%s): levels %s" % (sk[k], sc[sk[k]][0]["cls"], "; ".join("%s (%s)" % (r["title"], r["status"]) for r in sc[sk[k]])) for k in sk if k not in wk]
    md += ["", "## Same-name careers, level by level", "",
           "Per level: skills and talents only in WFRP (dropped or renamed in SL100) and only in SL100 (added). Status and trappings shown as written.", ""]
    for k in both:
        wrs, srs = wc[wk[k]], sc[sk[k]]
        md.append("### %s  (WFRP %s / SL100 %s)" % (sk[k], wrs[0]["cls"], srs[0]["cls"]))
        md.append("")
        for n in range(1, max(len(wrs), len(srs)) + 1):
            w = next((r for r in wrs if r["level"] == n), None)
            s = next((r for r in srs if r["level"] == n), None)
            if not w or not s:
                md.append("- Level %d: only in %s" % (n, "SL100" if s else "WFRP")); continue
            line = ["- **Level %d** WFRP *%s* (%s) / SL100 *%s* (%s)" % (n, w["title"], w["status"], s["title"], s["status"])]
            for f in ("skills", "talents"):
                a = {key(x): x for x in split_list(w[f])}
                b = {key(x): x for x in split_list(s[f])}
                gone = [a[x] for x in a if x not in b]
                new = [b[x] for x in b if x not in a]
                if gone or new:
                    line.append("  - %s: WFRP only: %s | SL100 only: %s" % (f, ", ".join(gone) or "-", ", ".join(new) or "-"))
                else:
                    line.append("  - %s: same (%d)" % (f, len(a)))
            line.append("  - trappings: WFRP: %s | SL100: %s" % (w["trappings"] or "-", s["trappings"] or "-"))
            md += line
        md.append("")
    short = [c for c, rs in wc.items() if len(rs) != 4]
    md += ["## WFRP careers where the text extraction did not find 4 levels (check the rulebook by hand)", "",
           ", ".join("%s (%d)" % (c, len(wc[c])) for c in short) or "none", ""]
    md += ["## SL100 career levels where a field is empty", ""]
    md += ["- %s %d %s: no %s" % (r["career"], r["level"], r["title"], f) for r in S for f in ("skills", "talents", "trappings") if not r[f]]
    (OUT / "careers_compare.md").write_text("\n".join(md) + "\n", encoding="utf-8")
    print("\n".join(md[:12]))


if __name__ == "__main__":
    main()
