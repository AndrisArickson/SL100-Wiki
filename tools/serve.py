"""Local wiki server: read, edit (wikitext), search, categories, images.   python3 tools/serve.py [port]

Binds to 127.0.0.1 only. Edits are written straight to pages/*.wiki and flagged local_edit=1 so the
crawler will never overwrite them. Previous versions are kept in data/history/.
"""
import html
import json
import mimetypes
import random
import re
import sys
import urllib.parse
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

import common as C
import placeholders
from common import (CFG, DATA_DIR, FULL_IMG_DIR, META_DIR, PAGES_DIR, PLACEHOLDER_DIR, ROOT, db_connect,
                    norm_title, now_iso, page_relpath, title_ns, write_atomic)
from wikitext import Renderer, wiki_href

STATIC = ROOT / "tools" / "static"
HOME_TITLE = "SL100:Main Page"
EXISTS = set()
DIMS = {}


def load_index():
    con = db_connect()
    C.register_untracked(con)
    EXISTS.clear()
    EXISTS.update(r[0] for r in con.execute("SELECT title FROM pages WHERE path IS NOT NULL"))
    DIMS.clear()
    for r in con.execute("SELECT name,width,height FROM imgs WHERE width IS NOT NULL"):
        DIMS[r[0]] = (r[1], r[2])
    con.close()


def img_info(name):
    w, h = DIMS.get(name, (None, None))
    return "/img/" + urllib.parse.quote(name), w, h


def esc(s):
    return html.escape(str(s), quote=True)


def get_page(con, title):
    r = con.execute("SELECT * FROM pages WHERE title=? AND path IS NOT NULL", (title,)).fetchone()
    if not r:
        return None, None
    f = PAGES_DIR / r["path"]
    return r, (f.read_text(encoding="utf-8", errors="replace") if f.exists() else "")


def save_page(con, title, text, summary=""):
    r = con.execute("SELECT * FROM pages WHERE title=?", (title,)).fetchone()
    if r and r["path"]:
        rel = r["path"]
        old = PAGES_DIR / rel
        if old.exists():
            h = DATA_DIR / "history" / re.sub(r"[^\w.-]", "_", rel)
            h.mkdir(parents=True, exist_ok=True)
            (h / (now_iso().replace(":", "") + ".wiki")).write_text(old.read_text(encoding="utf-8", errors="replace"), encoding="utf-8")
    else:
        taken = {x[0].lower() for x in con.execute("SELECT path FROM pages WHERE path IS NOT NULL")}
        ns = title_ns(title)
        if ns == 0 and title.lower().startswith("sl100:"):
            ns = 3000
        rel = page_relpath(title, ns, taken)
    ns = title_ns(title) or (3000 if title.lower().startswith("sl100:") else 0)
    write_atomic(PAGES_DIR / rel, text)
    red = C.redirect_target(text)
    if r:
        con.execute("UPDATE pages SET path=?, local_edit=1, ts=?, bytes=?, redirect_to=?, "
                    "status=CASE WHEN status IN ('ok','redirect') THEN ?  ELSE 'local' END WHERE title=?",
                    (rel, now_iso(), len(text.encode()), red, "redirect" if red else "ok", title))
    else:
        con.execute("INSERT INTO pages(title,ns,status,path,ts,bytes,local_edit,redirect_to,priority) VALUES(?,?,?,?,?,?,1,?,0)",
                    (title, ns, "local", rel, now_iso(), len(text.encode()), red))
    C.record_page_meta(con, title, text)
    con.commit()
    EXISTS.add(title)
    with open(META_DIR / "local_edits.jsonl", "a", encoding="utf-8") as f:
        f.write(json.dumps({"time": now_iso(), "title": title, "summary": summary}) + "\n")


def layout(title, body, q="", tabs="", extra_head=""):
    return """<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width">
<title>%s - Star Legends Wiki</title><link rel="stylesheet" href="/static/style.css">%s</head><body>
<header><a class="logo" href="/">Star Legends<br><small>Galactic Wars - SL100</small></a>
<form action="/search" method="get"><input name="q" value="%s" placeholder="Search titles &amp; text" autofocus><button>Go</button></form></header>
<div class="wrap"><nav>
<h4>Navigate</h4><a href="/">Main page</a><a href="/special/recent">Local edits</a><a href="/random">Random page</a>
<a href="/special/allpages">All pages</a><a href="/special/images">Image list</a><a href="/special/status">Harvest status</a>
<h4>Game (SL100)</h4><a href="/wiki/SL100:Main_Page">SL100 home</a><a href="/edit/SL100:New_page">Create game page</a>
<h4>Reference</h4><a href="/category/Weapons">Weapons</a><a href="/category/Armor">Armor</a><a href="/category/Starships">Starships</a>
<a href="/category/Vehicles">Vehicles</a><a href="/category/Droids">Droids</a><a href="/category/Planets">Planets</a>
</nav><main><div class="tabs">%s</div><h1>%s</h1>%s</main></div></body></html>""" % (
        esc(re.sub(r"<[^>]+>", "", title)), extra_head, esc(q), tabs, title, body)


def attribution(title, rec):
    if not rec or not rec["revid"]:
        return ""
    t = urllib.parse.quote(title.replace(" ", "_"), safe="/:()',!*~@$&+=;-._")
    mod = " (modified locally)" if rec["local_edit"] else ""
    return ('<footer class="attrib">This page is derived from the <a href="%s%s">Wookieepedia article "%s"</a> '
            '(<a href="%s%s?action=history">authors / history</a>, revision %s, %s)%s, text available under '
            '<a href="https://creativecommons.org/licenses/by-sa/3.0/">CC BY-SA 3.0</a>. '
            'Content from Wookieepedia is Star Wars (Legends) material; Star Wars is a trademark of Lucasfilm Ltd.</footer>'
            % (CFG["site"], t, esc(title), CFG["site"], t, rec["revid"], esc(rec["ts"] or ""), mod))


class H(BaseHTTPRequestHandler):
    server_version = "SL100Wiki/1.0"

    def log_message(self, *a):
        pass

    # ---- helpers
    def send(self, body, code=200, ctype="text/html; charset=utf-8", headers=None):
        b = body.encode("utf-8") if isinstance(body, str) else body
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(b)))
        for k, v in (headers or {}).items():
            self.send_header(k, v)
        self.end_headers()
        self.wfile.write(b)

    def redirect(self, url):
        self.send("", 303, headers={"Location": url})

    def local_only(self):
        host = (self.headers.get("Host") or "").split(":")[0]
        return host in ("127.0.0.1", "localhost", "[::1]")

    # ---- routing
    def do_GET(self):
        if not self.local_only():
            return self.send("forbidden", 403, "text/plain")
        u = urllib.parse.urlparse(self.path)
        path = urllib.parse.unquote(u.path)
        qs = urllib.parse.parse_qs(u.query)
        con = db_connect()
        try:
            if path == "/":
                return self.view(con, HOME_TITLE, home=True)
            if path.startswith("/wiki/"):
                return self.view(con, norm_title(path[6:]), redirected=qs.get("from", [""])[0], noredirect="redirect" in qs)
            if path.startswith("/edit/"):
                return self.edit_form(con, norm_title(path[6:]))
            if path.startswith("/raw/"):
                r, text = get_page(con, norm_title(path[5:]))
                return self.send(text or "", 200 if r else 404, "text/plain; charset=utf-8")
            if path == "/search":
                return self.search(con, qs.get("q", [""])[0])
            if path.startswith("/category/"):
                return self.category(con, norm_title(path[10:]), int(qs.get("from", ["0"])[0]))
            if path == "/random":
                r = con.execute("SELECT title FROM pages WHERE status='ok' AND ns=0 ORDER BY RANDOM() LIMIT 1").fetchone()
                return self.redirect(wiki_href(r[0]) if r else "/")
            if path.startswith("/special/"):
                return self.special(con, path[9:], qs)
            if path.startswith("/img/"):
                return self.image(con, path[5:])
            if path.startswith("/static/"):
                f = STATIC / path[8:].replace("..", "")
                if f.is_file():
                    return self.send(f.read_bytes(), 200, mimetypes.guess_type(str(f))[0] or "application/octet-stream")
            return self.send(layout("Not found", "<p>No such route.</p>"), 404)
        finally:
            con.close()

    def do_POST(self):
        if not self.local_only():
            return self.send("forbidden", 403, "text/plain")
        org = self.headers.get("Origin")
        if org and urllib.parse.urlparse(org).hostname not in ("127.0.0.1", "localhost", "::1"):
            return self.send("forbidden", 403, "text/plain")
        path = urllib.parse.unquote(urllib.parse.urlparse(self.path).path)
        n = int(self.headers.get("Content-Length") or 0)
        form = urllib.parse.parse_qs(self.rfile.read(n).decode("utf-8"), keep_blank_values=True)
        if not path.startswith("/edit/"):
            return self.send("bad request", 400, "text/plain")
        title = norm_title(path[6:])
        text = form.get("text", [""])[0].replace("\r\n", "\n")
        con = db_connect()
        try:
            if "save" in form and title:
                save_page(con, title, text, form.get("summary", [""])[0])
                return self.redirect(wiki_href(title))
            return self.edit_form(con, title, text=text, preview=True)
        finally:
            con.close()

    # ---- views
    def render(self, title, text):
        r = Renderer(title, exists=lambda t: t in EXISTS or t.startswith(("File:", "Special:")), img_info=img_info)
        return r.render(text), r

    def view(self, con, title, home=False, redirected="", noredirect=False):
        rec, text = get_page(con, title)
        if rec is None and title.startswith("File:"):
            return self.file_page(con, title[5:])
        if rec is None:
            if home:
                return self.home(con)
            sug = [r[0] for r in con.execute("SELECT title FROM pages WHERE title IN (?,?) AND path IS NOT NULL",
                                              (title + "/Legends", title.replace("/Legends", "")))]
            s = "".join('<li>A Legends version exists: <a href="%s">%s</a></li>' % (wiki_href(x), esc(x)) for x in sug)
            body = ('<p>There is no page called <b>%s</b> in this wiki.</p><ul>%s<li><a href="/edit/%s">Create it</a></li>'
                    '<li><a href="/search?q=%s">Search for it</a></li></ul>' %
                    (esc(title), s, urllib.parse.quote(title.replace(" ", "_")), urllib.parse.quote(title)))
            return self.send(layout(esc(title), body, tabs=self.tabs(title, False)), 404)
        if rec["redirect_to"] and not noredirect and rec["redirect_to"] != title and rec["redirect_to"] in EXISTS:
            return self.redirect(wiki_href(rec["redirect_to"]) + "?from=" + urllib.parse.quote(title))
        body, r = self.render(title, text)
        banner = ('<div class="redirnote">Redirected from <a href="%s?redirect=no">%s</a></div>' % (wiki_href(redirected), esc(redirected))) if redirected else ""
        if rec["local_edit"]:
            banner += '<div class="localnote">This page has local edits and is protected from re-download.</div>'
        cats = "".join('<a href="/category/%s">%s</a>' % (urllib.parse.quote(c.replace(" ", "_")), esc(c)) for c in r.cats)
        body = banner + body + ('<div class="catlinks"><b>Categories:</b> %s</div>' % cats if cats else "") + attribution(title, rec)
        shown = re.sub(r"/Legends$", ' <span class="legends">Legends</span>', esc(title))
        self.send(layout(shown, body, tabs=self.tabs(title, True)))

    def tabs(self, title, exists):
        t = urllib.parse.quote(title.replace(" ", "_"), safe="/:()',!*~@$&+=;-._")
        orig = '<a href="%s%s">Original</a>' % (CFG["site"], t) if not title.lower().startswith("sl100:") else ""
        return ('<a href="/wiki/%s">Read</a><a href="/edit/%s">Edit</a>%s%s' %
                (t, t, '<a href="/raw/%s">Raw</a>' % t if exists else "", orig))

    def edit_form(self, con, title, text=None, preview=False):
        rec, cur = get_page(con, title)
        if text is None:
            text = cur if cur is not None else ("{{SL100 Stub}}\n\n'''%s''' is ...\n\n[[Category:SL100]]\n" % title.split(":")[-1])
        pv = ""
        if preview:
            h, r = self.render(title, text)
            pv = '<div class="preview"><h3>Preview</h3>%s</div>' % h
        body = ('%s<form method="post" action="/edit/%s"><textarea name="text" spellcheck="false">%s</textarea>'
                '<p><input name="summary" placeholder="Edit summary" size="60"> <button name="preview" value="1">Show preview</button> '
                '<button name="save" value="1" class="primary">Save to disk</button></p></form>'
                '<p class="hint">Saved as MediaWiki wikitext in <code>pages/</code>. Prefix game pages with <code>SL100:</code>.</p>' %
                (pv, urllib.parse.quote(title.replace(" ", "_")), esc(text)))
        self.send(layout("Editing " + esc(title), body, tabs=self.tabs(title, rec is not None)))

    def search(self, con, q):
        q = q.strip()
        rows = []
        if q:
            like = "%" + q.replace("%", "").replace("_", "\\_") + "%"
            rows = con.execute("SELECT title, status FROM pages WHERE title LIKE ? ESCAPE '\\' AND path IS NOT NULL "
                               "ORDER BY (title LIKE ? ESCAPE '\\') DESC, length(title) LIMIT 200", (like, q + "%")).fetchall()
            try:
                fts = con.execute("SELECT title FROM fts WHERE fts MATCH ? LIMIT 100", (re.sub(r'[^\w\s]', ' ', q),)).fetchall()
            except Exception:
                fts = []
        else:
            fts = []
        li = "".join('<li><a href="%s">%s</a></li>' % (wiki_href(r[0]), esc(r[0])) for r in rows)
        li2 = "".join('<li><a href="%s">%s</a></li>' % (wiki_href(r[0]), esc(r[0])) for r in fts if r[0] not in {x[0] for x in rows})
        body = "<h3>Title matches (%d)</h3><ul>%s</ul>" % (len(rows), li)
        if li2:
            body += "<h3>Text matches</h3><ul>%s</ul>" % li2
        elif q:
            body += '<p class="hint">Full-text search is available after <code>./wiki.sh fts</code> has been run.</p>'
        self.send(layout("Search", body, q=q))

    def category(self, con, cat, start):
        rows = con.execute("SELECT page FROM cats WHERE cat=? ORDER BY page COLLATE NOCASE LIMIT 501 OFFSET ?", (cat, start)).fetchall()
        li = "".join('<li><a href="%s">%s</a></li>' % (wiki_href(r[0]), esc(r[0])) for r in rows[:500])
        nav = '<p><a href="?from=%d">Next 500 &raquo;</a></p>' % (start + 500) if len(rows) > 500 else ""
        sub = con.execute("SELECT DISTINCT cat FROM cats WHERE cat LIKE ? AND cat!=? LIMIT 40", (cat + "%", cat)).fetchall()
        subs = "".join('<a href="/category/%s">%s</a> ' % (urllib.parse.quote(s[0].replace(" ", "_")), esc(s[0])) for s in sub)
        body = ("<p class='hint'>Only locally harvested pages are listed.</p>%s<ul class='cols'>%s</ul>%s" %
                (("<p><b>Related:</b> %s</p>" % subs) if subs else "", li, nav))
        self.send(layout("Category: " + esc(cat), body))

    def special(self, con, what, qs):
        if what == "status":
            lines = ["<table class='wikitable'><tr><th>Status</th><th>Pages</th></tr>"]
            for r in con.execute("SELECT status,COUNT(*) FROM pages GROUP BY status"):
                lines.append("<tr><td>%s</td><td>%d</td></tr>" % (esc(r[0]), r[1]))
            lines.append("</table><table class='wikitable'><tr><th>Images</th><th></th></tr>")
            for r in con.execute("SELECT status,COUNT(*) FROM imgs GROUP BY status"):
                lines.append("<tr><td>%s</td><td>%d</td></tr>" % (esc(r[0]), r[1]))
            lines.append("</table>")
            return self.send(layout("Harvest status", "".join(lines)))
        if what == "recent":
            rows = con.execute("SELECT title,ts FROM pages WHERE local_edit=1 ORDER BY ts DESC LIMIT 200").fetchall()
            li = "".join('<li>%s - <a href="%s">%s</a></li>' % (esc(r[1]), wiki_href(r[0]), esc(r[0])) for r in rows)
            return self.send(layout("Local edits", "<ul>%s</ul>" % (li or "<li>No local edits yet.</li>")))
        if what == "images":
            start = int(qs.get("from", ["0"])[0])
            rows = con.execute("SELECT * FROM imgs ORDER BY name COLLATE NOCASE LIMIT 301 OFFSET ?", (start,)).fetchall()
            tr = "".join("<tr><td><a href='%s'>%s</a></td><td>%s x %s</td><td>%s</td><td>%s</td></tr>" %
                         (wiki_href("File:" + r["name"]), esc(r["name"]), r["width"], r["height"], r["uses"], r["status"]) for r in rows[:300])
            nxt = "<p><a href='?from=%d'>Next 300 &raquo;</a></p>" % (start + 300) if len(rows) > 300 else ""
            return self.send(layout("Image list", "<p>Images are shown as blank placeholders. Full list: <code>meta/images.tsv</code>.</p>"
                                    "<table class='wikitable'><tr><th>File</th><th>Size</th><th>Used on</th><th>Status</th></tr>%s</table>%s" % (tr, nxt)))
        if what == "allpages":
            start = int(qs.get("from", ["0"])[0])
            rows = con.execute("SELECT title FROM pages WHERE path IS NOT NULL ORDER BY title COLLATE NOCASE LIMIT 501 OFFSET ?", (start,)).fetchall()
            li = "".join('<li><a href="%s">%s</a></li>' % (wiki_href(r[0]), esc(r[0])) for r in rows[:500])
            nxt = "<p><a href='?from=%d'>Next 500 &raquo;</a></p>" % (start + 500) if len(rows) > 500 else ""
            return self.send(layout("All pages", "<ul class='cols'>%s</ul>%s" % (li, nxt)))
        self.send(layout("Not found", ""), 404)

    def home(self, con):
        n = con.execute("SELECT COUNT(*) FROM pages WHERE path IS NOT NULL").fetchone()[0]
        body = ("<p>Welcome to your local <b>Star Legends - Galactic Wars</b> reference wiki. <b>%d</b> pages are stored on disk.</p>"
                "<p>Create <a href='/edit/SL100:Main_Page'>SL100:Main Page</a> to replace this screen with your own front page.</p>"
                "<p>Harvested pages are Wookieepedia (Legends) text, CC BY-SA 3.0. Use the <code>SL100:</code> prefix for game rules, "
                "stats, costs and availability.</p>" % n)
        self.send(layout("Star Legends Wiki", body, tabs=self.tabs(HOME_TITLE, False)))

    def file_page(self, con, name):
        name = norm_title(name)
        r = con.execute("SELECT * FROM imgs WHERE name=?", (name,)).fetchone()
        info = ("<p>%s x %s, %s. <a href='%s'>Original file on Wookieepedia</a> (not downloaded).</p>" %
                (r["width"], r["height"], esc(r["mime"] or ""), esc(r["url"] or "#"))) if r else "<p>Unknown file.</p>"
        used = "".join('<li><a href="%s">%s</a></li>' % (wiki_href(x[0]), esc(x[0])) for x in
                       con.execute("SELECT page FROM imguse WHERE img=? LIMIT 100", (name,)))
        body = '<img class="wimg" src="/img/%s" style="max-width:100%%">%s<h3>Used on</h3><ul>%s</ul>' % (urllib.parse.quote(name), info, used)
        self.send(layout("File:" + esc(name), body))

    def image(self, con, name):
        name = norm_title(name)
        real = FULL_IMG_DIR / placeholders.placeholder_relpath(name).replace(".webp", "")
        if real.is_file():
            return self.send(real.read_bytes(), 200, mimetypes.guess_type(str(real))[0] or "image/jpeg",
                             {"Cache-Control": "max-age=3600"})
        w, h = DIMS.get(name, (None, None))
        p = placeholders.ensure_placeholder(name, w, h)
        self.send(p.read_bytes(), 200, "image/webp", {"Cache-Control": "max-age=3600"})


def main():
    port = int(sys.argv[1]) if len(sys.argv) > 1 else int(CFG["server_port"])
    load_index()
    srv = ThreadingHTTPServer((CFG["server_host"], port), H)
    print("Star Legends wiki running at http://%s:%d/  (%d pages)   Ctrl-C to stop" % (CFG["server_host"], port, len(EXISTS)), flush=True)
    try:
        srv.serve_forever()
    except KeyboardInterrupt:
        pass


if __name__ == "__main__":
    main()
