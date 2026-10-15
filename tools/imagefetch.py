"""Download or upload one image into the wiki, for reviewers (the "Images on this page" panel).

    info(name)              the Wookieepedia file details: original URL, size, type, licence, author, file page
    download(name)          fetch it from Wookieepedia as WebP (max 800 px wide) into images/full/
    save_upload(name, data) store an image the reviewer saved by hand (WebP, or any picture when Pillow is installed)

Wookieepedia's image server (Fandom's) returns WebP when asked with format=webp; anything else is converted with
Pillow when it is installed, and refused otherwise. The file lands where the wiki serves it from, and the caller
records it as a draft (tools/review.py) so it can be submitted to GitHub with the reviewer's other changes.
"""
import json
import os
import re
import urllib.error
import urllib.parse
import urllib.request

import common as C
import placeholders

MAX_W = int(C.CFG.get("image_max_width", 800))
API = os.environ.get("SL100_WOOKIEEPEDIA_API") or C.CFG["api"]
TIMEOUT = 45


class ImageError(Exception):
    pass


def is_webp(data):
    return data[:4] == b"RIFF" and data[8:12] == b"WEBP"


def repo_path(name):
    """Where the wiki serves this image from, relative to the repository root."""
    return "images/full/" + placeholders.placeholder_relpath(name)


def file_page_url(name):
    return C.CFG["site"] + urllib.parse.quote("File:" + name.replace(" ", "_"))


def _get(url):
    req = urllib.request.Request(url, headers={"User-Agent": C.CFG["user_agent"]})
    try:
        with urllib.request.urlopen(req, timeout=TIMEOUT) as r:
            return r.read(), r.headers.get("Content-Type", "")
    except urllib.error.HTTPError as e:
        raise ImageError("Wookieepedia answered %s for %s" % (e.code, url))
    except (urllib.error.URLError, OSError) as e:
        raise ImageError("could not reach Wookieepedia (%s)" % getattr(e, "reason", e))


def info(name):
    q = urllib.parse.urlencode({"action": "query", "titles": "File:" + name, "prop": "imageinfo", "format": "json",
                                "formatversion": "2", "iiprop": "url|size|mime|extmetadata",
                                "iiextmetadatafilter": "Artist|LicenseShortName|Credit"})
    raw, _ = _get(API + "?" + q)
    try:
        pages = json.loads(raw.decode("utf-8")).get("query", {}).get("pages", [])
    except ValueError:
        raise ImageError("Wookieepedia sent an unreadable answer")
    ii = ((pages[0] if pages else {}).get("imageinfo") or [None])[0]
    if not ii:
        raise ImageError("Wookieepedia has no file called %s" % name)
    md = ii.get("extmetadata") or {}
    val = lambda k: re.sub(r"\s+", " ", re.sub(r"<[^>]+>", "", str((md.get(k) or {}).get("value", "")))).strip()
    return {"url": ii.get("url", ""), "descurl": ii.get("descriptionurl") or file_page_url(name),
            "width": ii.get("width"), "height": ii.get("height"), "mime": ii.get("mime", ""), "bytes": ii.get("size"),
            "licence": val("LicenseShortName"), "artist": val("Artist"), "credit": val("Credit")}


def webp_url(url, width):
    """Ask Fandom's image server for a WebP copy, scaled down to MAX_W when the original is wider."""
    base, _, query = url.partition("?")
    if width and width > MAX_W and "/revision/latest" in base and "scale-to-width" not in base:
        base = base.replace("/revision/latest", "/revision/latest/scale-to-width-down/%d" % MAX_W, 1)
    params = urllib.parse.parse_qsl(query)
    params = [(k, v) for k, v in params if k != "format"] + [("format", "webp")]
    return base + "?" + urllib.parse.urlencode(params)


def to_webp(data):
    if is_webp(data):
        return data
    from images import to_webp as convert           # uses Pillow
    try:
        return convert(data)
    except ImportError:
        raise ImageError("the picture is not WebP and Pillow (pip install pillow) is not installed to convert it")
    except Exception as e:  # noqa: BLE001 - Pillow raises many kinds
        raise ImageError("not a picture the wiki can use (%s)" % e)


def _store(name, data):
    path = repo_path(name)
    f = C.ROOT / path
    f.parent.mkdir(parents=True, exist_ok=True)
    tmp = f.with_suffix(".tmp")
    tmp.write_bytes(data)
    tmp.replace(f)
    return path


def _mark(name, meta, path, size):
    """Keep the licence record (imglic, used by the image review and attribution files) in step, when it exists."""
    try:
        con = C.db_connect()
        con.execute("CREATE TABLE IF NOT EXISTS imglic(name TEXT PRIMARY KEY, bucket TEXT, licence TEXT, artist TEXT, "
                    "credit TEXT, cats TEXT, descurl TEXT, srcurl TEXT, ow INTEGER, oh INTEGER, obytes INTEGER, "
                    "status TEXT DEFAULT 'classified', path TEXT, bytes INTEGER, fetched_at TEXT, q_score INTEGER, "
                    "q_flags TEXT, dhash TEXT, sharp REAL, review TEXT, reviewed_at TEXT)")
        con.execute("INSERT OR IGNORE INTO imglic(name) VALUES(?)", (name,))
        con.execute("UPDATE imglic SET status='ok', path=?, bytes=?, fetched_at=?, licence=COALESCE(NULLIF(?,''),licence), "
                    "artist=COALESCE(NULLIF(?,''),artist), credit=COALESCE(NULLIF(?,''),credit), "
                    "descurl=COALESCE(NULLIF(?,''),descurl), srcurl=COALESCE(NULLIF(?,''),srcurl) WHERE name=?",
                    (path, size, C.now_iso(), meta.get("licence", ""), meta.get("artist", ""), meta.get("credit", ""),
                     meta.get("descurl", ""), meta.get("url", ""), name))
        con.commit()
        con.close()
    except Exception:  # noqa: BLE001 - the image is saved either way
        pass


def download(name):
    """Fetch the image from Wookieepedia as WebP and save it. Returns (repository path, size in bytes, details)."""
    meta = info(name)
    if not meta["url"]:
        raise ImageError("Wookieepedia lists no file to download for %s" % name)
    data, _ = _get(webp_url(meta["url"], meta.get("width")))
    data = to_webp(data)
    path = _store(name, data)
    _mark(name, meta, path, len(data))
    return path, len(data), meta


def save_upload(name, data):
    """Save a picture the reviewer downloaded by hand. Returns (repository path, size in bytes)."""
    if not data:
        raise ImageError("no file was uploaded")
    data = to_webp(data)
    path = _store(name, data)
    _mark(name, {}, path, len(data))
    return path, len(data)
