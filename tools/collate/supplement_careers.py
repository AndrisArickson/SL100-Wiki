"""Extract careers and talents from the WFRP 4e supplement text files.   python3 tools/collate/supplement_careers.py

Reads ../WFRP_Text/WFRP4_*.txt (not the core rulebook) and writes to ../Source_Text/collation/:
  wfrp_supplement_careers.csv   book, career, level, title, status, skills, talents, trappings, l1 (level-1 characteristics)
  wfrp_supplement_talents.csv   book, name, max, tests, text (first 600 characters)
Copyrighted extracts: Source_Text is never pushed.
"""
import csv
import re
from collections import OrderedDict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
TXT = ROOT.parent / "WFRP_Text"
OUT = ROOT.parent / "Source_Text" / "collation"
BOOKS = {"WFRP4_Up_in_Arms.txt": "Up in Arms", "WFRP4_Sea_of_Claws.txt": "Sea of Claws", "WFRP4_Archives_1.txt": "Archives I",
         "WFRP4_Archives_2.txt": "Archives II", "WFRP4_Archives_3.txt": "Archives III"}
COLS = ["WS", "BS", "S", "T", "I", "Ag", "Dex", "Int", "WP", "Fel"]


def strip_col2(s):
    return re.sub(r"\s{3,}.*$", "", s.strip())


def careers(lines, book):
    rows = []
    i = 0
    while i < len(lines):
        a = re.match(r"^\s*(\S.*?)\s+ADVANCE SCHEME\s*$", lines[i], re.I)
        if not a or len(a.group(1)) > 45:
            i += 1
            continue
        career = a.group(1).strip().title().replace("Of ", "of ").replace("The ", "the ")
        # level-1 trio: the header row and the glyph row that follow
        l1 = []
        for j in range(i + 1, min(i + 8, len(lines))):
            hdr = lines[j]
            if re.search(r"\bWS\b.*\bFel\b", hdr):
                pos = [m.start() + len(m.group()) / 2 for m in re.finditer(r"WS|BS|\bS\b|\bT\b|\bI\b|Agi?|Dex|Int|WP|Fel", hdr)]
                row = lines[j + 1] if j + 1 < len(lines) else ""
                for m in re.finditer(r"[^\s0-9|]", row):
                    if pos:
                        c = min(range(len(pos)), key=lambda k: abs(pos[k] - m.start() - 0.5))
                        l1.append(COLS[c])
                break
        lvl, cur, field = 0, None, None
        j = i + 1
        while j < len(lines) and j < i + 90:
            if j > i + 1 and re.search(r"ADVANCE SCHEME", lines[j], re.I):
                break
            s = strip_col2(lines[j])
            m = re.match(r"^(?:[^\w\s]\s*)?(.+?)\s+[—–-]\s+(Brass|Silver|Gold)\s+(\d)", s)
            if m and lvl < 4:
                lvl += 1
                cur = OrderedDict(book=book, career=career, level=lvl, title=m.group(1).strip(), status="%s %s" % (m.group(2), m.group(3)),
                                  skills="", talents="", trappings="", l1=", ".join(l1[:3]))
                rows.append(cur)
                field = None
            elif cur is not None:
                f = re.match(r"^(Skills|Talents|Trappings):\s*(.*)$", s)
                if f:
                    field = f.group(1).lower()
                    cur[field] = f.group(2)
                elif s and field and not re.match(r"^\d+$", s) and not re.match(r"^[A-Z ]{6,}$", s):
                    cur[field] += " " + s
                elif not s and field == "trappings":
                    field = None
                    if lvl >= 4:
                        break
            j += 1
        for r in rows[-lvl:] if lvl else []:
            for k in ("skills", "talents", "trappings"):
                r[k] = re.sub(r"\s+", " ", r[k]).strip().rstrip(",")
        i = j if j > i + 1 else i + 1
    return rows


def columns(lines, split=62):
    """Two-column pages: return the left and the right column as separate line streams."""
    left = [ln[:split].rstrip() for ln in lines]
    right = [ln[split:].rstrip() for ln in lines]
    return left, right


def talents(lines, book):
    out = []
    for stream in columns(lines):
        out += talents_stream(stream, book)
    seen, uniq = set(), []
    for t in out:
        k = (t["name"].lower(), t["max"])
        if t["name"] and k not in seen:
            seen.add(k)
            uniq.append(t)
    return uniq


def talents_stream(lines, book):
    out = []
    for i, ln in enumerate(lines):
        m = re.match(r"^\s*Max:\s*(.+?)\s*$", strip_col2(ln))
        if not m:
            continue
        name = ""
        for k in range(i - 1, max(i - 4, 0), -1):
            c = strip_col2(lines[k])
            if c and len(c) < 50 and not re.search(r"Max:|Tests:", c):
                name = c
                break
        tests = ""
        body = []
        for k in range(i + 1, min(i + 14, len(lines))):
            c = strip_col2(lines[k])
            t = re.match(r"^Tests:\s*(.*)$", c)
            if t:
                tests = t.group(1)
                continue
            if re.match(r"^\s*Max:", lines[k]):
                break
            if c:
                body.append(c)
        out.append(OrderedDict(book=book, name=name, max=m.group(1), tests=tests, text=" ".join(body)[:600]))
    return out


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    allc, allt = [], []
    for fn, book in BOOKS.items():
        p = TXT / fn
        if not p.exists():
            continue
        lines = p.read_text(encoding="utf-8", errors="replace").split("\n")
        c, t = careers(lines, book), talents(lines, book)
        allc += c
        allt += t
        print("%-14s careers %3d levels (%d careers)  talents %d" % (book, len(c), len({x["career"] for x in c}), len(t)))
    for name, rows in (("wfrp_supplement_careers.csv", allc), ("wfrp_supplement_talents.csv", allt)):
        with open(OUT / name, "w", encoding="utf-8", newline="") as f:
            w = csv.DictWriter(f, fieldnames=list(rows[0].keys()) if rows else ["book"])
            w.writeheader()
            w.writerows(rows)


if __name__ == "__main__":
    main()
