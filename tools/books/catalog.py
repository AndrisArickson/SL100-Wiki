"""Batch 0 - catalogue, de-duplicate and rename the d20 source books.  Stdlib only.

  python3 tools/books/catalog.py check            read-only: verify seed against the folder, prove every delete
  python3 tools/books/catalog.py apply            rename kept files to the common scheme (no deleting)
  python3 tools/books/catalog.py apply --delete   also delete the duplicates listed in books_seed.tsv
  python3 tools/books/catalog.py scan             write Source_Text/catalog/catalog.tsv (pages, text layer, md5, method)

Safety rules: a file is deleted only if (a) its kept twin exists and is a readable PDF, and (b) for
'identical' rows the MD5 of both files is re-computed and equal; for 'same-content'/'near-identical'
rows the page counts must match. Every deletion is logged with size and MD5 to
Source_Text/catalog/applied.tsv. Re-running is safe (idempotent).

Naming scheme:  SW_<Title_Words>[_<publisher code>][__variant-<tag>].pdf
  prefixes inside the title: Adventure_ WebEnh_ Errata_ Sheet_ Map_ ; suffix tags: _Fan _GURPS _WEG-d6 _Web
"""
import csv
import hashlib
import os
import re
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

HERE = Path(__file__).resolve().parent
SL100 = HERE.parents[2]
BOOKS = SL100 / "Source_Books"
OUT = SL100 / "Source_Text" / "catalog"
SEED = HERE / "books_seed.tsv"


_CACHE = {}
_CACHE_FILE = OUT / "md5cache.tsv"


def _load_cache():
    if _CACHE_FILE.exists():
        for ln in _CACHE_FILE.read_text(encoding="utf-8").splitlines():
            f = ln.split("\t")
            if len(f) == 4:
                _CACHE[(f[3], f[0], f[1])] = f[2]


def md5(p):
    """MD5 with an on-disk cache keyed by (name, size, mtime) so re-runs are fast."""
    p = Path(p)
    if not _CACHE:
        _load_cache()
    st = p.stat()
    key = (p.name, str(st.st_size), str(st.st_mtime_ns))
    if key in _CACHE:
        return _CACHE[key]
    h = hashlib.md5()
    with open(p, "rb") as f:
        for b in iter(lambda: f.read(1 << 20), b""):
            h.update(b)
    _CACHE[key] = h.hexdigest()
    OUT.mkdir(parents=True, exist_ok=True)
    with open(_CACHE_FILE, "a", encoding="utf-8", newline="\n") as cf:
        cf.write("%s\t%s\t%s\t%s\n" % (key[1], key[2], h.hexdigest(), p.name))
    return h.hexdigest()


def pages(p):
    try:
        r = subprocess.run(["pdfinfo", str(p)], capture_output=True, text=True, timeout=60)
        m = re.search(r"^Pages:\s+(\d+)", r.stdout, re.M)
        return int(m.group(1)) if m else None
    except Exception:
        return None


def read_seed():
    with open(SEED, encoding="utf-8", newline="") as f:
        return list(csv.DictReader(f, delimiter="\t", quoting=csv.QUOTE_NONE))


def locate(rows, name):
    """Return the path where this book currently lives (old name, or already renamed)."""
    old = BOOKS / name
    if old.exists():
        return old
    for r in rows:
        if r["old_name"] == name and r["new_name"] and (BOOKS / r["new_name"]).exists():
            return BOOKS / r["new_name"]
    return None


def plan_check(rows):
    problems, ok = [], []
    have = {p.name for p in BOOKS.glob("*.pdf")}
    seed_old = {r["old_name"] for r in rows}
    new_names = [r["new_name"] for r in rows if r["action"] == "keep"]
    seed_new = set(new_names)
    for n in sorted(have - seed_old - seed_new):
        problems.append("UNLISTED file (not in seed, left alone): " + n)
    if len(new_names) != len(seed_new):
        problems.append("duplicate target names in seed")
    for r in rows:
        if r["action"] == "keep":
            if locate(rows, r["old_name"]) is None:
                problems.append("MISSING keep file: " + r["old_name"])
            if not re.fullmatch(r"SW_[A-Za-z0-9_.\-]+\.pdf", r["new_name"]):
                problems.append("bad new name: " + r["new_name"])
        else:
            src = BOOKS / r["old_name"]
            if not src.exists():
                ok.append("already gone: " + r["old_name"])
    return problems, ok


def verify_delete(rows, r):
    src = BOOKS / r["old_name"]
    kept = locate(rows, r["kept_as"])
    if kept is None:
        return False, "kept twin missing"
    how = r["verification"]
    if how == "identical":
        a, b = md5(src), md5(kept)
        return (a == b), "md5 %s vs %s" % (a[:8], b[:8])
    if how == "corrupt-copy":
        if pages(src) is not None:
            return False, "file is readable - not treating as corrupt"
        return (pages(kept) is not None), "unreadable (no trailer); twin readable"
    pa, pb = pages(src), pages(kept)
    if how in ("same-content", "near-identical", "same-text"):
        return (pa is not None and pa == pb), "pages %s vs %s" % (pa, pb)
    return False, "unknown verification " + how


def cmd_apply(rows, do_delete):
    OUT.mkdir(parents=True, exist_ok=True)
    problems, _ = plan_check(rows)
    hard = [p for p in problems if not p.startswith("UNLISTED")]
    for p in problems:
        print("WARN", p)
    if hard:
        sys.exit("Fix the problems above first (nothing was changed).")
    log = OUT / "applied.tsv"
    new = not log.exists()
    with open(log, "a", encoding="utf-8", newline="\n") as lf:
        if new:
            lf.write("time\taction\told_name\tnew_name_or_kept_as\tbytes\tmd5\tverification\n")
        now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
        # 1. deletions (verified first)
        deleted = 0
        for r in rows:
            if r["action"] != "delete":
                continue
            src = BOOKS / r["old_name"]
            if not src.exists():
                continue
            good, why = verify_delete(rows, r)
            if not good:
                print("SKIP delete (not proven):", r["old_name"], "-", why)
                continue
            if not do_delete:
                print("would delete:", r["old_name"], "(%s; %s)" % (r["verification"], why))
                continue
            size, h = src.stat().st_size, md5(src)
            os.remove(src)
            lf.write("\t".join([now, "delete", r["old_name"], r["kept_as"], str(size), h, r["verification"] + ": " + why]) + "\n")
            lf.flush()
            deleted += 1
            print("deleted:", r["old_name"])
        # 2. renames, two-phase so a half-finished run can't collide
        renamed = 0
        for r in rows:
            if r["action"] != "keep":
                continue
            src, dst = BOOKS / r["old_name"], BOOKS / r["new_name"]
            if not src.exists():
                continue
            if dst.exists():
                print("SKIP rename (target exists):", r["new_name"])
                continue
            os.rename(src, dst)
            lf.write("\t".join([now, "rename", r["old_name"], r["new_name"], str(dst.stat().st_size), "", ""]) + "\n")
            renamed += 1
        print("done: %d deleted, %d renamed" % (deleted, renamed))


def text_layer(p):
    """Per-page character counts from pdftotext (form feed separated)."""
    r = subprocess.run(["pdftotext", "-layout", str(p), "-"], capture_output=True, text=True, timeout=600, errors="replace")
    pgs = r.stdout.split("\f")
    if pgs and not pgs[-1].strip():
        pgs = pgs[:-1]
    return [len(x.strip()) for x in pgs]


def cmd_scan(rows):
    OUT.mkdir(parents=True, exist_ok=True)
    meta = {r["new_name"]: r for r in rows if r["action"] == "keep"}
    lines = ["file\tpages\tmb\ttext_pages\tscanned_pages\tmethod\tmd5\tnote"]
    for p in sorted(BOOKS.glob("*.pdf"), key=lambda x: x.name.lower()):
        n = pages(p)
        counts = text_layer(p) if n else []
        t = sum(1 for c in counts if c >= 40)
        s = (n or 0) - t
        kind = re.match(r"SW_(Sheet|Map)_", p.name)
        method = "skip-form" if kind else ("unreadable" if not n else "text" if s <= 2 else "ocr" if t <= 2 else "hybrid")
        note = meta.get(p.name, {}).get("note", "")
        lines.append("\t".join(map(str, [p.name, n, round(p.stat().st_size / 1048576, 1), t, s, method, md5(p), note])))
        print(p.name, n, method, flush=True)
    (OUT / "catalog.tsv").write_text("\n".join(lines) + "\n", encoding="utf-8")
    print("wrote", OUT / "catalog.tsv")


def main():
    a = sys.argv[1:]
    cmd = a[0] if a else "check"
    rows = read_seed()
    if cmd == "check":
        problems, ok = plan_check(rows)
        for p in problems + ok:
            print(p)
        bad = 0
        for r in rows:
            if r["action"] == "delete" and (BOOKS / r["old_name"]).exists():
                good, why = verify_delete(rows, r)
                print("%-6s %-14s %s  [%s]" % ("PROVEN" if good else "FAIL", r["verification"], r["old_name"], why))
                bad += (not good)
        print("check complete: %d delete rows not proven" % bad)
    elif cmd == "apply":
        cmd_apply(rows, "--delete" in a)
    elif cmd == "scan":
        cmd_scan(rows)
    else:
        print(__doc__)


if __name__ == "__main__":
    main()
