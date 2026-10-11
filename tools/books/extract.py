#!/usr/bin/env python3
"""Text extraction / OCR of the d20 source books.  Standard library + poppler-utils + tesseract.

  extract.py pilot                          OCR a few pages with several settings, write a report (about 5 min)
  extract.py run --batch N [--workers K] [--limit-pages M]
  extract.py run --book SLUG [...]          one book (slug = file name without .pdf)
  extract.py sample SLUG --pages 20,40      extract only those pages into Source_Text/_samples/
  extract.py compare SLUG_A SLUG_B [--pages 30,60,90]    are two variant files the same book?
  extract.py status                         what is done, speed, ETA
  extract.py qa                             quality report -> Source_Text/qa_report.md
  extract.py batches                        list batches

Per page: pdftotext -layout; if the page has fewer than min_text_chars characters it is rendered with
pdftoppm and OCR'd with tesseract. Resumable (finished pages are skipped), stops cleanly when the file
Source_Text/STOP exists (or on Ctrl-C / kill), runs at low priority, one tesseract thread per worker.

Output (outside the git repo, copyrighted text):
  Source_Text/<slug>/pages/0001.txt ...   one file per page         Source_Text/<slug>/<slug>.txt   all pages joined
  Source_Text/<slug>/meta.jsonl           per-page method/chars/confidence/seconds
  Source_Text/<slug>/<slug>.meta.json     book summary              Source_Text/STATUS.json, PROGRESS.md
"""
import argparse
import collections
import difflib
import json
import os
import random
import re
import shutil
import signal
import subprocess
import sys
import tempfile
import time
from datetime import datetime, timezone
from multiprocessing import Pool
from pathlib import Path

HERE = Path(__file__).resolve().parent
SL100 = HERE.parents[2]
BOOKS = Path(os.environ.get("SL100_BOOKS_DIR", SL100 / "Source_Books"))
TEXT = Path(os.environ.get("SL100_TEXT_DIR", SL100 / "Source_Text"))
IS_TEST = "SL100_TEXT_DIR" in os.environ
CONF = json.loads((HERE / "batches.json").read_text(encoding="utf-8"))
DEFAULT_CFG = {"dpi": 300, "psm": 3, "gray": True, "min_text_chars": 40}
STOP_FILE = TEXT / "STOP"
STOP = False


def now():
    return datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%SZ")


def log(*a):
    print(datetime.now().strftime("%H:%M:%S"), *a, flush=True)


def on_signal(sig, frm):
    global STOP
    STOP = True
    log("Stop requested - finishing in-flight pages, progress is saved.")


def should_stop():
    return STOP or STOP_FILE.exists()


# ------------------------------------------------------------------ tools
def check_tools():
    missing = [t for t in ("pdftotext", "pdfinfo", "pdftoppm", "tesseract") if not shutil.which(t)]
    if missing:
        sys.exit("Missing tools: %s\nInstall poppler-utils and tesseract-ocr (+ English data), e.g.\n"
                 "  sudo apt install poppler-utils tesseract-ocr tesseract-ocr-eng     (Debian/Ubuntu)\n"
                 "  sudo dnf install poppler-utils tesseract                            (Fedora)\n"
                 "  sudo pacman -S poppler tesseract tesseract-data-eng                 (Arch)" % ", ".join(missing))
    out = subprocess.run(["tesseract", "--list-langs"], capture_output=True, text=True).stdout
    if "eng" not in out.split():
        sys.exit("Tesseract has no English language data (eng). Install tesseract-ocr-eng / tesseract-data-eng.")


def pdf_pages(pdf):
    r = subprocess.run(["pdfinfo", str(pdf)], capture_output=True, text=True)
    m = re.search(r"^Pages:\s+(\d+)", r.stdout, re.M)
    if not m:
        raise RuntimeError("cannot read %s" % pdf)
    return int(m.group(1))


def load_settings():
    f = TEXT / "settings.json"
    if f.exists():
        return json.loads(f.read_text(encoding="utf-8"))
    return {"default": dict(DEFAULT_CFG), "books": {}}


def book_cfg(slug, settings=None):
    s = settings or load_settings()
    cfg = dict(DEFAULT_CFG)
    cfg.update(s.get("default", {}))
    cfg.update(s.get("books", {}).get(slug, {}))
    return cfg


# ------------------------------------------------------------ page worker
def tsv_conf(tsv_path):
    tot, n = 0.0, 0
    for ln in Path(tsv_path).read_text(encoding="utf-8", errors="replace").splitlines()[1:]:
        f = ln.split("\t")
        if len(f) >= 12 and f[0] == "5" and f[11].strip():
            try:
                c = float(f[10])
            except ValueError:
                continue
            if c >= 0:
                tot += c
                n += 1
    return round(tot / n, 1) if n else None


def stitch_page(pdf, n, tmp):
    """Pull the page's embedded images, stack them top to bottom, boost contrast, double the size -> tmp/pg.png.
    Needed for the Hero's Guide: rendering the page leaves tinted backgrounds that make Tesseract return nothing."""
    from PIL import Image, ImageOps
    subprocess.run(["pdfimages", "-f", str(n), "-l", str(n), "-all", pdf, tmp + "/im"], check=True, capture_output=True, timeout=300)
    files = sorted(p for p in Path(tmp).glob("im-*") if p.suffix.lower() in (".jpg", ".png", ".jpeg", ".ppm", ".pgm", ".tif"))
    if not files:
        raise RuntimeError("no embedded images on page %d" % n)
    ims = [Image.open(p).convert("L") for p in files]
    w = max(i.width for i in ims)
    canvas = Image.new("L", (w, sum(i.height for i in ims)), 255)
    y = 0
    for i in ims:
        canvas.paste(i, (0, y)); y += i.height
    canvas = ImageOps.autocontrast(canvas, cutoff=2)
    canvas = canvas.resize((canvas.width * 2, canvas.height * 2), Image.LANCZOS)
    canvas.save(tmp + "/pg.png")


def work(job):
    """Extract one page. Returns a small dict; writes the page text file itself."""
    slug, pdf, n, cfg, out = job
    t0 = time.time()
    res = {"slug": slug, "page": n, "method": "text", "chars": 0, "conf": None, "secs": 0.0, "err": None}
    try:
        txt = subprocess.run(["pdftotext", "-layout", "-f", str(n), "-l", str(n), pdf, "-"],
                             capture_output=True, text=True, errors="replace", timeout=120).stdout.replace("\f", "")
        if len(txt.strip()) < cfg["min_text_chars"]:
            res["method"] = "ocr"
            tmp = tempfile.mkdtemp(prefix="p%04d_" % n, dir=str(TEXT / ".tmp"))
            try:
                if cfg.get("stitch"):
                    stitch_page(pdf, n, tmp)       # scans stored as image strips on tinted backgrounds
                else:
                    cmd = ["pdftoppm", "-r", str(cfg["dpi"]), "-f", str(n), "-l", str(n), "-png", "-singlefile"]
                    if cfg.get("gray", True):
                        cmd.insert(1, "-gray")
                    subprocess.run(cmd + [pdf, tmp + "/pg"], check=True, capture_output=True, timeout=300)
                env = dict(os.environ, OMP_THREAD_LIMIT="1")
                subprocess.run(["tesseract", tmp + "/pg.png", tmp + "/o", "--psm", str(cfg["psm"]), "-l", "eng",
                                "-c", "preserve_interword_spaces=1", "txt", "tsv"],
                               capture_output=True, env=env, timeout=600)
                txt = Path(tmp + "/o.txt").read_text(encoding="utf-8", errors="replace").replace("\f", "")
                res["conf"] = tsv_conf(tmp + "/o.tsv")
            finally:
                shutil.rmtree(tmp, ignore_errors=True)
        txt = re.sub(r"\n{3,}", "\n\n", txt).rstrip() + "\n"
        res["chars"] = len(txt.strip())
        Path(out).parent.mkdir(parents=True, exist_ok=True)
        tmpf = Path(str(out) + ".tmp")
        tmpf.write_text(txt, encoding="utf-8", newline="\n")
        os.replace(tmpf, out)
    except Exception as e:  # keep the run going; page will be retried next run
        res["err"] = repr(e)
    res["secs"] = round(time.time() - t0, 1)
    return res


def init_worker():
    signal.signal(signal.SIGINT, signal.SIG_IGN)
    try:
        os.nice(10)
    except Exception:
        pass


# ------------------------------------------------------------- run books
def bookdir(slug, base=None):
    return (base or TEXT) / slug


def pages_done(slug, base=None):
    d = bookdir(slug, base) / "pages"
    return {int(p.stem) for p in d.glob("*.txt")} if d.exists() else set()


def append(path, text):
    path.parent.mkdir(parents=True, exist_ok=True)
    with open(path, "a", encoding="utf-8", newline="\n") as f:
        f.write(text)


def finish_book(slug, n):
    d = bookdir(slug)
    parts = []
    for p in range(1, n + 1):
        f = d / "pages" / ("%04d.txt" % p)
        parts.append("=== Page %d ===\n%s" % (p, f.read_text(encoding="utf-8") if f.exists() else ""))
    (d / (slug + ".txt")).write_text("\n".join(parts), encoding="utf-8", newline="\n")
    summ = summarise(slug)
    summ["pages"] = n
    summ["finished"] = now()
    (d / (slug + ".meta.json")).write_text(json.dumps(summ, indent=1), encoding="utf-8")
    append(TEXT / "PROGRESS.md", "- %s finished %s: %d pages, %s\n" % (now(), slug, n, summ["methods"]))
    return summ


def read_meta(slug, base=None):
    f = bookdir(slug, base) / "meta.jsonl"
    last = {}
    if f.exists():
        for ln in f.read_text(encoding="utf-8").splitlines():
            try:
                r = json.loads(ln)
                last[r["page"]] = r
            except Exception:
                pass
    return last


def summarise(slug):
    m = read_meta(slug)
    meth = collections.Counter(r["method"] for r in m.values())
    confs = [r["conf"] for r in m.values() if r.get("conf") is not None]
    ocr_secs = [r["secs"] for r in m.values() if r["method"] == "ocr"]
    return {"methods": dict(meth),
            "mean_conf": round(sum(confs) / len(confs), 1) if confs else None,
            "low_conf_pages": sorted(p for p, r in m.items() if r.get("conf") is not None and r["conf"] < 70),
            "empty_pages": sorted(p for p, r in m.items() if r["chars"] < 20),
            "secs_per_ocr_page": round(sum(ocr_secs) / len(ocr_secs), 1) if ocr_secs else None}


def write_status(state, batch=None, run=None):
    books = {}
    for d in sorted(TEXT.glob("SW_*")):
        bj = d / "book.json"
        if bj.exists():
            b = json.loads(bj.read_text(encoding="utf-8"))
            b["done"] = len(pages_done(d.name))
            b["complete"] = b["done"] >= b["pages"]
            books[d.name] = b
    st = {"updated": now(), "state": state, "batch": batch, "run": run, "books": books,
          "books_complete": sum(1 for b in books.values() if b["complete"]),
          "pages_done": sum(b["done"] for b in books.values()),
          "dashboard_sync_needed": True}
    (TEXT / "STATUS.json").write_text(json.dumps(st, indent=1), encoding="utf-8")


def lock():
    f = TEXT / "extract.lock"
    if f.exists():
        try:
            os.kill(int(f.read_text().strip()), 0)
            sys.exit("Another extraction is already running (pid %s)." % f.read_text().strip())
        except (ValueError, ProcessLookupError, PermissionError):
            pass
    f.write_text(str(os.getpid()))
    return f


def run_books(slugs, workers, limit, label):
    check_tools()
    (TEXT / ".tmp").mkdir(parents=True, exist_ok=True)
    if STOP_FILE.exists():
        try:
            STOP_FILE.unlink()
        except OSError:
            sys.exit("Cannot remove %s - delete it by hand." % STOP_FILE)
    lk = lock()
    signal.signal(signal.SIGINT, on_signal)
    signal.signal(signal.SIGTERM, on_signal)
    settings = load_settings()
    t0, done_total = time.time(), 0
    append(TEXT / "PROGRESS.md", "- %s started %s (%d books, %d workers)\n" % (now(), label, len(slugs), workers))
    try:
        for slug in slugs:
            if should_stop() or (limit and done_total >= limit):
                break
            pdf = BOOKS / (slug + ".pdf")
            if not pdf.exists():
                log("MISSING", pdf.name)
                continue
            n = pdf_pages(pdf)
            d = bookdir(slug)
            (d / "pages").mkdir(parents=True, exist_ok=True)
            (d / "book.json").write_text(json.dumps({"pdf": pdf.name, "pages": n, "started": now()}), encoding="utf-8")
            cfg = book_cfg(slug, settings)
            todo = [p for p in range(1, n + 1) if p not in pages_done(slug)]
            if limit:
                todo = todo[: max(0, limit - done_total)]
            log("%s: %d pages, %d to do (dpi %s, psm %s)" % (slug, n, len(todo), cfg["dpi"], cfg["psm"]))
            jobs = [(slug, str(pdf), p, cfg, str(d / "pages" / ("%04d.txt" % p))) for p in todo]
            if jobs:
                with Pool(workers, initializer=init_worker) as pool:
                    for r in pool.imap_unordered(work, jobs):
                        if r["err"]:
                            log("page %d error: %s" % (r["page"], r["err"]))
                        else:
                            append(d / "meta.jsonl", json.dumps(r) + "\n")
                            done_total += 1
                        if done_total and done_total % 10 == 0:
                            rate = done_total / (time.time() - t0) * 60
                            left = sum(len(pages_done_missing(s2)) for s2 in slugs)
                            log("%d pages this run, %.1f pages/min, ~%.0f min left in this batch" %
                                (done_total, rate, left / rate if rate else 0))
                            write_status("running", label, {"pages_this_run": done_total, "pages_per_min": round(rate, 1)})
                        if should_stop():
                            pool.terminate()
                            break
            if len(pages_done(slug)) >= n:
                finish_book(slug, n)
                log("%s complete" % slug)
        write_status("stopped" if should_stop() else "idle", label, {"pages_this_run": done_total})
        append(TEXT / "PROGRESS.md", "- %s %s %s: %d pages this run\n" %
               (now(), "stopped" if should_stop() else "finished", label, done_total))
        if not IS_TEST:
            append(SL100 / "PROGRESS_LOG.md", "- %s [auto] extract %s %s: %d pages this run. See Source_Text/STATUS.json; dashboard needs syncing.\n" %
                   (datetime.now().strftime("%Y-%m-%d"), label, "stopped" if should_stop() else "finished", done_total))
    finally:
        try:
            lk.unlink()
        except OSError:
            pass


_NP = {}


def pages_done_missing(slug):
    pdf = BOOKS / (slug + ".pdf")
    if slug not in _NP:
        _NP[slug] = pdf_pages(pdf) if pdf.exists() else 0
    n = _NP[slug]
    return [p for p in range(1, n + 1) if p not in pages_done(slug)]


# ------------------------------------------------------------ sub-commands
def evenly(n, k=5):
    pts = sorted({max(1, min(n, int(n * f))) for f in [0.12, 0.3, 0.5, 0.7, 0.88][:k]})
    return pts


def cmd_pilot(workers):
    check_tools()
    (TEXT / ".tmp").mkdir(parents=True, exist_ok=True)
    settings = {"S1 300dpi psm3 gray": {"dpi": 300, "psm": 3, "gray": True},
                "S2 200dpi psm3 gray": {"dpi": 200, "psm": 3, "gray": True},
                "S3 300dpi psm11 gray": {"dpi": 300, "psm": 11, "gray": True},
                "S4 300dpi psm3 colour": {"dpi": 300, "psm": 3, "gray": False}}
    jobs, root = [], TEXT / "_pilot"
    for slug in CONF["pilot_books"]:
        pdf = BOOKS / (slug + ".pdf")
        if not pdf.exists():
            continue
        for p in evenly(pdf_pages(pdf)):
            for name, c in settings.items():
                cfg = dict(DEFAULT_CFG, min_text_chars=10 ** 9, **c)   # force OCR
                tag = name.split()[0]
                jobs.append(((slug, name), (slug, str(pdf), p, cfg, str(root / slug / ("%s_p%04d.txt" % (tag, p))))))
    stats = collections.defaultdict(list)
    cache = root / "results.jsonl"          # resumable: finished runs are kept here
    done = {}
    if cache.exists():
        for ln in cache.read_text(encoding="utf-8").splitlines():
            try:
                d = json.loads(ln); done[(d["_slug"], d["_name"], d["page"])] = d
            except Exception:
                pass
    todo = []
    for key, j in jobs:
        d = done.get((key[0], key[1], j[2]))
        if d:
            stats[key].append(d)
        else:
            todo.append((key, j))
    log("pilot: %d OCR runs to do (%d already done) with %d workers" % (len(todo), len(jobs) - len(todo), workers))
    root.mkdir(parents=True, exist_ok=True)
    with Pool(workers, initializer=init_worker) as pool:
        for (key, _job), r in zip(todo, pool.imap(work, [j[1] for j in todo])):
            stats[key].append(r)
            if not r["err"]:
                with open(cache, "a", encoding="utf-8") as fh:
                    fh.write(json.dumps(dict(r, _slug=key[0], _name=key[1])) + "\n")
            log("%s | %s | page %d | %.1fs | conf %s | %d chars" % (key[0][-24:], key[1], r["page"], r["secs"], r["conf"], r["chars"]))
    lines = ["# OCR pilot report", "", "Generated %s. Pages sampled evenly through each book; every setting forced to OCR." % now(), "",
             "| Book | Setting | Avg secs/page | Avg confidence | Avg chars/page |", "|---|---|---|---|---|"]
    best = {}
    for (slug, name), rs in stats.items():
        ok = [r for r in rs if not r["err"]]
        if not ok:
            continue
        sec = sum(r["secs"] for r in ok) / len(ok)
        confs = [r["conf"] for r in ok if r["conf"] is not None]
        conf = sum(confs) / len(confs) if confs else 0
        ch = sum(r["chars"] for r in ok) / len(ok)
        lines.append("| %s | %s | %.1f | %.1f | %.0f |" % (slug, name, sec, conf, ch))
        score = ch * conf / 100.0 - sec * 2
        if slug not in best or score > best[slug][0]:
            best[slug] = (score, name)
    rec = {"default": dict(DEFAULT_CFG), "books": {}}
    for slug, (_s, name) in best.items():
        rec["books"][slug] = dict(settings[name])
    lines += ["", "## Suggested per-book settings (written to settings.json)", ""]
    lines += ["- %s: %s" % (s, n) for s, (_x, n) in best.items()]
    lines += ["", "Raw OCR output per page and setting is in `Source_Text/_pilot/`. Edit `Source_Text/settings.json` to override."]
    (TEXT / "pilot_report.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
    if not (TEXT / "settings.json").exists():
        (TEXT / "settings.json").write_text(json.dumps(rec, indent=1), encoding="utf-8")
    append(TEXT / "PROGRESS.md", "- %s pilot finished; see pilot_report.md\n" % now())
    if not IS_TEST:
        append(SL100 / "PROGRESS_LOG.md", "- %s [auto] OCR pilot finished; see Source_Text/pilot_report.md; dashboard needs syncing.\n" % datetime.now().strftime("%Y-%m-%d"))
    write_status("pilot done", "pilot")
    print("\n".join(lines))


def cmd_sample(slug, pages):
    check_tools()
    (TEXT / ".tmp").mkdir(parents=True, exist_ok=True)
    pdf = BOOKS / (slug + ".pdf")
    cfg = book_cfg(slug)
    out = TEXT / "_samples" / slug / "pages"
    jobs = [(slug, str(pdf), p, cfg, str(out / ("%04d.txt" % p))) for p in pages if not (out / ("%04d.txt" % p)).exists()]
    with Pool(2, initializer=init_worker) as pool:
        list(pool.imap_unordered(work, jobs))
    return out


def words(path):
    return re.findall(r"[A-Za-z0-9']+", path.read_text(encoding="utf-8", errors="replace").lower()) if path.exists() else []


def cmd_compare(a, b, pages):
    n = min(pdf_pages(BOOKS / (a + ".pdf")), pdf_pages(BOOKS / (b + ".pdf")))
    pages = pages or evenly(n)
    da, db = cmd_sample(a, pages), cmd_sample(b, pages)
    print("Comparing %s (%d pp) with %s (%d pp) on pages %s" % (a, pdf_pages(BOOKS / (a + ".pdf")), b, pdf_pages(BOOKS / (b + ".pdf")), pages))
    for p in pages:
        wa, wb = words(da / ("%04d.txt" % p)), words(db / ("%04d.txt" % p))
        ca, cb = collections.Counter(wa), collections.Counter(wb)
        inter = sum((ca & cb).values())
        cont = inter / max(1, min(sum(ca.values()), sum(cb.values())))
        seq = difflib.SequenceMatcher(None, wa, wb, autojunk=False).ratio() if wa and wb else 0
        print("  page %4d: words %4d vs %4d | shared-word overlap %.2f | sequence match %.2f" % (p, len(wa), len(wb), cont, seq))
    print("Overlap above ~0.85 on most pages (with similar word counts) means the same text; the longer file then holds extra pages.")


def cmd_status():
    f = TEXT / "STATUS.json"
    if not f.exists():
        print("No extraction has run yet.")
        return
    s = json.loads(f.read_text(encoding="utf-8"))
    lk = TEXT / "extract.lock"
    print("Updated %s | state: %s | batch: %s | run: %s" % (s["updated"], s["state"], s["batch"], s["run"]))
    print("Running now: %s" % ("yes (pid %s)" % lk.read_text() if lk.exists() else "no"))
    print("Books complete: %d | pages extracted: %d" % (s["books_complete"], s["pages_done"]))
    for slug, b in s["books"].items():
        print("  %-62s %4d/%-4d %s" % (slug, b["done"], b["pages"], "done" if b["complete"] else ""))
    for k, b in CONF["batches"].items():
        have = sum(1 for sl in b["books"] if s["books"].get(sl, {}).get("complete"))
        print("Batch %s: %d/%d books  - %s" % (k, have, len(b["books"]), b["title"]))


def cmd_qa():
    lines = ["# Extraction QA report", "", "Generated %s" % now(), "",
             "| Book | Pages | Text-layer | OCR | Mean OCR conf | Low-conf pages (<70) | Near-empty pages |", "|---|---|---|---|---|---|---|"]
    detail = []
    for d in sorted(TEXT.glob("SW_*")):
        mj = d / (d.name + ".meta.json")
        if not mj.exists():
            continue
        m = json.loads(mj.read_text(encoding="utf-8"))
        me = m["methods"]
        lines.append("| %s | %d | %d | %d | %s | %d | %d |" % (d.name, m["pages"], me.get("text", 0), me.get("ocr", 0),
                                                               m["mean_conf"], len(m["low_conf_pages"]), len(m["empty_pages"])))
        if m["low_conf_pages"]:
            detail.append("- %s low confidence: pages %s" % (d.name, ", ".join(map(str, m["low_conf_pages"][:40]))))
        done = sorted(pages_done(d.name))
        sample = sorted(random.Random(d.name).sample(done, min(5, len(done)))) if done else []
        detail.append("- %s eyeball these PDF pages: %s" % (d.name, ", ".join(map(str, sample))))
    (TEXT / "qa_report.md").write_text("\n".join(lines + ["", "## Details", ""] + detail) + "\n", encoding="utf-8")
    print("\n".join(lines + [""] + detail))


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("cmd", choices=["pilot", "run", "sample", "compare", "status", "qa", "batches"])
    ap.add_argument("args", nargs="*")
    ap.add_argument("--batch")
    ap.add_argument("--book")
    ap.add_argument("--workers", type=int, default=max(1, min(4, (os.cpu_count() or 2) - 1)))
    ap.add_argument("--limit-pages", type=int, default=0)
    ap.add_argument("--pages", default="")
    a = ap.parse_args()
    TEXT.mkdir(parents=True, exist_ok=True)
    pages = [int(x) for x in a.pages.split(",") if x]
    if a.cmd == "pilot":
        signal.signal(signal.SIGTERM, on_signal)
        cmd_pilot(a.workers)
    elif a.cmd == "run":
        if a.book:
            run_books([a.book], a.workers, a.limit_pages, "book " + a.book)
        elif a.batch in CONF["batches"]:
            b = CONF["batches"][a.batch]
            run_books(b["books"], a.workers, a.limit_pages, "batch %s: %s" % (a.batch, b["title"]))
        else:
            sys.exit("give --batch N (%s) or --book SLUG" % ", ".join(CONF["batches"]))
    elif a.cmd == "sample":
        cmd_sample(a.args[0], pages or evenly(pdf_pages(BOOKS / (a.args[0] + ".pdf"))))
    elif a.cmd == "compare":
        cmd_compare(a.args[0], a.args[1], pages)
    elif a.cmd == "status":
        cmd_status()
    elif a.cmd == "qa":
        cmd_qa()
    elif a.cmd == "batches":
        for k, b in CONF["batches"].items():
            print("Batch %s - %s (%d books)" % (k, b["title"], len(b["books"])))
            for s in b["books"]:
                print("    " + s)


if __name__ == "__main__":
    main()
