"""Gentle, resumable Wookieepedia (Legends) harvester.

Commands (run via ./wiki.sh or  python3 tools/crawl.py <cmd>):
  discover     list every Legends article (+ Template/Module support pages) into the local DB
  prioritize   bump RPG-relevant pages (weapons, armour, ships ...) to the front of the queue
  fetch        download wikitext, 50 pages per request, politely throttled
  images       look up dimensions of every referenced image (no image files are downloaded)
  placeholders write blank .webp placeholders + meta/images.tsv
  fts          build full-text search index for the local server
  export       write meta/pages.tsv (page index used for attribution / rebuilding)
  status       progress report
  all          discover -> prioritize -> fetch -> images -> placeholders -> export
Options: --limit N (stop after N pages fetched), --no-prioritize
Stop gracefully any time:  touch data/STOP   (or Ctrl-C / kill). Re-running resumes where it left off.
"""
import json
import os
import sys
import time

import common as C
from common import (CFG, DATA_DIR, META_DIR, PAGES_DIR, api, chunks, db_connect, log, now_iso,
                    norm_title, page_relpath, should_stop, state_get, state_set, title_ns, write_atomic)


# ---------------------------------------------------------------- lock handling
def acquire_lock():
    lock = DATA_DIR / "crawl.lock"
    if lock.exists():
        try:
            pid = int(lock.read_text().strip())
            os.kill(pid, 0)
            sys.exit("Another crawl is already running (pid %d)." % pid)
        except (ValueError, ProcessLookupError, PermissionError):
            pass
    lock.write_text(str(os.getpid()))
    stop = DATA_DIR / "STOP"
    try:
        if stop.exists():
            stop.unlink()
    except OSError:
        log("WARNING: cannot remove data/STOP - delete it by hand or the crawl will stop immediately")


def release_lock():
    for n in ("crawl.lock",):
        try:
            (DATA_DIR / n).unlink()
        except OSError:
            pass


# -------------------------------------------------------------------- discover
def cmd_topup(con):
    """Cheap incremental discovery: newest category members first; stop once a whole page is already known."""
    cat = CFG["legends_category"]
    cont, new = None, 0
    while not should_stop():
        p = dict(action="query", list="categorymembers", cmtitle=cat, cmlimit="500", cmprop="ids|title|type|timestamp",
                 cmtype="page", cmsort="timestamp", cmdir="desc")
        if cont:
            p["cmcontinue"] = cont
        r = api(**p)
        mem = r["query"]["categorymembers"]
        known = {t for (t,) in con.execute("SELECT title FROM pages WHERE title IN (%s)" % ",".join("?" * len(mem)), [m["title"] for m in mem])} if mem else set()
        rows = [(m["title"], m["pageid"], m["ns"], "listed", 100) for m in mem if m["title"] not in known]
        con.executemany("INSERT OR IGNORE INTO pages(title,pageid,ns,status,priority) VALUES(?,?,?,?,?)", rows)
        con.commit()
        new += len(rows)
        log("topup: %d new so far (%d known on this page)" % (new, len(known)))
        cont = r.get("continue", {}).get("cmcontinue")
        if not cont or not rows:
            break
    log("topup: %d new Legends pages queued" % new)


def cmd_discover(con):
    cat = CFG["legends_category"]
    cont = state_get(con, "discover_cont")
    if state_get(con, "discover_done") == "1":
        log("discover: Legends list already complete (delete state row 'discover_done' to redo)")
    else:
        total = con.execute("SELECT COUNT(*) FROM pages").fetchone()[0]
        log("discover: listing %s (have %d so far)" % (cat, total))
        while not should_stop():
            p = dict(action="query", list="categorymembers", cmtitle=cat, cmlimit="500",
                     cmprop="ids|title|type", cmtype="page")
            if cont:
                p["cmcontinue"] = cont
            r = api(**p)
            rows = [(m["title"], m["pageid"], m["ns"], "listed", 100)
                    for m in r["query"]["categorymembers"]]
            con.executemany("INSERT OR IGNORE INTO pages(title,pageid,ns,status,priority) VALUES(?,?,?,?,?)", rows)
            cont = r.get("continue", {}).get("cmcontinue")
            state_set(con, "discover_cont", cont or "")
            con.commit()
            total += len(rows)
            log("  listed %d" % total)
            if not cont:
                state_set(con, "discover_done", "1")
                break
    # support namespaces (templates, lua modules) so pages can be rebuilt / imported elsewhere
    for ns in CFG["support_namespaces"]:
        if should_stop() or state_get(con, "support_done_%d" % ns) == "1":
            continue
        cont = state_get(con, "support_cont_%d" % ns)
        log("discover: namespace %d" % ns)
        while not should_stop():
            p = dict(action="query", list="allpages", apnamespace=str(ns), aplimit="500", apfilterredir="nonredirects")
            if cont:
                p["apcontinue"] = cont
            r = api(**p)
            rows = [(m["title"], m["pageid"], ns, "listed", 5) for m in r["query"]["allpages"]]
            con.executemany("INSERT OR IGNORE INTO pages(title,pageid,ns,status,priority) VALUES(?,?,?,?,?)", rows)
            cont = r.get("continue", {}).get("apcontinue")
            state_set(con, "support_cont_%d" % ns, cont or "")
            con.commit()
            if not cont:
                state_set(con, "support_done_%d" % ns, "1")
                break


# ------------------------------------------------------------------ prioritize
def cmd_prioritize(con):
    depth = int(CFG["priority_depth"])
    cap = int(CFG["priority_max_categories_per_root"])
    for root, weight in CFG["priority_roots"].items():
        if should_stop():
            return
        key = "prio_done:" + root
        if state_get(con, key) == "1":
            continue
        queue = [("Category:" + root, 0)]
        seen = set()
        n = 0
        log("prioritize: %s (weight %d)" % (root, weight))
        while queue and n < cap and not should_stop():
            cat, d = queue.pop(0)
            if cat in seen:
                continue
            seen.add(cat)
            n += 1
            cont = None
            while not should_stop():
                p = dict(action="query", list="categorymembers", cmtitle=cat, cmlimit="500", cmprop="title|type")
                if cont:
                    p["cmcontinue"] = cont
                r = api(**p)
                hits = []
                for m in r["query"]["categorymembers"]:
                    if m["type"] == "subcat":
                        if d < depth:
                            queue.append((m["title"], d + 1))
                    else:
                        hits.append((weight, m["title"], weight))
                con.executemany("UPDATE pages SET priority=? WHERE title=? AND priority>? AND status='listed'", hits)
                con.commit()
                cont = r.get("continue", {}).get("cmcontinue")
                if not cont:
                    break
        else:
            pass
        if not should_stop():
            state_set(con, key, "1")
            con.commit()
    log("prioritize: done")


# ----------------------------------------------------------------------- fetch
def taken_paths(con):
    return {r[0].lower() for r in con.execute("SELECT path FROM pages WHERE path IS NOT NULL")}


def cmd_fetch(con, limit=None):
    taken = taken_paths(con)
    done = 0
    bs = int(CFG["batch_size"])
    t0 = time.time()
    while not should_stop() and (limit is None or done < limit):
        rows = con.execute(
            "SELECT title,ns FROM pages WHERE status='listed' AND local_edit=0 ORDER BY priority, title LIMIT ?",
            (bs,)).fetchall()
        if not rows:
            log("fetch: nothing left to fetch")
            break
        titles = [r["title"] for r in rows]
        nsmap = {r["title"]: r["ns"] for r in rows}
        r = api(action="query", prop="revisions", rvprop="ids|timestamp|content|size", rvslots="main",
                titles="|".join(titles))
        got = set()
        for pg in r["query"].get("pages", []):
            t = pg["title"]
            if t not in nsmap:                 # title normalised differently by the server
                continue
            got.add(t)
            if pg.get("missing") or "invalid" in pg:
                con.execute("UPDATE pages SET status='missing', fetched_at=? WHERE title=?", (now_iso(), t))
                continue
            revs = pg.get("revisions")
            if not revs:
                con.execute("UPDATE pages SET tries=tries+1, status=CASE WHEN tries>=4 THEN 'error' ELSE status END "
                            "WHERE title=?", (t,))
                continue
            rev = revs[0]
            text = rev["slots"]["main"]["content"]
            ns = pg.get("ns", nsmap[t])
            rel = page_relpath(t, ns, taken)
            taken.add(rel.lower())
            write_atomic(PAGES_DIR / rel, text)
            red = C.redirect_target(text)
            con.execute(
                "UPDATE pages SET status=?, path=?, revid=?, ts=?, bytes=?, fetched_at=?, redirect_to=?, pageid=?, ns=? "
                "WHERE title=?",
                ("redirect" if red else "ok", rel, rev.get("revid"), rev.get("timestamp"), len(text.encode("utf-8")),
                 now_iso(), red, pg.get("pageid"), ns, t))
            C.record_page_meta(con, t, text)
            done += 1
        for t in titles:                      # server returned nothing for it at all
            if t not in got:
                con.execute("UPDATE pages SET tries=tries+1, status=CASE WHEN tries>=4 THEN 'error' ELSE status END "
                            "WHERE title=?", (t,))
        con.commit()
        left = con.execute("SELECT COUNT(*) FROM pages WHERE status='listed'").fetchone()[0]
        rate = done / max(1, time.time() - t0)
        eta = left / rate / 3600 if rate else 0
        log("fetch: %d pages this run | %d still queued | ~%.1f h remaining" % (done, left, eta))
    return done


# ---------------------------------------------------------------------- images
def cmd_images(con):
    bs = int(CFG["batch_size"])
    while not should_stop():
        rows = con.execute("SELECT name FROM imgs WHERE status='listed' ORDER BY uses DESC, name LIMIT ?", (bs,)).fetchall()
        if not rows:
            log("images: all dimensions known")
            break
        names = [r["name"] for r in rows]
        r = api(action="query", prop="imageinfo", iiprop="url|size|mime",
                titles="|".join("File:" + n for n in names))
        seen = set()
        for pg in r["query"].get("pages", []):
            n = pg["title"].split(":", 1)[1] if ":" in pg["title"] else pg["title"]
            ii = (pg.get("imageinfo") or [None])[0]
            if n not in names:
                n = norm_title(n)
            if ii:
                con.execute("UPDATE imgs SET status='ok', width=?, height=?, mime=?, size=?, url=? WHERE name=?",
                            (ii.get("width"), ii.get("height"), ii.get("mime"), ii.get("size"), ii.get("url"), n))
            else:
                con.execute("UPDATE imgs SET status='missing' WHERE name=?", (n,))
            seen.add(n)
        for n in names:                        # anything the server never mentioned
            if n not in seen:
                con.execute("UPDATE imgs SET status='missing' WHERE name=? AND status='listed'", (n,))
        con.commit()
        left = con.execute("SELECT COUNT(*) FROM imgs WHERE status='listed'").fetchone()[0]
        log("images: %d still to look up" % left)


# ---------------------------------------------------------------------- export
def cmd_export(con):
    lines = ["title\tns\tpageid\trevid\ttimestamp\tbytes\tstatus\tlocal_edit\tpath"]
    for r in con.execute("SELECT * FROM pages WHERE path IS NOT NULL ORDER BY title COLLATE NOCASE"):
        lines.append("\t".join(str(r[k] if r[k] is not None else "") for k in
                               ("title", "ns", "pageid", "revid", "ts", "bytes", "status", "local_edit", "path")))
    write_atomic(META_DIR / "pages.tsv", "\n".join(lines) + "\n")
    log("export: meta/pages.tsv (%d pages)" % (len(lines) - 1))


def cmd_rebuild(con):
    """Rebuild data/wiki.db from meta/pages.tsv + the .wiki files (e.g. after a fresh git clone)."""
    p = META_DIR / "pages.tsv"
    if not p.exists():
        sys.exit("meta/pages.tsv not found")
    n = 0
    for line in p.read_text(encoding="utf-8").splitlines()[1:]:
        f = line.split("\t")
        if len(f) < 9:
            continue
        title, ns, pid, rev, ts, size, st, le, path = f[:9]
        con.execute("INSERT OR REPLACE INTO pages(title,pageid,ns,status,path,revid,ts,bytes,local_edit,priority) "
                    "VALUES(?,?,?,?,?,?,?,?,?,100)",
                    (title, int(pid or 0), int(ns or 0), st, path, int(rev or 0), ts, int(size or 0), int(le or 0)))
        fp = PAGES_DIR / path
        if fp.exists():
            C.record_page_meta(con, title, fp.read_text(encoding="utf-8", errors="replace"))
        n += 1
        if n % 2000 == 0:
            con.commit()
    con.commit()
    n += C.register_untracked(con)
    log("rebuild: %d pages indexed" % n)


def cmd_fts(con):
    """Build a full-text search index (data/wiki.db) over local pages. Takes a while for the full wiki."""
    import re
    con.execute("DROP TABLE IF EXISTS fts")
    con.execute("CREATE VIRTUAL TABLE fts USING fts5(title, body, tokenize='porter unicode61')")
    n = 0
    for r in con.execute("SELECT title,path FROM pages WHERE path IS NOT NULL AND ns IN (0,3000)").fetchall():
        f = PAGES_DIR / r["path"]
        if not f.exists():
            continue
        t = f.read_text(encoding="utf-8", errors="replace")
        t = re.sub(r"<ref[^>]*>.*?</ref>|<!--.*?-->|\{\|.*?\|\}", " ", t, flags=re.S)
        t = re.sub(r"\[\[(?:[^\]|]*\|)?([^\]]*)\]\]", r"\1", t)
        t = re.sub(r"\{\{[^{}]*\}\}|<[^>]+>|[{}\[\]|=*#']", " ", t)
        con.execute("INSERT INTO fts(title,body) VALUES(?,?)", (r["title"], t))
        n += 1
        if n % 2000 == 0:
            con.commit()
            log("fts: %d pages" % n)
    con.commit()
    log("fts: done, %d pages" % n)


def cmd_status(con):
    q = lambda s: con.execute(s).fetchall()
    print("Pages by status:")
    for r in q("SELECT status, COUNT(*) c FROM pages GROUP BY status ORDER BY c DESC"):
        print("  %-10s %d" % (r["status"], r["c"]))
    print("Priority queue (listed pages):")
    for r in q("SELECT priority, COUNT(*) c FROM pages WHERE status='listed' GROUP BY priority ORDER BY priority"):
        print("  priority %-4s %d" % (r["priority"], r["c"]))
    print("Images:")
    for r in q("SELECT status, COUNT(*) c FROM imgs GROUP BY status"):
        print("  %-10s %d" % (r["status"], r["c"]))
    b = q("SELECT COALESCE(SUM(bytes),0) b FROM pages")[0]["b"]
    print("Wikitext on disk: %.1f MB" % (b / 1e6))
    print("discover_done=%s" % state_get(con, "discover_done"))


def main():
    args = sys.argv[1:]
    if not args or args[0] in ("-h", "--help"):
        print(__doc__)
        return
    cmd = args[0]
    limit = int(args[args.index("--limit") + 1]) if "--limit" in args else None
    con = db_connect()
    if cmd in ("status", "export", "rebuild", "fts"):
        {"status": cmd_status, "export": cmd_export, "rebuild": cmd_rebuild, "fts": cmd_fts}[cmd](con)
        return
    C.install_signal_handlers()
    acquire_lock()
    try:
        steps = {"all": ["discover", "prioritize", "fetch", "images", "placeholders", "export"],
                 "discover": ["discover"], "topup": ["topup", "fetch", "images", "placeholders", "export"], "prioritize": ["prioritize"], "fetch": ["fetch"],
                 "images": ["images"], "placeholders": ["placeholders"]}.get(cmd)
        if not steps:
            sys.exit("unknown command " + cmd)
        if "--no-prioritize" in args and "prioritize" in steps:
            steps.remove("prioritize")
        try:
            for s in steps:
                if should_stop():
                    break
                log("=== %s ===" % s)
                if s == "discover":
                    cmd_discover(con)
                elif s == "topup":
                    cmd_topup(con)
                elif s == "prioritize":
                    cmd_prioritize(con)
                elif s == "fetch":
                    cmd_fetch(con, limit)
                elif s == "images":
                    cmd_images(con)
                elif s == "placeholders":
                    import placeholders
                    placeholders.generate_all()
                elif s == "export":
                    cmd_export(con)
        except C.ApiError as e:
            log("STOPPED by API problem: %s (re-run to resume)" % e)
            con.commit()
        log("finished (or stopped); progress saved.")
    finally:
        con.commit()
        release_lock()


if __name__ == "__main__":
    main()
