#!/usr/bin/env python3
"""Gather Wookieepedia images for the local wiki, by licence, as WebP - gently and resumably - and score them for review.

  images.py classify [--limit N]   look up licence + author + a download URL for every image our pages use (50 per request)
  images.py fetch [--bucket free|fair|untagged|all] [--limit N]
                                   download, convert to WebP (max 800 px), save:
                                     free     -> images/full/<x>/<name>.webp   (CC-BY-SA, GFDL, public domain, free use; pushed to GitHub)
                                     fair / untagged -> images/local/<x>/<name>.webp  (private local wiki only, git-ignored)
  images.py qc                     score every downloaded image (size, sharpness, flatness, aspect, compression, duplicates)
  images.py export                 meta/image_licences.tsv (attribution for every downloaded image) + meta/image_review.tsv
  images.py status
Review in the local wiki: http://127.0.0.1:8100/image-review (lowest scores first, one click per page of 120).
Stop a running fetch with:  touch data/STOP   (re-run to resume).
"""
import hashlib, io, json, re, sys, time, urllib.parse, urllib.request
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import common as C          # noqa: E402
import placeholders         # noqa: E402

LOCAL_IMG_DIR = C.IMG_DIR / "local"
MAX_W = int(C.CFG.get("image_max_width", 800))
DELAY = float(C.CFG.get("image_delay_seconds", 1.0))
FREE = re.compile(r"CC-BY|Creative Commons|GFDL|public domain|Free use|Free images", re.I)
FAIR = re.compile(r"Fair use", re.I)
SCHEMA = """CREATE TABLE IF NOT EXISTS imglic(
  name TEXT PRIMARY KEY, bucket TEXT, licence TEXT, artist TEXT, credit TEXT, cats TEXT, descurl TEXT, srcurl TEXT,
  ow INTEGER, oh INTEGER, obytes INTEGER, status TEXT DEFAULT 'classified', path TEXT, bytes INTEGER, fetched_at TEXT,
  q_score INTEGER, q_flags TEXT, dhash TEXT, sharp REAL, review TEXT, reviewed_at TEXT);
CREATE INDEX IF NOT EXISTS imglic_status ON imglic(status, bucket);"""


def db():
    con = C.db_connect()
    con.executescript(SCHEMA)
    try:
        con.execute("ALTER TABLE imglic ADD COLUMN sharp REAL")
    except Exception:
        pass
    return con


def strip_html(s):
    return re.sub(r"\s+", " ", re.sub(r"<[^>]+>", "", s or "")).strip()[:300]


def bucket_of(cats, lic):
    joined = " | ".join(cats) + " | " + (lic or "")
    if FAIR.search(joined):
        return "fair"
    if FREE.search(joined):
        return "free"
    return "untagged"


def cmd_classify(limit=None):
    con = db()
    names = [r[0] for r in con.execute("SELECT name FROM imgs WHERE status='ok' AND name NOT IN (SELECT name FROM imglic) ORDER BY uses DESC")]
    if limit:
        names = names[:limit]
    C.log("classify: %d images to look up" % len(names))
    done = 0
    for chunk in C.chunks(names, 50):
        if C.should_stop():
            break
        r = C.api(action="query", titles="|".join("File:" + n for n in chunk), prop="categories|imageinfo", cllimit="max",
                  iiprop="url|size|extmetadata", iiurlwidth=str(MAX_W), iiextmetadatafilter="Artist|LicenseShortName|Credit|UsageTerms")
        q = r.get("query", {})
        norm = {x["to"]: x["from"] for x in q.get("normalized", [])}
        rows = []
        for p in q.get("pages", []):
            title = p.get("title", "")[5:]
            name = norm.get("File:" + title, "File:" + title)[5:]
            cats = [c["title"].split(":", 1)[1] for c in p.get("categories", [])]
            ii = (p.get("imageinfo") or [{}])[0]
            md = ii.get("extmetadata") or {}
            if not isinstance(md, dict):
                md = {}
            lic = (md.get("LicenseShortName") or {}).get("value", "")
            b = bucket_of(cats, lic) if ii else "missing"
            artist = strip_html((md.get("Artist") or {}).get("value"))
            if not artist:
                artist = "; ".join(c[10:] for c in cats if c.startswith("Images by "))
            rows.append((name, b, strip_html(lic) or "; ".join(c for c in cats if FREE.search(c) or FAIR.search(c)),
                         artist, strip_html((md.get("Credit") or {}).get("value")),
                         "; ".join(cats)[:500], ii.get("descriptionurl", ""), ii.get("thumburl") or ii.get("url", ""),
                         ii.get("width"), ii.get("height"), ii.get("size"), "classified" if ii else "missing"))
        con.executemany("INSERT OR REPLACE INTO imglic(name,bucket,licence,artist,credit,cats,descurl,srcurl,ow,oh,obytes,status) "
                        "VALUES(?,?,?,?,?,?,?,?,?,?,?,?)", rows)
        con.commit()
        done += len(chunk)
        if done % 1000 < 50:
            C.log("  classified %d / %d" % (done, len(names)))
    cmd_status()


def dest(name, bucket):
    rel = placeholders.placeholder_relpath(name)          # <x>/<safe name>.webp
    return (C.FULL_IMG_DIR if bucket == "free" else LOCAL_IMG_DIR) / rel


def to_webp(data):
    """Return WebP bytes. Wookieepedia's CDN usually serves WebP already: keep those untouched when small enough."""
    from PIL import Image
    if data[:4] == b"RIFF" and data[8:12] == b"WEBP":
        try:
            if Image.open(io.BytesIO(data)).width <= MAX_W:
                return data
        except Exception:
            return data
    im = Image.open(io.BytesIO(data))
    try:
        im.seek(0)
    except Exception:
        pass
    if im.mode not in ("RGB", "RGBA"):
        im = im.convert("RGBA" if "A" in im.getbands() or im.mode == "P" else "RGB")
    if im.width > MAX_W:
        im = im.resize((MAX_W, max(1, round(im.height * MAX_W / im.width))), Image.LANCZOS)
    out = io.BytesIO()
    im.save(out, "WEBP", quality=80, method=4)
    return out.getvalue()


def cmd_fetch(bucket="all", limit=None):
    con = db()
    where = "status IN ('classified','error')" + ("" if bucket == "all" else " AND bucket='%s'" % bucket.replace("'", ""))
    rows = con.execute("SELECT name,bucket,srcurl FROM imglic WHERE %s ORDER BY bucket='free' DESC, name" % where).fetchall()
    if limit:
        rows = rows[:limit]
    C.log("fetch: %d images (%s), %.1f s apart" % (len(rows), bucket, DELAY))
    ok = bad = streak = 0
    for n, (name, b, url) in enumerate(rows, 1):
        if C.should_stop():
            C.log("fetch: stop requested; progress saved")
            break
        if not url:
            continue
        if name.lower().endswith(".svg") and "scale-to-width" not in url:       # ask the CDN for a rasterised copy
            url = url.replace("/revision/latest", "/revision/latest/scale-to-width-down/%d" % MAX_W, 1)
        try:
            req = urllib.request.Request(url, headers={"User-Agent": C.CFG["user_agent"]})
            data = urllib.request.urlopen(req, timeout=60).read()
            webp = to_webp(data)
            p = dest(name, b)
            p.parent.mkdir(parents=True, exist_ok=True)
            tmp = p.with_suffix(".tmp")
            tmp.write_bytes(webp)
            tmp.replace(p)
            con.execute("UPDATE imglic SET status='ok', path=?, bytes=?, fetched_at=? WHERE name=?",
                        (p.relative_to(C.ROOT).as_posix(), len(webp), C.now_iso(), name))
            ok += 1
            streak = 0
        except Exception as e:  # noqa: BLE001
            bad += 1
            streak = streak + 1 if "403" in repr(e) else 0
            if streak >= 20:
                con.execute("UPDATE imglic SET status=?, q_flags=? WHERE name=?", ("error", ("fetch: %r" % e)[:200], name))
                con.commit()
                C.log("fetch: 20 refusals (HTTP 403) in a row - the image server is refusing this connection (bot check). "
                      "Stopped; nothing is lost. Wait some hours, then re-run (errors are retried).")
                break
            st = "skipped" if "cannot identify image" in repr(e) else "error"     # not a raster image (sound, video, odd format)
            con.execute("UPDATE imglic SET status=?, q_flags=? WHERE name=?", (st, ("fetch: %r" % e)[:200], name))
        if ok % 50 == 0:
            con.commit()
        if n % 100 == 0:
            C.log("  %d / %d tried: %d saved, %d failed" % (n, len(rows), ok, bad))
        time.sleep(DELAY)
    con.commit()
    C.log("fetch: %d saved this run" % ok)


def dhash(im):
    g = im.convert("L").resize((9, 8))
    px = list(g.tobytes())
    bits = "".join("1" if px[r * 9 + c] > px[r * 9 + c + 1] else "0" for r in range(8) for c in range(8))
    return "%016x" % int(bits, 2)


def cmd_qc():
    from PIL import Image, ImageFilter, ImageStat
    con = db()
    rows = con.execute("SELECT name,path,ow,oh,obytes FROM imglic WHERE status='ok' AND q_score IS NULL").fetchall()
    C.log("qc: scoring %d images" % len(rows))
    for n, (name, path, ow, oh, ob) in enumerate(rows, 1):
        try:
            im = Image.open(C.ROOT / path)
            im.load()
        except Exception as e:  # noqa: BLE001
            con.execute("UPDATE imglic SET q_score=0, q_flags=? WHERE name=?", ("unreadable: %r" % e, name)); continue
        ow, oh = ow or im.width, oh or im.height
        flags, score = [], 100
        short = min(ow, oh)
        if short < 200:
            flags.append("tiny (<200 px)"); score -= 40
        elif short < 400:
            flags.append("small (<400 px)"); score -= 15
        g = im.convert("L")
        g.thumbnail((400, 400))
        sharp = ImageStat.Stat(g.filter(ImageFilter.FIND_EDGES)).var[0]     # edge energy; judged against the whole set below
        if ImageStat.Stat(g).stddev[0] < 15:
            flags.append("flat/blank"); score -= 35
        ar = max(ow, oh) / max(1, min(ow, oh))
        if ar > 4:
            flags.append("extreme aspect"); score -= 10
        if ob and ow and oh and ob / (ow * oh) < 0.06 and name.lower().endswith((".jpg", ".jpeg")):
            flags.append("heavily compressed"); score -= 10
        con.execute("UPDATE imglic SET q_score=?, q_flags=?, dhash=?, sharp=? WHERE name=?", (max(0, score), "; ".join(flags), dhash(im), sharp, name))
        if n % 500 == 0:
            con.commit(); C.log("  scored %d / %d" % (n, len(rows)))
    # sharpness relative to the whole collection: bottom 3 % "blurry" (-30), next 7 % "soft" (-10); re-judged each run
    vals = sorted(v for (v,) in con.execute("SELECT sharp FROM imglic WHERE sharp IS NOT NULL"))
    if len(vals) >= 50:
        p3, p10 = vals[len(vals) * 3 // 100], vals[len(vals) // 10]
        for name, sh, sc, fl in con.execute("SELECT name,sharp,q_score,coalesce(q_flags,'') FROM imglic WHERE sharp IS NOT NULL").fetchall():
            if "blurry" in fl or "soft" in fl:
                continue
            if sh <= p3:
                con.execute("UPDATE imglic SET q_score=max(0,q_score-30), q_flags=trim(? || '; blurry', '; ') WHERE name=?", (fl, name))
            elif sh <= p10:
                con.execute("UPDATE imglic SET q_score=max(0,q_score-10), q_flags=trim(? || '; soft', '; ') WHERE name=?", (fl, name))
    # duplicates: identical perceptual hash
    dup = {}
    for name, h in con.execute("SELECT name,dhash FROM imglic WHERE dhash IS NOT NULL ORDER BY name"):
        dup.setdefault(h, []).append(name)
    for h, names in dup.items():
        if len(names) > 1 and h not in ("0000000000000000", "ffffffffffffffff"):
            for nm in names[1:]:
                con.execute("UPDATE imglic SET q_flags=trim(coalesce(q_flags,'') || '; duplicate of ' || ?, '; ') WHERE name=? "
                            "AND coalesce(q_flags,'') NOT LIKE '%duplicate of%'", (names[0], nm))
    con.commit()
    cmd_status()


def cmd_export():
    con = db()
    with open(C.META_DIR / "image_licences.tsv", "w", encoding="utf-8") as fh:
        fh.write("name\tbucket\tlicence\tartist\tcredit\tfile_page\tlocal_path\n")
        for r in con.execute("SELECT name,bucket,licence,artist,credit,descurl,path FROM imglic WHERE status='ok' ORDER BY name"):
            fh.write("\t".join((x or "").replace("\t", " ") for x in r) + "\n")
    with open(C.META_DIR / "image_review.tsv", "w", encoding="utf-8") as fh:
        fh.write("name\tbucket\tq_score\tq_flags\treview\treviewed_at\n")
        for r in con.execute("SELECT name,bucket,q_score,q_flags,review,reviewed_at FROM imglic WHERE status='ok' ORDER BY name"):
            fh.write("\t".join("" if x is None else str(x).replace("\t", " ") for x in r) + "\n")
    with open(C.META_DIR / "image_replace.tsv", "w", encoding="utf-8") as fh:     # work list for new art (image generation)
        fh.write("name\tlicence_bucket\treason\tused_on\n")
        for name, b, why in con.execute("SELECT name,bucket,coalesce(q_flags,'') FROM imglic WHERE review='replace' ORDER BY name").fetchall():
            pages = [r[0] for r in con.execute("SELECT page FROM imguse WHERE img=? LIMIT 3", (name,))]
            fh.write("%s\t%s\t%s\t%s\n" % (name, b, why, " | ".join(pages)))
    print("wrote meta/image_licences.tsv, meta/image_review.tsv and meta/image_replace.tsv")


def cmd_status():
    con = db()
    print("Licence buckets (images used on our pages):")
    for r in con.execute("SELECT bucket, status, COUNT(*), COALESCE(SUM(bytes),0) FROM imglic GROUP BY bucket, status ORDER BY bucket, status"):
        print("  %-9s %-11s %7d  %6.1f MB" % (r[0], r[1], r[2], r[3] / 1e6))
    left = con.execute("SELECT COUNT(*) FROM imgs WHERE status='ok' AND name NOT IN (SELECT name FROM imglic)").fetchone()[0]
    print("  not yet classified: %d" % left)
    r = con.execute("SELECT COUNT(*), SUM(q_score<50), SUM(review IS NOT NULL) FROM imglic WHERE q_score IS NOT NULL").fetchone()
    print("QC: %d scored, %d below 50, %d reviewed" % (r[0], r[1] or 0, r[2] or 0))


def main():
    a = sys.argv[1:]
    if not a or a[0] in ("-h", "--help"):
        print(__doc__); return
    lim = int(a[a.index("--limit") + 1]) if "--limit" in a else None
    bucket = a[a.index("--bucket") + 1] if "--bucket" in a else "all"
    {"classify": lambda: cmd_classify(lim), "fetch": lambda: cmd_fetch(bucket, lim), "qc": cmd_qc,
     "export": cmd_export, "status": cmd_status}[a[0]]()


if __name__ == "__main__":
    main()
