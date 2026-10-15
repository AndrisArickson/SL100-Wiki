#!/usr/bin/env python3
"""Hand-downloaded Wookieepedia images -> WebP in the wiki.

  ingest_images.py species      write the species work list: meta/species_images.tsv and
                                images/incoming/species_download_list.html (open it in your browser,
                                click each image, save it into images/incoming/)
  ingest_images.py ingest       convert everything in images/incoming/ to WebP (max 800 px), put it where the
                                wiki looks (images/full, pushed to GitHub),
                                mark it fetched, and move the original to images/incoming/done/
  ingest_images.py status       species images: how many are in the wiki, how many still to download

A saved file is matched to its wiki image by file name (spaces, underscores, case and extension don't matter,
so "Arkanians_DoH.png", "Arkanians DoH.webp" and "arkanians_doh.jpg" all match "Arkanians DoH.png").
A file named after a species ("Arkanian.png", "KelDor.jpg") replaces that species' Legends article picture, which is
also the picture SL100:Species shows (a copy is kept as "SL100 Species <Name>.jpg"). Unmatched files are listed and left in place.
Writes data/wiki.db: run when no other image job is running."""
import html
import re
import shutil
import sys
import urllib.parse
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import common as C  # noqa: E402
import images as I  # noqa: E402

ROOT = C.ROOT
INCOMING = C.IMG_DIR / "incoming"
DONE = INCOMING / "done"
SPECIES_MD = C.RULES_DIR / "02 New Star Wars - Species (revised).md"
SPECIES_TSV = C.META_DIR / "species_images.tsv"
EXTS = {".png", ".jpg", ".jpeg", ".webp", ".gif", ".bmp", ".tif", ".tiff", ".avif"}


def norm(s):
    s = urllib.parse.unquote(s).strip().lower().replace("_", " ")
    while True:
        b, e = Path(s).stem, Path(s).suffix
        if e in EXTS or e in (".svg",):
            s = b
        else:
            break
    return re.sub(r"\s+", " ", s).strip()


def page_text(con, title, depth=0):
    r = con.execute("SELECT path, redirect_to FROM pages WHERE title=?", (title,)).fetchone()
    if not r:
        return None, None
    if r[1] and depth < 3:
        return page_text(con, r[1], depth + 1)
    p = C.PAGES_DIR / r[0] if r[0] else None
    return title, (p.read_text(encoding="utf-8") if p and p.exists() else None)


def species_rows(con):
    md = SPECIES_MD.read_text(encoding="utf-8")
    out = []
    for name, url in re.findall(r"^### \[([^\]]+)\]\(https://starwars\.fandom\.com/wiki/([^)#?]+)\)", md, re.M):
        title = urllib.parse.unquote(url).replace("_", " ")
        pt, txt = page_text(con, title)
        if not txt and not title.endswith("/Legends"):          # entry links the canon article: use the Legends one for the picture
            pt, txt = page_text(con, title + "/Legends")
        f = ""
        if txt:
            m = re.search(r"\|\s*image\s*=\s*\[\[(?:File|Image):([^|\]]+)", txt) or re.search(r"\[\[(?:File|Image):([^|\]]+)", txt)
            f = m.group(1).strip().replace("_", " ") if m else ""
        r = con.execute("SELECT bucket, status, descurl, srcurl FROM imglic WHERE name=?", (f,)).fetchone() if f else None
        out.append({"species": name, "page": pt or title, "file": f, "bucket": r[0] if r else "",
                    "status": r[1] if r else ("no image" if txt else "no local page"),
                    "file_page": r[2] if r else "", "image_url": r[3] if r else ""})
    return out


def cmd_species():
    con = I.db()
    rows = species_rows(con)
    cols = ["species", "page", "file", "bucket", "status", "file_page", "image_url"]
    SPECIES_TSV.write_text("\t".join(cols) + "\n" + "".join("\t".join(r[c] or "" for c in cols) + "\n" for r in rows), encoding="utf-8")
    INCOMING.mkdir(parents=True, exist_ok=True)
    todo = [r for r in rows if r["file"] and r["status"] != "ok"]
    have = sum(1 for r in rows if r["status"] == "ok")
    li = []
    for r in todo:
        li.append('<tr><td>%s</td><td><a href="%s" target="_blank">%s</a></td><td><a href="%s" target="_blank">open image</a></td><td>%s</td></tr>' % (
            html.escape(r["species"]), html.escape(r["file_page"]), html.escape(r["file"]), html.escape(r["image_url"]), html.escape(r["bucket"])))
    page = """<!doctype html><meta charset="utf-8"><title>Species images to download</title>
<style>body{font:15px system-ui,sans-serif;margin:24px;max-width:1000px}table{border-collapse:collapse;width:100%%}td,th{border-bottom:1px solid #ccc;padding:5px 8px;text-align:left}code{background:#eee;padding:1px 4px}</style>
<h1>Species images to download (%d left, %d already in the wiki)</h1>
<ol><li>Click <b>open image</b>, then right-click the picture and choose <b>Save image as</b>.</li>
<li>Save it into <code>%s</code>. Keep the name the browser offers; if it offers <code>latest</code>, name it after the species (e.g. <code>Arkanian.png</code>).</li>
<li>When you have a batch, run <code>./wiki.sh images-ingest</code> and refresh this list with <code>./wiki.sh species-images</code>.</li></ol>
<p>They are converted to WebP and go to images/full, which is pushed to GitHub. The originals are kept in images/incoming/done.</p>
<table><tr><th>Species</th><th>Wookieepedia file page</th><th>Image</th><th>Licence</th></tr>%s</table>""" % (len(todo), have, "SL100-Wiki/images/incoming/", "".join(li))
    (INCOMING / "species_download_list.html").write_text(page, encoding="utf-8")
    print("species: %d, image in wiki: %d, to download: %d, no image found: %d" % (
        len(rows), have, len(todo), sum(1 for r in rows if not r["file"])))
    print("list: SL100-Wiki/images/incoming/species_download_list.html (open it in your browser)\nsave into: SL100-Wiki/images/incoming/")


def squash(s):
    return re.sub(r"[^a-z0-9]", "", norm(s))


def portrait_name(species):
    return "SL100 Species %s.jpg" % re.sub(r"[^\w' -]", "", species).strip()


def put(con, name, bucket, data, licence=None, flag="hand-downloaded"):
    webp = I.to_webp(data)
    d = I.dest(name, bucket)
    d.parent.mkdir(parents=True, exist_ok=True)
    tmp = d.with_suffix(".tmp")
    tmp.write_bytes(webp)
    tmp.replace(d)
    if licence:
        con.execute("INSERT OR REPLACE INTO imglic(name,bucket,licence,artist,credit,cats,descurl,srcurl,status,path,bytes,fetched_at,q_flags) "
                    "VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?)",
                    (name, bucket, licence, "", "Picked by the SL100 group from Wookieepedia; local wiki only", "SL100 species portraits",
                     "", "", "ok", d.relative_to(ROOT).as_posix(), len(webp), C.now_iso(), flag))
    else:
        con.execute("UPDATE imglic SET status='ok', path=?, bytes=?, fetched_at=?, q_flags=? WHERE name=?",
                    (d.relative_to(ROOT).as_posix(), len(webp), C.now_iso(), flag, name))


def cmd_ingest():
    """A file named after a species (Arkanian.jpg, KelDor.jpg, Twilek.jpg) becomes that species' portrait,
    'SL100 Species <Name>.jpg', and replaces the species' Legends article picture, which is what SL100:Species shows.
    Any other file is matched to the Wookieepedia image of the same name."""
    con = I.db()
    if not SPECIES_TSV.exists():
        cmd_species()
    species = {}
    for ln in SPECIES_TSV.read_text(encoding="utf-8").splitlines()[1:]:
        c = ln.split("\t")
        if len(c) > 2:
            species[squash(c[0])] = (c[0], c[2], c[3] or "fair")
    by_norm = {}
    for (name,) in con.execute("SELECT name FROM imglic"):
        by_norm.setdefault(norm(name), name)
    files = [p for p in sorted(INCOMING.iterdir()) if p.is_file() and p.suffix.lower() in EXTS]
    ok, unmatched = 0, []
    DONE.mkdir(parents=True, exist_ok=True)
    for p in files:
        data = p.read_bytes()
        try:
            sp = species.get(squash(p.name))
            if sp:
                sname, sfile, sbucket = sp
                put(con, portrait_name(sname), "fair", data, licence="Fair use (Wookieepedia image picked for the species portrait)")
                msg = "species portrait %s" % sname
                if sfile:                      # SL100:Species shows the article picture, so the two always match
                    put(con, sfile, sbucket, data, flag="hand-picked for the species")
                    msg += " + article picture " + sfile
            else:
                name = by_norm.get(norm(p.name))
                if not name:
                    unmatched.append(p.name)
                    continue
                b = (con.execute("SELECT bucket FROM imglic WHERE name=?", (name,)).fetchone() or ["untagged"])[0] or "untagged"
                put(con, name, b, data)
                msg = "%s (%s)" % (name, b)
        except Exception as e:  # noqa: BLE001
            print("  could not read %s: %s" % (p.name, e))
            continue
        shutil.move(str(p), str(DONE / p.name))
        ok += 1
        print("  %-40s -> %s" % (p.name, msg))
    con.commit()
    print("ingested %d; unmatched %d%s" % (ok, len(unmatched), (": " + ", ".join(unmatched)) if unmatched else ""))
    if unmatched:
        print("Rename unmatched files to the species name or the Wookieepedia file name, then run again.")


def cmd_status():
    con = I.db()
    rows = species_rows(con)
    have = [r for r in rows if r["status"] == "ok"]
    print("species %d: images in wiki %d, still to download %d, no image found %d" % (
        len(rows), len(have), sum(1 for r in rows if r["file"] and r["status"] != "ok"), sum(1 for r in rows if not r["file"])))


if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else "status"
    {"species": cmd_species, "ingest": cmd_ingest, "status": cmd_status}.get(cmd, lambda: print(__doc__))()
