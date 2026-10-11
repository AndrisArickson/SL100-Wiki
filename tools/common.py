"""Shared helpers for the SL100 wiki tools. Standard library only (Python 3.8+)."""
import gzip
import hashlib
import json
import os
import random
import re
import signal
import sqlite3
import sys
import time
import unicodedata
import urllib.error
import urllib.parse
import urllib.request
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

DEFAULTS = {
    "api": "https://starwars.fandom.com/api.php",
    "site": "https://starwars.fandom.com/wiki/",
    "user_agent": "SL100-Wiki/1.0 (+https://github.com/AndrisArickson/SL100-Wiki; personal non-commercial)",
    "delay_seconds": 2.5, "batch_size": 50, "maxlag": 5, "max_retries": 8, "request_timeout": 60,
    "legends_category": "Category:Legends articles", "support_namespaces": [10, 828],
    "priority_depth": 3, "priority_max_categories_per_root": 250, "priority_roots": {},
    "placeholder_max_px": 640, "placeholder_default_size": [300, 200],
    "placeholder_rgb": [205, 211, 217],
    "server_host": "127.0.0.1", "server_port": 8100,
}


def load_config():
    cfg = dict(DEFAULTS)
    p = ROOT / "config.json"
    if p.exists():
        cfg.update(json.loads(p.read_text(encoding="utf-8")))
    if os.environ.get("SL100_DELAY"):
        cfg["delay_seconds"] = float(os.environ["SL100_DELAY"])
    return cfg


CFG = load_config()
PAGES_DIR = ROOT / "pages"
DATA_DIR = ROOT / "data"
META_DIR = ROOT / "meta"
IMG_DIR = ROOT / "images"
PLACEHOLDER_DIR = IMG_DIR / "placeholders"
FULL_IMG_DIR = IMG_DIR / "full"
for _d in (PAGES_DIR, DATA_DIR, META_DIR, PLACEHOLDER_DIR, DATA_DIR / "logs"):
    _d.mkdir(parents=True, exist_ok=True)

# ---------------------------------------------------------------- namespaces
NS_NAMES = {0: "", 1: "Talk", 2: "User", 4: "Wookieepedia", 6: "File", 8: "MediaWiki",
            10: "Template", 12: "Help", 14: "Category", 828: "Module", 3000: "SL100"}
NS_BY_NAME = {v.lower(): k for k, v in NS_NAMES.items() if v}
NS_BY_NAME.update({"image": 6, "project": 4})


def now_iso():
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def log(*a):
    print(datetime.now().strftime("%Y-%m-%d %H:%M:%S"), *a, flush=True)


def norm_title(t):
    t = unicodedata.normalize("NFC", t.replace("_", " "))
    t = re.sub(r"\s+", " ", t).strip()
    return t[:1].upper() + t[1:] if t else t


def title_ns(title):
    if ":" in title:
        pre = title.split(":", 1)[0].strip().lower()
        if pre in NS_BY_NAME:
            return NS_BY_NAME[pre]
    return 0


# ----------------------------------------------------------- filename mapping
_BAD = set('<>:"/\\|?*%')
_RESERVED = {"CON", "PRN", "AUX", "NUL", *{f"COM{i}" for i in range(1, 10)}, *{f"LPT{i}" for i in range(1, 10)}}


def safe_name(s, maxbytes=180):
    """Reversible-ish, filesystem-safe (exFAT/NTFS/ext4) filename for a title."""
    out = []
    for ch in unicodedata.normalize("NFC", s).replace(" ", "_"):
        if ch in _BAD or ord(ch) < 32:
            out.append("%%%02X" % ord(ch))
        else:
            out.append(ch)
    name = "".join(out).rstrip(". ")
    if name.upper() in _RESERVED:
        name = "%" + name
    if len(name.encode("utf-8")) > maxbytes:
        h = hashlib.sha1(s.encode("utf-8")).hexdigest()[:8]
        name = name.encode("utf-8")[: maxbytes - 10].decode("utf-8", "ignore") + "~" + h
    return name or "_"


def shard(name):
    c = name[:1].upper()
    return c if re.match(r"[A-Z0-9]", c) else "_"


def page_relpath(title, ns, taken_lower=None):
    base = safe_name(title)
    ext = ".lua" if ns == 828 else ".wiki"
    folder = NS_NAMES.get(ns, "") or "Main"
    stem = base
    if ns:
        stem = safe_name(title.split(":", 1)[1]) if ":" in title else base
    rel = "%s/%s/%s%s" % (folder, shard(stem), base, ext)
    if taken_lower is not None and rel.lower() in taken_lower:
        h = hashlib.sha1(title.encode("utf-8")).hexdigest()[:6]
        rel = "%s/%s/%s~%s%s" % (folder, shard(stem), base, h, ext)
    return rel


# ------------------------------------------------------------------ database
SCHEMA = """
CREATE TABLE IF NOT EXISTS pages(
  title TEXT PRIMARY KEY, pageid INTEGER, ns INTEGER DEFAULT 0,
  status TEXT DEFAULT 'listed',      -- listed | ok | redirect | missing | error | local
  priority INTEGER DEFAULT 100, path TEXT, revid INTEGER, ts TEXT, bytes INTEGER,
  local_edit INTEGER DEFAULT 0, fetched_at TEXT, redirect_to TEXT, tries INTEGER DEFAULT 0);
CREATE INDEX IF NOT EXISTS pages_status ON pages(status, priority);
CREATE INDEX IF NOT EXISTS pages_lpath ON pages(path);
CREATE TABLE IF NOT EXISTS cats(page TEXT, cat TEXT, PRIMARY KEY(page, cat));
CREATE INDEX IF NOT EXISTS cats_cat ON cats(cat);
CREATE TABLE IF NOT EXISTS imgs(
  name TEXT PRIMARY KEY, status TEXT DEFAULT 'listed',   -- listed | ok | missing
  width INTEGER, height INTEGER, mime TEXT, size INTEGER, url TEXT,
  uses INTEGER DEFAULT 0, placeholder INTEGER DEFAULT 0);
CREATE TABLE IF NOT EXISTS imguse(page TEXT, img TEXT, PRIMARY KEY(page, img));
CREATE INDEX IF NOT EXISTS imguse_img ON imguse(img);
CREATE TABLE IF NOT EXISTS state(k TEXT PRIMARY KEY, v TEXT);
"""


def _open_db(path):
    con = sqlite3.connect(str(path), timeout=60, check_same_thread=False)
    con.row_factory = sqlite3.Row
    con.executescript(SCHEMA)
    return con


def db_connect():
    """Open the state DB. Journal mode is left at default (WAL needs shared memory that FUSE/exFAT/NTFS lack).
    If the wiki drive cannot do SQLite file locking, fall back to a DB in your home directory."""
    p = CFG.get("db_path") or str(DATA_DIR / "wiki.db")
    try:
        return _open_db(p)
    except sqlite3.OperationalError as e:
        alt = Path.home() / ".local" / "share" / "sl100-wiki" / "wiki.db"
        alt.parent.mkdir(parents=True, exist_ok=True)
        print("WARNING: cannot use %s (%s); using %s instead" % (p, e, alt), file=sys.stderr)
        return _open_db(alt)


def state_get(con, k, default=None):
    r = con.execute("SELECT v FROM state WHERE k=?", (k,)).fetchone()
    return r["v"] if r else default


def state_set(con, k, v):
    con.execute("INSERT OR REPLACE INTO state(k,v) VALUES(?,?)", (k, v))


# ---------------------------------------------------------------- page content
IMG_EXT = r"(?:jpe?g|png|gif|svg|webp|bmp|tiff?|ico)"


def extract_categories(text):
    cats = []
    for m in re.finditer(r"\[\[\s*Category\s*:\s*([^\]|]+)", text, re.I):
        c = norm_title(m.group(1))
        if c and c not in cats:
            cats.append(c)
    return cats


def extract_images(text):
    names = []

    def add(n):
        n = norm_title(n.split("|")[0])
        if n and re.search(r"\." + IMG_EXT + r"$", n, re.I) and n not in names:
            names.append(n)

    for m in re.finditer(r"\[\[\s*(?:File|Image)\s*:\s*([^|\]\n]+)", text, re.I):
        add(m.group(1))
    for g in re.finditer(r"<gallery[^>]*>(.*?)</gallery>", text, re.I | re.S):
        for line in g.group(1).splitlines():
            line = re.sub(r"^\s*(?:File|Image)\s*:\s*", "", line.strip(), flags=re.I)
            if line:
                add(line)
    for m in re.finditer(r"\|\s*[\w ]*?(?:image|img|file|icon|logo|map|portrait|photo|picture)[\w ]*=\s*"
                         r"(?:\[\[(?:File|Image):)?\s*([^|\n\]}]+?\." + IMG_EXT + r")", text, re.I):
        add(m.group(1))
    return names


def redirect_target(text):
    m = re.match(r"\s*#redirect\s*:?\s*\[\[([^\]|#]+)", text, re.I)
    return norm_title(m.group(1)) if m else None


def write_atomic(path, data):
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_name(path.name + ".tmp")
    tmp.write_text(data, encoding="utf-8", newline="\n")
    os.replace(tmp, path)


def record_page_meta(con, title, text):
    """Refresh categories / image usage rows for a page from its wikitext."""
    con.execute("DELETE FROM cats WHERE page=?", (title,))
    con.executemany("INSERT OR IGNORE INTO cats(page,cat) VALUES(?,?)",
                    [(title, c) for c in extract_categories(text)])
    old = [r[0] for r in con.execute("SELECT img FROM imguse WHERE page=?", (title,))]
    con.execute("DELETE FROM imguse WHERE page=?", (title,))
    new = extract_images(text)
    for n in new:
        con.execute("INSERT OR IGNORE INTO imgs(name) VALUES(?)", (n,))
        con.execute("INSERT OR IGNORE INTO imguse(page,img) VALUES(?,?)", (title, n))
    for n in set(old) | set(new):
        con.execute("UPDATE imgs SET uses=(SELECT COUNT(*) FROM imguse WHERE img=?) WHERE name=?", (n, n))


# ------------------------------------------------------------------- API client
STOP = False


def _on_signal(signum, frame):
    global STOP
    STOP = True
    log("Stop requested - finishing the current batch then exiting cleanly.")


def install_signal_handlers():
    signal.signal(signal.SIGINT, _on_signal)
    signal.signal(signal.SIGTERM, _on_signal)


def should_stop():
    return STOP or (DATA_DIR / "STOP").exists()


class ApiError(Exception):
    pass


_last_request = [0.0]


def _throttle():
    delay = float(CFG["delay_seconds"])
    wait = _last_request[0] + delay + random.uniform(0, delay * 0.25) - time.time()
    if wait > 0:
        time.sleep(wait)
    _last_request[0] = time.time()


def api(**params):
    """One polite, throttled MediaWiki API call with retry/backoff. Returns parsed JSON."""
    params.update(format="json", formatversion="2", maxlag=str(CFG["maxlag"]))
    data = urllib.parse.urlencode(params).encode()
    headers = {"User-Agent": CFG["user_agent"], "Accept-Encoding": "gzip",
               "Content-Type": "application/x-www-form-urlencoded"}
    last = None
    for attempt in range(int(CFG["max_retries"])):
        if should_stop() and attempt:
            raise ApiError("stopped")
        _throttle()
        try:
            req = urllib.request.Request(CFG["api"], data=data, headers=headers)
            with urllib.request.urlopen(req, timeout=CFG["request_timeout"]) as r:
                raw = r.read()
                if r.headers.get("Content-Encoding") == "gzip":
                    raw = gzip.decompress(raw)
            js = json.loads(raw.decode("utf-8"))
            if "error" in js:
                code = js["error"].get("code", "")
                if code in ("maxlag", "ratelimited"):
                    wait = 15 * (attempt + 1)
                    log("API says %s; sleeping %ss" % (code, wait))
                    time.sleep(wait)
                    last = code
                    continue
                raise ApiError("%s: %s" % (code, js["error"].get("info", "")))
            return js
        except urllib.error.HTTPError as e:
            last = "HTTP %s" % e.code
            ra = e.headers.get("Retry-After") if e.headers else None
            wait = int(ra) if ra and ra.isdigit() else min(900, 20 * 2 ** attempt)
            if e.code == 403:
                wait = max(wait, 300)
            log("%s - backing off %ss (attempt %d)" % (last, wait, attempt + 1))
            time.sleep(wait)
        except (urllib.error.URLError, TimeoutError, ConnectionError, json.JSONDecodeError, OSError) as e:
            last = repr(e)
            wait = min(600, 10 * 2 ** attempt)
            log("Network problem %s - retrying in %ss" % (last, wait))
            time.sleep(wait)
    raise ApiError("gave up after retries: %s" % last)


def chunks(seq, n):
    for i in range(0, len(seq), n):
        yield seq[i:i + n]


def register_untracked(con):
    """Add .wiki files that exist on disk but are unknown to the DB (hand-made pages, a fresh clone)."""
    known = {r[0].lower() for r in con.execute("SELECT path FROM pages WHERE path IS NOT NULL")}
    added = 0
    for f in PAGES_DIR.rglob("*.wiki"):
        rel = f.relative_to(PAGES_DIR).as_posix()
        if rel.lower() in known:
            continue
        stem = urllib.parse.unquote(f.stem).split("~")[0] if "~" in f.stem and len(f.stem.rsplit("~", 1)[1]) <= 8 else urllib.parse.unquote(f.stem)
        title = norm_title(stem)
        ns = title_ns(title) or (3000 if title.lower().startswith("sl100:") else 0)
        if con.execute("SELECT 1 FROM pages WHERE title=?", (title,)).fetchone():
            continue
        text = f.read_text(encoding="utf-8", errors="replace")
        con.execute("INSERT INTO pages(title,ns,status,path,ts,bytes,local_edit,priority,redirect_to) VALUES(?,?,?,?,?,?,1,0,?)",
                    (title, ns, "local", rel, now_iso(), len(text.encode()), redirect_target(text)))
        record_page_meta(con, title, text)
        added += 1
    con.commit()
    return added
