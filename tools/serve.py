"""Local wiki server: read, edit (wikitext), search, categories, images.   python3 tools/serve.py [port]

Binds to 127.0.0.1 only. Edits are written straight to pages/*.wiki and flagged local_edit=1 so the
crawler will never overwrite them. Previous versions are kept in data/history/.
Every edit is also a draft (tools/review.py): the page is flagged until the draft is submitted to GitHub as a pull
request from the Review changes page, or discarded.
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
import review
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


def img_version(name):
    """Last-modified time of the file /img/<name> will serve, so a replaced picture gets a new URL and no browser
    keeps showing the old one from its cache."""
    rel = placeholders.placeholder_relpath(name)
    for real in (FULL_IMG_DIR / rel.replace(".webp", ""), FULL_IMG_DIR / rel, ROOT / "images" / "local" / rel):
        try:
            return int(real.stat().st_mtime)
        except OSError:
            continue
    return 0


def img_info(name):
    w, h = DIMS.get(name, (None, None))
    v = img_version(name)
    return "/img/" + urllib.parse.quote(name) + ("?v=%d" % v if v else ""), w, h


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
<title>%s - Star Legends Wiki</title><link rel="stylesheet" href="/static/style.css">%s
<script>try{if(localStorage.getItem("sl-review")==="1")document.documentElement.classList.add("show-review")}catch(e){}
function slToggleReview(){var on=document.documentElement.classList.toggle("show-review");try{localStorage.setItem("sl-review",on?"1":"0")}catch(e){}
document.querySelectorAll(".sl-review-toggle").forEach(function(b){b.textContent=(on?"Hide":"Show")+" review notes ("+b.dataset.n+")"})}</script></head><body>
<header><a class="logo" href="/">Star Legends<br><small>Galactic Wars - SL100</small></a>
<form action="/search" method="get"><input name="q" value="%s" placeholder="Search titles &amp; text" autofocus><button>Go</button></form></header>
<div class="wrap"><nav>
<h4>Navigate</h4><a href="/">Main page</a><a href="/review">Review changes%s</a><a href="/review/settings">Reviewer settings</a><a href="/special/recent">Local edits</a><a href="/random">Random page</a>
<a href="/special/allpages">All pages</a><a href="/special/images">Image list</a><a href="/special/status">Harvest status</a>
<h4>Game (SL100)</h4><a href="/wiki/SL100:Main_Page">SL100 home</a><a href="/wiki/SL100:Characteristics#CREATING_A_CHARACTER">Character creation</a><a href="/books">Source books (d20)</a><a href="/match-review">Match review</a><a href="/image-review">Image review</a><a href="/edit/SL100:New_page">Create game page</a>
<h4>Reference</h4><a href="/category/Weapons">Weapons</a><a href="/category/Armor">Armor</a><a href="/category/Starships">Starships</a>
<a href="/category/Vehicles">Vehicles</a><a href="/category/Droids">Droids</a><a href="/category/Planets">Planets</a>
</nav><main><div class="tabs">%s</div><h1>%s</h1>%s</main></div></body></html>""" % (
        esc(re.sub(r"<[^>]+>", "", title)), extra_head, esc(q), draft_count(), tabs, title, body)


def draft_count():
    n = len(review.drafts())
    return " (%d)" % n if n else ""


def mark_review_notes(body):
    """Reviewer notes, written `[review: ...]` in the page, are hidden until the reader asks for them."""
    body, n = re.subn(r"<code>(\[review\b[^<]*\])</code>", r'<span class="sl-review">\1</span>', body)
    if n:
        body = ('<button type="button" class="sl-review-toggle" data-n="%d" onclick="slToggleReview()">Show review notes (%d)</button>'
                '<script>if(document.documentElement.classList.contains("show-review"))document.currentScript.previousSibling.textContent="Hide review notes (%d)"</script>'
                % (n, n, n)) + body
    return body


def discard_draft(title):
    """Throw a draft away: the page goes back to the pulled version, and a page the draft created is removed."""
    if not review.discard(title):
        return
    con = db_connect()
    try:
        r = con.execute("SELECT path FROM pages WHERE title=?", (title,)).fetchone()
        if r and r[0] and not (PAGES_DIR / r[0]).exists():
            con.execute("UPDATE pages SET path=NULL WHERE title=?", (title,))
            con.commit()
    finally:
        con.close()
    load_index()


def draft_banner(title):
    rec = review.drafts().get(title)
    if not rec:
        return ""
    t = urllib.parse.quote(title.replace(" ", "_"))
    who = ", ".join(rec["editors"]) or "you"
    if rec["state"] == "submitted":
        return ('<div class="draftnote submitted"><b>Submitted for approval</b> by %s on %s. '
                '<a href="%s">See the pull request</a>. It goes live for everyone once it is approved and merged.</div>'
                % (esc(who), esc(rec["last"][:16].replace("T", " ")), esc(rec["pr"])))
    return ('<div class="draftnote"><b>Edited - not yet submitted</b> (by %s, %s). '
            '<a href="/review/diff/%s">See changes</a> &middot; <a href="/review">Review and submit</a> &middot; '
            '<form method="post" action="/review/discard" style="display:inline"><input type="hidden" name="title" value="%s">'
            '<button class="linkish" onclick="return confirm(\'Throw away the changes to this page?\')">Discard</button></form></div>'
            % (esc(who), esc(rec["last"][:16].replace("T", " ")), t, esc(title)))


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
            if path in ("/wiki/Special:Review", "/review"):
                return self.review_page(qs)
            if path.startswith("/review/diff/"):
                return self.review_diff(norm_title(path[13:]))
            if path == "/review/settings":
                return self.review_settings()
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
            if path == "/match-review":
                return self.match_review(qs)
            if path == "/image-review":
                return self.image_review(con, qs)
            if path == "/books" or path.startswith("/books/"):
                return self.books(path[7:].strip("/"), qs)
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
        if path == "/match-review":
            return self.match_review_save(form)
        if path == "/image-review":
            return self.image_review_save(form)
        if path.startswith("/review"):
            return self.review_post(path, form)
        if not path.startswith("/edit/"):
            return self.send("bad request", 400, "text/plain")
        title = norm_title(path[6:])
        text = form.get("text", [""])[0].replace("\r\n", "\n")
        con = db_connect()
        try:
            if "save" in form and title:
                summary = form.get("summary", [""])[0].strip()
                editor = form.get("editor", [""])[0].strip()
                if editor and editor != review.settings()["name"]:
                    review.save_settings({"name": editor})
                save_page(con, title, text, summary)
                rel = con.execute("SELECT path FROM pages WHERE title=?", (title,)).fetchone()[0]
                review.record_edit(title, rel, editor, summary)
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
        banner += draft_banner(title)
        if rec["local_edit"] and not title.lower().startswith("sl100:"):
            banner += '<div class="localnote">This page has local edits and is protected from re-download.</div>'
        body = mark_review_notes(body)
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
        name = review.settings()["name"]
        body = ('%s<form method="post" action="/edit/%s"><textarea name="text" spellcheck="false">%s</textarea>'
                '<p><input name="editor" placeholder="Your name" size="18" value="%s" required> '
                '<input name="summary" placeholder="What did you change, and why?" size="50"> '
                '<button name="preview" value="1">Show preview</button> '
                '<button name="save" value="1" class="primary">Save draft</button></p></form>'
                '<p class="hint">Saving keeps your change as a <b>draft</b> on this computer: the page shows it straight away, '
                'flagged as edited. Send your drafts for approval from <a href="/review">Review changes</a>. '
                'To leave a note for reviewers, write <code>`[review: your note]`</code> in the text; such notes stay hidden '
                'until a reader presses "Show review notes". Prefix new game pages with <code>SL100:</code>.</p>' %
                (pv, urllib.parse.quote(title.replace(" ", "_")), esc(text), esc(name)))
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

    # ---- reviewer workflow (tools/review.py)
    def review_page(self, qs, message="", error=""):
        d = review.drafts()
        s = review.settings()
        note = ('<div class="draftnote submitted">%s</div>' % message if message else "") + \
               ('<div class="draftnote error">%s</div>' % esc(error) if error else "")
        if not d:
            return self.send(layout("Review changes", note + "<p>You have no drafts. Edit a page and save it to start one.</p>"))
        rows = []
        for title, rec in sorted(d.items(), key=lambda x: x[1]["last"], reverse=True):
            t = urllib.parse.quote(title.replace(" ", "_"))
            state = ('submitted - <a href="%s">pull request</a>' % esc(rec["pr"])) if rec["state"] == "submitted" else "not yet submitted"
            rows.append('<tr><td><input type="checkbox" name="title" value="%s"%s></td><td><a href="%s">%s</a></td>'
                        '<td>%s</td><td>%s</td><td>%s</td><td><a href="/review/diff/%s">changes</a></td></tr>' %
                        (esc(title), "" if rec["state"] == "submitted" else " checked", wiki_href(title), esc(title),
                         esc(", ".join(rec["editors"])), esc("; ".join(rec["summaries"]) or "-"), state, t))
        warn = "" if s["token"] else ('<p class="hint">Add your GitHub token under <a href="/review/settings">Reviewer settings</a> '
                                      'before submitting.</p>')
        default_title = "Wiki edits by %s" % (s["name"] or "a reviewer")
        body = (note + '<p>Drafts saved on this computer. Tick the ones to send, give them a title, and submit: they go to '
                'GitHub as one pull request, which the project owner approves and merges. Until then only you see them.</p>'
                '<form method="post" action="/review/submit"><table class="wikitable"><tr><th></th><th>Page</th><th>Edited by</th>'
                '<th>Summary</th><th>State</th><th></th></tr>%s</table>'
                '<p><input name="pr_title" size="60" value="%s" required></p>'
                '<p><textarea name="description" rows="4" placeholder="Anything the approver should know (optional)"></textarea></p>'
                '<p><button class="primary" name="submit" value="1">Submit for approval</button> '
                '<button name="discard" value="1" onclick="return confirm(\'Throw away the ticked drafts?\')">Discard ticked</button></p>'
                '</form>%s' % ("".join(rows), esc(default_title), warn))
        self.send(layout("Review changes", body))

    def review_diff(self, title):
        body = ('<p>Changes to <a href="%s">%s</a> compared with the version you last pulled. '
                '<span class="d-add">Added lines</span> and <span class="d-del">removed lines</span> are marked.</p>%s'
                '<p><a href="/review">Back to Review changes</a></p>' % (wiki_href(title), esc(title), review.diff_html(title)))
        self.send(layout("Changes: " + esc(title), body))

    def review_settings(self, saved=False):
        s = review.settings()
        body = (('<div class="draftnote submitted">Saved.</div>' if saved else "") +
                '<form method="post" action="/review/settings"><table class="wikitable">'
                '<tr><td>Your name</td><td><input name="name" value="%s" size="30"></td></tr>'
                '<tr><td>GitHub token</td><td><input name="token" type="password" size="44" placeholder="%s"> '
                '<label><input type="checkbox" name="forget_token" value="1"> forget the saved token</label></td></tr>'
                '<tr><td>Repository</td><td><input name="repo" value="%s" size="30"></td></tr>'
                '<tr><td>Branch to submit to</td><td><input name="base" value="%s" size="12"></td></tr>'
                '<tr><td>Your fork</td><td><input name="fork" value="%s" size="30" placeholder="only if you cannot push to the repository"></td></tr>'
                '</table><p><button class="primary">Save</button></p></form>'
                '<p class="hint">The token is kept in <code>data/reviewer.json</code> on this computer only (data/ is never committed). '
                'Create one on GitHub under Settings, Developer settings, Fine-grained tokens, for the SL100-Wiki repository with '
                '<b>Contents: read and write</b> and <b>Pull requests: read and write</b>. Reviewers the owner has added as '
                'collaborators submit straight to the repository; anyone else forks it on GitHub and enters the fork here.</p>'
                % (esc(s["name"]), "saved - leave empty to keep it" if s["token"] else "paste a token", esc(s["repo"]),
                   esc(s["base"]), esc(s["fork"])))
        self.send(layout("Reviewer settings", body))

    def review_post(self, path, form):
        first = {k: v[0] for k, v in form.items()}
        if path == "/review/settings":
            review.save_settings(first)
            return self.review_settings(saved=True)
        if path == "/review/discard":
            discard_draft(first.get("title", ""))
            return self.redirect(wiki_href(first.get("title", "")) if first.get("title") else "/review")
        if path == "/review/submit":
            titles = form.get("title", [])
            if "discard" in form:
                for t in titles:
                    discard_draft(t)
                return self.review_page({}, message="Discarded %d draft(s)." % len(titles))
            try:
                url = review.submit(titles, first.get("pr_title", "Wiki edits").strip() or "Wiki edits", first.get("description", ""))
            except review.GitHubError as e:
                return self.review_page({}, error="Not submitted: %s" % e)
            return self.review_page({}, message='Submitted. <a href="%s">Open the pull request</a>; the pages go live for '
                                                'everyone once the owner approves and merges it.' % esc(url))
        return self.send("bad request", 400, "text/plain")

    def home(self, con):
        n = con.execute("SELECT COUNT(*) FROM pages WHERE path IS NOT NULL").fetchone()[0]
        body = ("<p>Welcome to your local <b>Star Legends - Galactic Wars</b> reference wiki. <b>%d</b> pages are stored on disk.</p>"
                "<p>Create <a href='/edit/SL100:Main_Page'>SL100:Main Page</a> to replace this screen with your own front page.</p>"
                "<p>Harvested pages are Wookieepedia (Legends) text, CC BY-SA 3.0. Use the <code>SL100:</code> prefix for game rules, "
                "stats, costs and availability.</p>" % n)
        self.send(layout("Star Legends Wiki", body, tabs=self.tabs(HOME_TITLE, False)))

    # ---- image quality review: contact sheets, worst first; one click decides a whole page
    def image_review(self, con, qs):
        try:
            con.execute("SELECT 1 FROM imglic LIMIT 1")
        except Exception:
            return self.send(layout("Image review", "<p>No images yet: run <code>./wiki.sh images-fetch</code> then <code>./wiki.sh images-qc</code>.</p>"))
        g = lambda k, d: (qs.get(k, [d])[0] or d)
        bucket, show, maxs = g("bucket", "all"), g("show", "todo"), int(g("max", "100"))
        per = int(g("per", "120"))
        w = ["status='ok'", "q_score IS NOT NULL", "q_score <= %d" % maxs]
        if bucket != "all":
            w.append("bucket='%s'" % bucket.replace("'", ""))
        if show == "todo":
            w.append("review IS NULL")
        elif show == "replace":
            w.append("review='replace'")
        where = " AND ".join(w)
        total = con.execute("SELECT COUNT(*) FROM imglic WHERE " + where).fetchone()[0]
        rows = con.execute("SELECT name,q_score,q_flags,bucket,review FROM imglic WHERE %s ORDER BY q_score, name LIMIT %d" % (where, per)).fetchall()
        stats = con.execute("SELECT COUNT(*), SUM(review='ok'), SUM(review='replace'), SUM(review IS NULL) FROM imglic WHERE status='ok' AND q_score IS NOT NULL").fetchone()
        tiles = "".join(
            '<label class="ir-tile%s" title="%s"><input type="checkbox" name="replace" value="%s"%s><img src="/img/%s" loading="lazy">'
            '<span>%s &middot; %d &middot; %s</span><a href="/wiki/File:%s" target="_blank">open</a></label>' %
            (" ir-rep" if r[4] == "replace" else "", esc(r[2] or ""), esc(r[0]), " checked" if r[4] == "replace" else "", urllib.parse.quote(r[0]),
             esc(r[0][:28]), r[1], esc(r[3]), urllib.parse.quote(r[0].replace(" ", "_"))) for r in rows)
        hidden = "".join('<input type="hidden" name="page" value="%s">' % esc(r[0]) for r in rows)
        filt = ('<form method="get" action="/image-review" class="ir-filter">Licence <select name="bucket">%s</select> '
                'Show <select name="show">%s</select> Score up to <input name="max" size="3" value="%d"> Per page <input name="per" size="3" value="%d"> '
                '<button>Filter</button></form>' %
                ("".join('<option%s>%s</option>' % (" selected" if bucket == b else "", b) for b in ("all", "free", "fair", "untagged")),
                 "".join('<option value="%s"%s>%s</option>' % (v, " selected" if show == v else "", t) for v, t in
                         (("todo", "not yet reviewed"), ("replace", "marked for replacement"), ("all", "everything"))), maxs, per))
        auto = ('<form method="post" action="/image-review" style="display:inline"><input type="hidden" name="action" value="auto">'
                'Approve every unreviewed image scoring at least <input name="min" size="3" value="70"> <button>Auto-approve</button></form>')
        body = ('<p>%d scored &middot; %d approved &middot; %d marked for replacement &middot; %d to review. This view: %d images, worst first.</p>%s<p>%s</p>'
                '<form method="post" action="/image-review"><input type="hidden" name="action" value="page">%s'
                '<p><b>Tick the images that need replacing</b>, then one click: <button>Save page: ticked = replace, rest = OK</button></p>'
                '<div class="ir-grid">%s</div><p><button>Save page: ticked = replace, rest = OK</button></p></form>' %
                (stats[0], stats[1] or 0, stats[2] or 0, stats[3] or 0, total, filt, auto, hidden, tiles or "<p><i>Nothing left in this view.</i></p>"))
        self.send(layout("Image review", body))

    def image_review_save(self, form):
        con = db_connect()
        try:
            now = now_iso()
            if (form.get("action", [""])[0]) == "auto":
                mn = int(form.get("min", ["70"])[0] or 70)
                con.execute("UPDATE imglic SET review='ok', reviewed_at=? WHERE status='ok' AND review IS NULL AND q_score >= ?", (now, mn))
            else:
                rep = set(form.get("replace", []))
                for n in form.get("page", []):
                    con.execute("UPDATE imglic SET review=?, reviewed_at=? WHERE name=?", ("replace" if n in rep else "ok", now, n))
            con.commit()
        finally:
            con.close()
        self.redirect(self.headers.get("Referer") or "/image-review")

    # ---- d20 item -> Legends article review (Source_Text/tables/wiki_match.csv; choices saved beside it)
    def _mr_files(self):
        base = ROOT.parent / "Source_Text" / "tables"
        return base / "wiki_match.csv", base / "wiki_match_choices.csv"

    def _mr_choices(self):
        import csv
        _, cf = self._mr_files()
        if not cf.exists():
            return {}
        return {(r["source_file"], r["name"]): r["chosen"] for r in csv.DictReader(open(cf, encoding="utf-8"))}

    def match_review(self, qs):
        import csv
        mf, _ = self._mr_files()
        if not mf.exists():
            return self.send(layout("Match review", "<p>Run <code>./wiki.sh collate</code> first.</p>"))
        show = qs.get("show", ["open"])[0]
        ch = self._mr_choices()
        rows = [r for r in csv.DictReader(open(mf, encoding="utf-8")) if r["match"] in ("words", "multi", "generic", "none")]
        if show == "open":
            rows = [r for r in rows if (r["source_file"], r["name"]) not in ch and r["match"] != "none"]
        elif show == "none":
            rows = [r for r in rows if r["match"] == "none" and (r["source_file"], r["name"]) not in ch]
        out = []
        for r in rows:
            key = (r["source_file"], r["name"])
            opts = [t for t in ([r["wiki_title"]] if r["wiki_title"] else []) + [c.strip() for c in r["candidates"].split("|") if c.strip()]]
            btn = "".join('<button name="chosen" value="%s">%s</button> <a href="%s" target="_blank" title="open article">&#8599;</a> ' %
                          (esc(t), esc(t.replace("/Legends", "")), wiki_href(t)) for t in dict.fromkeys(opts))
            done = ch.get(key)
            out.append('<tr><td><b>%s</b><br><small>%s p.%s, %s</small></td><td>%s</td><td><form method="post" action="/match-review">'
                       '<input type="hidden" name="source_file" value="%s"><input type="hidden" name="name" value="%s">%s'
                       '<input name="other" size="22" placeholder="other article title"> <button name="chosen" value="__other">Use</button> '
                       '<button name="chosen" value="-">No article</button>%s</form></td></tr>' %
                       (esc(r["name"]), esc(r["book"][3:30]), esc(r["page"]), esc(r["kind"]), esc(r["match"]), esc(r["source_file"]), esc(r["name"]), btn,
                        (" <i>chosen: %s</i>" % esc(done)) if done else ""))
        nav = ('<p>Show: <a href="?show=open">to review (%s)</a> | <a href="?show=none">no match found</a> | <a href="?show=all">all</a>. '
               'Choices are saved in <code>Source_Text/tables/wiki_match_choices.csv</code> and applied the next time '
               '<code>./wiki.sh collate</code> runs.</p>' % ("this list" if show == "open" else "unreviewed"))
        self.send(layout("Match review: d20 items to Legends articles", nav + "<table class='wikitable'><tr><th>d20 item</th><th>how matched</th>"
                         "<th>pick the Legends article</th></tr>%s</table>" % "".join(out)))

    def match_review_save(self, form):
        import csv
        _, cf = self._mr_files()
        f = lambda k: (form.get(k, [""])[0] or "").strip()
        chosen = f("other") if f("chosen") == "__other" else f("chosen")
        if chosen and chosen != "-":
            chosen = norm_title(chosen)
        ch = self._mr_choices()
        if f("source_file") and f("name") and chosen:
            ch[(f("source_file"), f("name"))] = chosen
            with open(cf, "w", newline="", encoding="utf-8") as fh:
                w = csv.writer(fh)
                w.writerow(["source_file", "name", "chosen"])
                for (a, b), c in sorted(ch.items()):
                    w.writerow([a, b, c])
        self.redirect(self.headers.get("Referer") or "/match-review")

    # ---- private d20 source-book browser (reads ../Source_Text; local only, never part of the wiki or git)
    def books(self, slug, qs):
        base = ROOT.parent / "Source_Text"
        q = (qs.get("q", [""])[0] or "").strip()
        books = sorted(d for d in base.glob("SW_*") if (d / "pages").is_dir())
        if not slug:
            hits = ""
            if q:
                rx = re.compile(re.escape(q), re.I)
                found = []
                for d in books:
                    for f in sorted((d / "pages").glob("*.txt")):
                        t = f.read_text(encoding="utf-8", errors="replace")
                        m = rx.search(t)
                        if m:
                            found.append((d.name, int(f.stem), t[max(0, m.start() - 80):m.end() + 80]))
                            if len(found) >= 200:
                                break
                    if len(found) >= 200:
                        break
                hits = "<h3>%d hits for <i>%s</i>%s</h3><ul>%s</ul>" % (len(found), esc(q), " (first 200)" if len(found) >= 200 else "", "".join(
                    '<li><a href="/books/%s?p=%d&q=%s">%s p.%d</a>: <small>%s</small></li>' % (b, n, urllib.parse.quote(q), esc(b[3:].replace("_", " ")), n,
                                                                                     esc(" ".join(c.split()))) for b, n, c in found))
            rows = "".join('<tr><td><a href="/books/%s">%s</a></td><td>%d</td></tr>' % (d.name, esc(d.name[3:].replace("_", " ")), len(list((d / "pages").glob("*.txt"))))
                           for d in books)
            body = ('<p class="note">Private reading copies of the d20 source books, extracted to <code>Source_Text/</code>. '
                    'They are copyrighted: this page is served only on your computer and is never written into the wiki or pushed to GitHub.</p>'
                    '<form action="/books"><input name="q" value="%s" placeholder="Search all books" size="40"><button>Search</button></form>%s'
                    '<table class="wikitable"><tr><th>Book</th><th>Pages</th></tr>%s</table>' % (esc(q), hits, rows))
            return self.send(layout("Source books (d20)", body))
        d = base / slug.replace("/", "").replace("..", "")
        pages = sorted((d / "pages").glob("*.txt")) if (d / "pages").is_dir() else []
        if not pages:
            return self.send(layout("Not found", "<p>No such book.</p>"), 404)
        n = max(1, min(len(pages), int((qs.get("p", ["1"])[0] or "1")))) if (qs.get("p", ["1"])[0] or "1").isdigit() else 1
        t = pages[n - 1].read_text(encoding="utf-8", errors="replace")
        h = esc(t)
        if q:
            h = re.sub("(%s)" % re.escape(esc(q)), r"<mark>\1</mark>", h, flags=re.I)
        nav = ('<p><a href="/books">All books</a> | <a href="/books/%s?p=%d&q=%s">&laquo; previous</a> | page %d of %d | '
               '<a href="/books/%s?p=%d&q=%s">next &raquo;</a> | <form style="display:inline" action="/books/%s"><input name="p" size="4" value="%d"><button>Go</button></form></p>'
               % (slug, max(1, n - 1), urllib.parse.quote(q), n, len(pages), slug, min(len(pages), n + 1), urllib.parse.quote(q), slug, n))
        self.send(layout(esc(slug[3:].replace("_", " ")), nav + "<pre class='booktext'>%s</pre>" % h + nav))

    def file_page(self, con, name):
        name = norm_title(name)
        r = con.execute("SELECT * FROM imgs WHERE name=?", (name,)).fetchone()
        info = ("<p>%s x %s, %s. <a href='%s'>Original file on Wookieepedia</a> (not downloaded).</p>" %
                (r["width"], r["height"], esc(r["mime"] or ""), esc(r["url"] or "#"))) if r else "<p>Unknown file.</p>"
        used = "".join('<li><a href="%s">%s</a></li>' % (wiki_href(x[0]), esc(x[0])) for x in
                       con.execute("SELECT page FROM imguse WHERE img=? LIMIT 100", (name,)))
        try:
            lic = con.execute("SELECT bucket,licence,artist,credit,descurl FROM imglic WHERE name=?", (name,)).fetchone()
        except Exception:
            lic = None
        if lic:
            info += ("<p class='note'><b>Licence:</b> %s (%s)%s%s. <a href='%s'>File page on Wookieepedia</a>.%s</p>" %
                     (esc(lic[1] or "not stated"), esc(lic[0]), (" &middot; <b>Author:</b> " + esc(lic[2])) if lic[2] else "",
                      (" &middot; <b>Credit:</b> " + esc(lic[3])) if lic[3] else "", esc(lic[4] or "#"),
                      " Shown in this private local wiki only; not published." if lic[0] != "free" else ""))
        body = '<img class="wimg" src="/img/%s" style="max-width:100%%">%s<h3>Used on</h3><ul>%s</ul>' % (urllib.parse.quote(name), info, used)
        self.send(layout("File:" + esc(name), body))

    def image(self, con, name):
        name = norm_title(name)
        rel = placeholders.placeholder_relpath(name)
        for real, ctype in ((FULL_IMG_DIR / rel.replace(".webp", ""), None), (FULL_IMG_DIR / rel, "image/webp"),
                            (ROOT / "images" / "local" / rel, "image/webp")):      # hand-placed file, free WebP, local-only WebP
            if real.is_file():
                return self.send(real.read_bytes(), 200, ctype or mimetypes.guess_type(str(real))[0] or "image/jpeg",
                                 {"Cache-Control": "no-cache"})
        w, h = DIMS.get(name, (None, None))
        p = placeholders.ensure_placeholder(name, w, h)
        self.send(p.read_bytes(), 200, "image/webp", {"Cache-Control": "no-cache"})


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
