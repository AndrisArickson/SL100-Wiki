#!/usr/bin/env python3
"""Write <slug>.raw.txt: the PDF text layer in reading order (pdftotext without -layout), one '=== Page n ===' marker
per page. For two-column books whose -layout text interleaves the columns line by line. Text-layer pages only; pages
that were OCR'd keep their OCR text (tesseract already reads column by column).

  rawtext.py SLUG [SLUG ...]
"""
import json, subprocess, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent.parent.parent
BOOKS, TEXT = ROOT / "Source_Books", ROOT / "Source_Text"


def main(slugs):
    for slug in slugs:
        pdf, d = BOOKS / (slug + ".pdf"), TEXT / slug
        meta = {}
        for line in (d / "meta.jsonl").read_text().splitlines() if (d / "meta.jsonl").exists() else []:
            try:
                m = json.loads(line); meta[int(m.get("page", 0))] = m
            except Exception:
                pass
        n = int(json.loads((d / "book.json").read_text())["pages"])
        out = []
        for p in range(1, n + 1):
            if meta.get(p, {}).get("method") == "ocr":
                t = (d / "pages" / ("%04d.txt" % p)).read_text(encoding="utf-8", errors="replace")
            else:
                t = subprocess.run(["pdftotext", "-f", str(p), "-l", str(p), str(pdf), "-"], capture_output=True,
                                   text=True, errors="replace").stdout
            out.append("=== Page %d ===\n%s" % (p, t.replace("\f", "")))
        (d / (slug + ".raw.txt")).write_text("\n".join(out), encoding="utf-8")
        print(slug, n, "pages")


if __name__ == "__main__":
    main(sys.argv[1:])
