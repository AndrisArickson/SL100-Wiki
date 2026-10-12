#!/usr/bin/env python3
"""Check whether an unextracted variant PDF holds the same text as an already-extracted copy.
OCRs a handful of evenly spaced pages of the variant (into Source_Text/_samples/) and finds, for each, the best-matching
page anywhere in the extracted copy (so page offsets do not matter).
  variant_check.py VARIANT_SLUG EXTRACTED_SLUG [N_PAGES]
"""
import collections, re, sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent))
import extract as X
from multiprocessing import Pool


def words(t):
    return [w for w in re.findall(r"[a-z]{3,}", t.lower())]


def main(var, ext, n=8):
    pdf = X.BOOKS / (var + ".pdf")
    total = X.pdf_pages(pdf)
    pages = [max(1, round(total * (i + 1) / (n + 1))) for i in range(n)]
    cfg = dict(X.book_cfg(var), min_text_chars=40)
    out = X.TEXT / "_samples" / var / "pages"
    (X.TEXT / ".tmp").mkdir(parents=True, exist_ok=True)
    jobs = [(var, str(pdf), p, cfg, str(out / ("%04d.txt" % p))) for p in pages if not (out / ("%04d.txt" % p)).exists()]
    if jobs:
        with Pool(2, initializer=X.init_worker) as pool:
            list(pool.imap(X.work, jobs))
    ref = {}
    for f in sorted((X.TEXT / ext / "pages").glob("*.txt")):
        ref[int(f.stem)] = collections.Counter(words(f.read_text(encoding="utf-8", errors="replace")))
    print("%s (%d pp) vs %s (%d pp)" % (var, total, ext, len(ref)))
    scores = []
    for p in pages:
        c = collections.Counter(words((out / ("%04d.txt" % p)).read_text(encoding="utf-8", errors="replace")))
        if sum(c.values()) < 30:
            print("  variant p%-4d: too little text (%d words) - art/blank page" % (p, sum(c.values()))); continue
        best = max(ref, key=lambda k: sum((c & ref[k]).values()))          # page sharing the most words
        sc = sum((c & ref[best]).values()) / max(1, sum(c.values()))      # share of the variant page found there
        scores.append(sc)
        print("  variant p%-4d -> extracted p%-4d overlap %.2f  (%d vs %d words)" % (p, best, sc, sum(c.values()), sum(ref[best].values())))
    if scores:
        print("  mean overlap %.2f over %d text pages" % (sum(scores) / len(scores), len(scores)))


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2], int(sys.argv[3]) if len(sys.argv) > 3 else 8)
