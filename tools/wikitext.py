"""A small, dependency-free MediaWiki wikitext -> HTML renderer, good enough for browsing Wookieepedia
articles locally. Templates are not expanded; infobox-style templates are shown as tables.

    r = Renderer(title, exists=fn, img_info=fn); html = r.render(text); r.cats, r.images
"""
import html as _html
import re
import urllib.parse

ALLOWED_TAGS = {"b", "i", "u", "s", "strike", "del", "ins", "sub", "sup", "small", "big", "br", "span", "div",
                "center", "code", "tt", "em", "strong", "blockquote", "p", "abbr", "cite", "font", "ul", "ol",
                "li", "dl", "dt", "dd", "table", "tr", "td", "th", "caption", "hr", "pre", "kbd", "var", "q",
                "thead", "tbody"}
VOID = {"br", "hr"}
ALLOWED_ATTRS = {"class", "id", "style", "colspan", "rowspan", "align", "valign", "width", "height", "title",
                 "cellpadding", "cellspacing", "border"}
HIDDEN_TEMPLATES = {"top", "bottom", "otheruses", "multipleissues", "interlang", "stub", "cleanup", "expand",
                    "citation", "update", "needsimages", "clear", "toc", "tocright", "legends", "canon",
                    "dablink", "about", "for", "distinguish", "redirect", "notnc", "inuse", "delete"}
HIDDEN_PREFIXES = ("top|", "interlang", "otheruses", "multipleissues", "sources", "cleanup")
BLOCK_TOKEN_START = ("<table", "<div", "<figure", "<ul class=\"gallery", "<blockquote", "<pre", "<ol", "<ul", "<h")
FANDOM_URL = re.compile(r"^(?:https?:)?//[a-z0-9.-]*starwars\.(?:fandom|wikia)\.(?:com|org)/", re.I)
OWN_PREFIXES = ("SL100:", "SL100 ", "User:", "Talk:", "Help:", "Project:")   # our own space: red links invite new pages
INTERWIKI = {"w": "https://community.fandom.com/wiki/", "wikipedia": "https://en.wikipedia.org/wiki/",
             "wikt": "https://en.wiktionary.org/wiki/", "commons": "https://commons.wikimedia.org/wiki/",
             "c": "https://community.fandom.com/wiki/", "w:c:starwars": "https://starwars.fandom.com/wiki/"}
REFS_MARK = "\x01REFS\x01"
FILE_OPTS = re.compile(r"^(thumb|thumbnail|frame|frameless|border|right|left|center|none|baseline|sub|super|top|"
                       r"text-top|middle|bottom|text-bottom|\d+(x\d+)?px|x\d+px|upright.*|link=.*|alt=.*|class=.*|"
                       r"page=.*|lang=.*)$", re.I)


def slug(s):
    return re.sub(r"\s+", "_", s.strip())


def wiki_href(title):
    return "/wiki/" + urllib.parse.quote(slug(title), safe="/:()',!*~@$&+=;-._")


def sanitize_attrs(raw):
    out = []
    for m in re.finditer(r"([A-Za-z][\w-]*)\s*=\s*(?:\"([^\"]*)\"|'([^']*)'|([^\s\"'>]+))", raw or ""):
        k = m.group(1).lower()
        v = m.group(2) if m.group(2) is not None else (m.group(3) if m.group(3) is not None else m.group(4))
        if k not in ALLOWED_ATTRS:
            continue
        if k == "style" and re.search(r"url\s*\(|expression|javascript|@import|behavior|binding", v, re.I):
            continue
        out.append(' %s="%s"' % (k, _html.escape(v, quote=True)))
    return "".join(out)


class Renderer:
    def __init__(self, title="", exists=None, img_info=None):
        self.title = title
        self.exists = exists or (lambda t: True)
        self.img_info = img_info or (lambda n: ("/img/" + urllib.parse.quote(n), None, None))
        self.stash = []
        self.cats = []
        self.images = []
        self.refs = []
        self.refnames = {}
        self.toc = []
        self.ids = set()

    # ------------------------------------------------------------ tokens
    def tok(self, h):
        self.stash.append(h)
        return "\x00%d\x00" % (len(self.stash) - 1)

    def untok(self, s):
        for _ in range(40):
            n = re.sub(r"\x00(\d+)\x00", lambda m: self.stash[int(m.group(1))], s)
            if n == s:
                break
            s = n
        return s

    # -------------------------------------------------------------- main
    def render(self, text):
        text = text.replace("\x00", "").replace("\x01", "")
        text = re.sub(r"<!--.*?-->", "", text, flags=re.S)
        text = re.sub(r"<includeonly>.*?</includeonly>", "", text, flags=re.S | re.I)
        text = re.sub(r"</?(?:noinclude|onlyinclude)\s*>", "", text, flags=re.I)
        text = self.stash_nowiki(text)
        text = self.stash_refs(text)
        text = self.stash_gallery(text)
        text = self.tokenize_templates(text)
        text = self.tokenize_links(text)
        text = self.tokenize_tables(text)
        body = self.blocks(text)
        out = self.untok(body)
        refs_html = self.refs_html()
        if REFS_MARK in out:
            out = out.replace(REFS_MARK, refs_html)
        elif self.refs:
            out += "<h2>References</h2>" + refs_html
        return out

    # ----------------------------------------------------- nowiki / refs
    def stash_nowiki(self, t):
        t = re.sub(r"<nowiki>(.*?)</nowiki>", lambda m: self.tok(_html.escape(m.group(1))), t, flags=re.S | re.I)
        t = re.sub(r"<(pre|syntaxhighlight|source|math)\b[^>]*>(.*?)</\1>",
                   lambda m: self.tok("<pre>%s</pre>" % _html.escape(m.group(2))), t, flags=re.S | re.I)
        return t

    def stash_refs(self, t):
        t = re.sub(r"<references\b[^>]*?/?>(?:\s*</references>)?", REFS_MARK, t, flags=re.I)
        t = re.sub(r"<ref\b([^>]*?)\s*/>", lambda m: self._ref(m.group(1), None), t, flags=re.I)
        t = re.sub(r"<ref\b([^>]*)>(.*?)</ref>", lambda m: self._ref(m.group(1), m.group(2)), t, flags=re.S | re.I)
        return t

    def _ref(self, attrs, body):
        nm = re.search(r"name\s*=\s*\"?([^\"\s/>]+)", attrs or "")
        name = nm.group(1) if nm else None
        content = self.inline(body.replace("\n", " ")) if body and body.strip() else ""
        if name and name in self.refnames:
            n = self.refnames[name]
            if content and not self.refs[n]["content"]:
                self.refs[n]["content"] = content
        else:
            self.refs.append({"name": name, "content": content})
            n = len(self.refs) - 1
            if name:
                self.refnames[name] = n
        return self.tok('<sup class="ref" id="cite_ref-%d"><a href="#cite_note-%d">[%d]</a></sup>' % (n + 1, n + 1, n + 1))

    def refs_html(self):
        if not self.refs:
            return ""
        li = "".join('<li id="cite_note-%d"><a class="backlink" href="#cite_ref-%d">^</a> %s</li>' %
                     (i + 1, i + 1, self.untok(r["content"])) for i, r in enumerate(self.refs))
        return '<ol class="references">%s</ol>' % li

    def stash_gallery(self, t):
        def g(m):
            items = []
            for line in m.group(1).splitlines():
                line = line.strip()
                if not line:
                    continue
                parts = line.split("|", 1)
                name = re.sub(r"^(?:File|Image)\s*:\s*", "", parts[0].strip(), flags=re.I)
                cap = self.inline(parts[1]) if len(parts) > 1 else ""
                src, w, h = self.img_info(self._norm_img(name))
                self.images.append(self._norm_img(name))
                items.append('<li><img src="%s" loading="lazy" alt=""><div class="gcap">%s</div></li>' % (src, cap))
            return self.tok('<ul class="gallery">%s</ul>' % "".join(items))
        return re.sub(r"<gallery\b[^>]*>(.*?)</gallery>", g, t, flags=re.S | re.I)

    @staticmethod
    def _norm_img(n):
        n = re.sub(r"\s+", " ", n.replace("_", " ")).strip()
        return n[:1].upper() + n[1:]

    # ---------------------------------------------------------- templates
    @staticmethod
    def _match(text, i, open_, close):
        depth, k, n = 0, i, len(text)
        while k < n:
            if text.startswith(open_, k):
                depth += 1
                k += len(open_)
            elif text.startswith(close, k):
                depth -= 1
                k += len(close)
                if depth == 0:
                    return k
            else:
                k += 1
        return -1

    @staticmethod
    def split_top(s, sep="|"):
        parts, buf, d1, d2, i = [], [], 0, 0, 0
        while i < len(s):
            two = s[i:i + 2]
            if two == "{{":
                d1 += 1; buf.append(two); i += 2; continue
            if two == "}}":
                d1 -= 1; buf.append(two); i += 2; continue
            if two == "[[":
                d2 += 1; buf.append(two); i += 2; continue
            if two == "]]":
                d2 -= 1; buf.append(two); i += 2; continue
            if s[i] == sep and d1 <= 0 and d2 <= 0:
                parts.append("".join(buf)); buf = []
            else:
                buf.append(s[i])
            i += 1
        parts.append("".join(buf))
        return parts

    def tokenize_templates(self, text):
        out, i = [], 0
        while True:
            j = text.find("{{", i)
            if j < 0:
                out.append(text[i:]); break
            out.append(text[i:j])
            if text.startswith("{{{", j):
                k = text.find("}}}", j)
                i = len(text) if k < 0 else k + 3
                continue
            k = self._match(text, j, "{{", "}}")
            if k < 0:
                out.append("{{"); i = j + 2; continue
            out.append(self.tok(self.render_template(text[j + 2:k - 2])))
            i = k
        return "".join(out)

    def render_template(self, inner):
        parts = self.split_top(inner)
        name = parts[0].strip()
        lname = re.sub(r"[_\s]+", " ", name).lower()
        pos, named = [], []
        for p in parts[1:]:
            m = re.match(r"\s*([^=\[\]{}|<>\n]+?)\s*=(.*)$", p, re.S)
            if m:
                named.append((m.group(1).strip(), m.group(2).strip()))
            else:
                pos.append(p.strip())
        if name.startswith("#") or lname.startswith(("#", "{{#")):
            return ""
        if lname == "!":
            return "|"
        if lname in ("pagename", "fullpagename"):
            return _html.escape(self.title)
        if lname in ("reflist", "references", "reflist|2"):
            return REFS_MARK
        if lname in HIDDEN_TEMPLATES or lname.startswith(HIDDEN_PREFIXES):
            return ""
        if lname in ("quote", "cquote", "bquote"):
            q = self.inline(pos[0]) if pos else self.inline(dict(named).get("quote", ""))
            src = self.inline(pos[1]) if len(pos) > 1 else ""
            return '<blockquote class="tquote">%s%s</blockquote>' % (q, ("<cite>— %s</cite>" % src) if src else "")
        filled = [(k, v) for k, v in named if v.strip()]
        if len(filled) >= 3:
            return self.infobox(name, filled)
        bits = [self.inline(p) for p in pos if p]
        bits += [self.inline(v) for k, v in filled]
        if not bits:
            return ""
        return '<span class="tpl" title="{{%s}}">%s</span>' % (_html.escape(name), " · ".join(bits))

    def infobox(self, name, rows):
        title = ""
        for k, v in rows:
            if k.lower() in ("name", "title"):
                title = self.inline(v)
        body = []
        for k, v in rows:
            if k.lower() in ("name", "title", "type", "bgcolor", "nocat", "noimage"):
                continue
            lines = [ln.strip() for ln in v.split("\n") if ln.strip()]
            lines = [("• " + ln.lstrip("*").strip()) if ln.startswith("*") else ln for ln in lines]
            val = self.inline("<br>".join(lines))
            if k.lower() in ("image", "img", "image1", "portrait") and "[[" in v:
                body.append('<tr><td colspan="2" class="ibimg">%s</td></tr>' % val)
            else:
                body.append("<tr><th>%s</th><td>%s</td></tr>" % (_html.escape(k.replace("_", " ").capitalize()), val))
        return ('<table class="infobox"><caption>%s <small>{{%s}}</small></caption>%s</table>' %
                (title or _html.escape(name), _html.escape(name), "".join(body)))

    # -------------------------------------------------------------- links
    def tokenize_links(self, text):
        out, i = [], 0
        while True:
            j = text.find("[[", i)
            if j < 0:
                out.append(text[i:]); break
            out.append(text[i:j])
            k = self._match(text, j, "[[", "]]")
            if k < 0:
                out.append("[["); i = j + 2; continue
            trail = re.match(r"[a-z]+", text[k:])
            tr = trail.group(0) if trail else ""
            out.append(self.render_link(text[j + 2:k - 2], tr))
            i = k + len(tr)
        return "".join(out)

    def render_link(self, inner, trail=""):
        parts = self.split_top(inner)
        target = parts[0].strip()
        forced = target.startswith(":")
        if forced:
            target = target[1:].strip()
        pre = target.split(":", 1)[0].strip().lower() if ":" in target else ""
        if pre == "category" and not forced:
            c = re.sub(r"\s+", " ", target.split(":", 1)[1].replace("_", " ")).strip()
            c = c[:1].upper() + c[1:]
            if c and c not in self.cats:
                self.cats.append(c)
            return ""
        if pre in ("file", "image") and not forced:
            return self.tok(self.render_file(target.split(":", 1)[1], parts[1:]))
        if re.match(r"(?:w|c):(?:c:)?starwars:", target, re.I):          # interwiki back to the live Wookieepedia
            lab = parts[1] if len(parts) > 1 else target.split(":")[-1].replace("_", " ")
            return self.tok('<span class="unlinked" title="Wookieepedia link removed">%s</span>' % self.fmt(lab + trail))
        for iw, base in INTERWIKI.items():
            if target.lower().startswith(iw + ":") and iw in ("w", "wikipedia", "wikt", "commons", "c"):
                url = base + urllib.parse.quote(target.split(":", 1)[1].strip().replace(" ", "_"), safe="/:()'")
                label = parts[1] if len(parts) > 1 else target.split(":")[-1]
                if "fandom.com" in base and iw in ("w", "c"):
                    pass
                return self.tok('<a class="ext" href="%s" rel="nofollow">%s</a>' % (url, self.fmt(label + trail)))
        base_t, _, frag = target.partition("#")
        norm = re.sub(r"\s+", " ", base_t.replace("_", " ")).strip()
        norm = norm[:1].upper() + norm[1:]
        if len(parts) > 1 and parts[1].strip():
            label = parts[1]
        elif len(parts) > 1:                      # pipe trick
            label = re.sub(r"\s*\(.*?\)$", "", re.sub(r"^[^:]*:", "", norm))
        else:
            label = re.sub(r"/Legends$", "", target if target else frag)
            if not base_t:
                label = frag
        label = self.fmt(label + trail)
        if not norm:                               # section link on same page
            return self.tok('<a href="#%s">%s</a>' % (_html.escape(slug(frag), quote=True), label))
        if not self.exists(norm):
            # Legends-only wiki: prefer the /Legends version of a title; never link out to pages we do not hold
            alt = norm if norm.endswith("/Legends") else norm + "/Legends"
            if self.exists(alt):
                norm = alt
            elif not norm.startswith(OWN_PREFIXES):
                return self.tok('<span class="unlinked" title="Not in this Legends wiki">%s</span>' % label)
        href = wiki_href(norm) + ("#" + urllib.parse.quote(slug(frag)) if frag else "")
        cls = "" if self.exists(norm) else ' class="new"'
        return self.tok('<a href="%s"%s title="%s">%s</a>' % (href, cls, _html.escape(norm, quote=True), label))

    def render_file(self, name, opts):
        name = self._norm_img(name)
        self.images.append(name)
        src, nw, nh = self.img_info(name)
        thumb = frame = False
        width = None
        pos = "right"
        cap = ""
        alt = ""
        for o in opts:
            o = o.strip()
            ol = o.lower()
            if ol in ("thumb", "thumbnail"):
                thumb = True
            elif ol == "frame":
                frame = True
            elif ol in ("left", "right", "center", "none"):
                pos = ol
            elif re.match(r"^\d+px$|^\d+x\d+px$|^x\d+px$", ol):
                m = re.match(r"(\d+)", ol)
                width = int(m.group(1)) if m else None
            elif ol.startswith("alt="):
                alt = o[4:]
            elif not FILE_OPTS.match(o):
                cap = o
        if width is None:
            width = 220 if (thumb or frame) else (min(nw, 400) if nw else 220)
        elif nw and width > nw and not (thumb or frame):
            width = nw
        capH = self.inline(cap) if cap else ""
        img = ('<a href="%s"><img src="%s" width="%d" loading="lazy" alt="%s" class="wimg"></a>' %
               (wiki_href("File:" + name), src, width, _html.escape(alt or name, quote=True)))
        if thumb or frame:
            return ('<figure class="thumb t%s" style="width:%dpx">%s<figcaption>%s</figcaption></figure>' %
                    (pos if pos != "none" else "none", width + 8, img, capH))
        return '<span class="fimg f%s">%s</span>' % (pos, img)

    # -------------------------------------------------------------- tables
    def tokenize_tables(self, text):
        lines = text.split("\n")
        out, i = [], 0
        while i < len(lines):
            if lines[i].lstrip().startswith("{|"):
                depth, j = 0, i
                while j < len(lines):
                    s = lines[j].lstrip()
                    if s.startswith("{|"):
                        depth += 1
                    if s.startswith("|}"):
                        depth -= 1
                        if depth == 0:
                            break
                    j += 1
                out.append(self.tok(self.render_table(lines[i:j + 1])))
                i = j + 1
            else:
                out.append(lines[i]); i += 1
        return "\n".join(out)

    def _cell(self, content):
        content = content.strip("\n")
        if "\n" in content.strip() or re.match(r"^[*#:;]|^=", content.strip()):
            return self.blocks(content)
        return self.fmt(content)

    def render_table(self, lines):
        attrs = sanitize_attrs(lines[0].strip()[2:])
        caption, rows, cur, cell = "", [], None, None

        def newrow(a=""):
            nonlocal cur, cell
            cur = {"attrs": sanitize_attrs(a), "cells": []}
            rows.append(cur)
            cell = None

        i = 1
        while i < len(lines):
            s = lines[i].strip()
            if s.startswith("{|"):                 # nested table
                depth, j = 0, i
                while j < len(lines):
                    t = lines[j].strip()
                    depth += t.startswith("{|")
                    if t.startswith("|}"):
                        depth -= 1
                        if depth == 0:
                            break
                    j += 1
                if cell is not None:
                    cell["body"] += "\n" + self.tok(self.render_table(lines[i:j + 1]))
                i = j + 1
                continue
            if s.startswith("|}"):
                break
            if s.startswith("|+"):
                caption = self.fmt(s[2:].split("|", 1)[-1].strip())
            elif s.startswith("|-"):
                newrow(s.lstrip("|-"))
            elif s[:1] in ("|", "!"):
                if cur is None:
                    newrow()
                head = s[0] == "!"
                body = s[1:]
                for piece in re.split(r"\|\||!!" if head else r"\|\|", body):
                    a, c = "", piece
                    if "|" in piece and not piece.lstrip().startswith("\x00"):
                        a, c = piece.split("|", 1)
                    cell = {"head": head, "attrs": sanitize_attrs(a), "body": c.strip()}
                    cur["cells"].append(cell)
            elif cell is not None:
                cell["body"] += "\n" + lines[i]
            i += 1
        h = ["<table%s>" % (attrs or ' class="wikitable"')]
        if caption:
            h.append("<caption>%s</caption>" % caption)
        for r in rows:
            if not r["cells"]:
                continue
            h.append("<tr%s>" % r["attrs"])
            for c in r["cells"]:
                tag = "th" if c["head"] else "td"
                h.append("<%s%s>%s</%s>" % (tag, c["attrs"], self._cell(c["body"]), tag))
            h.append("</tr>")
        h.append("</table>")
        return "".join(h)

    # --------------------------------------------------------------- blocks
    @staticmethod
    def _lt(c):
        return {"*": "ul", "#": "ol", ":": "dl", ";": "dl"}[c]

    @staticmethod
    def _it(c):
        return {"*": "li", "#": "li", ":": "dd", ";": "dt"}[c]

    def _list_to(self, out, cur, new):
        k = 0
        while k < len(cur) and k < len(new) and self._lt(cur[k]) == self._lt(new[k]):
            k += 1
        for c in reversed(cur[k:]):
            out.append("</%s></%s>" % (self._it(c), self._lt(c)))
        if k == len(new) and k > 0:
            out.append("</%s><%s>" % (self._it(cur[k - 1]), self._it(new[k - 1])))
        else:
            for c in new[k:]:
                out.append("<%s><%s>" % (self._lt(c), self._it(c)))
        return new

    def _heading_id(self, plain):
        base = slug(re.sub(r"<[^>]+>", "", plain)) or "section"
        i, hid = 1, base
        while hid in self.ids:
            i += 1
            hid = "%s_%d" % (base, i)
        self.ids.add(hid)
        return hid

    def blocks(self, text):
        out, para, cur = [], [], ""

        def flush():
            if para:
                h = self.fmt("\n".join(para)).strip()
                if self.untok(h).strip():
                    out.append("<p>%s</p>" % h)
                para.clear()

        for line in text.split("\n"):
            s = line.strip()
            if not s:
                flush()
                if cur:
                    self._list_to(out, cur, ""); cur = ""
                continue
            m = re.match(r"^(={1,6})\s*(.+?)\s*\1\s*$", s)
            if m:
                flush()
                if cur:
                    self._list_to(out, cur, ""); cur = ""
                lvl = len(m.group(1))
                inner = self.fmt(m.group(2))
                hid = self._heading_id(self.untok(inner))
                self.toc.append((lvl, hid, re.sub(r"<[^>]+>", "", self.untok(inner))))
                out.append('<h%d id="%s">%s</h%d>' % (lvl, _html.escape(hid, quote=True), inner, lvl))
                continue
            if re.match(r"^-{4,}$", s):
                flush(); out.append("<hr>"); continue
            m = re.match(r"^([*#:;]+)\s*(.*)$", line)
            if m:
                flush()
                prefix, content = m.group(1), m.group(2)
                cur = self._list_to(out, cur, prefix)
                if prefix[-1] == ";" and " : " in content:
                    a, b = content.split(" : ", 1)
                    out.append(self.fmt(a) + "</dt><dd>" + self.fmt(b))
                    cur = cur[:-1] + ":"
                else:
                    out.append(self.fmt(content))
                continue
            if cur:
                self._list_to(out, cur, ""); cur = ""
            tm = re.fullmatch(r"\x00(\d+)\x00", s)
            if tm:
                h = self.stash[int(tm.group(1))]
                if not self.untok(h).strip():
                    continue
                if h.startswith(BLOCK_TOKEN_START):
                    flush(); out.append(h); continue
            if re.match(r"^</?(div|table|tr|td|th|blockquote|center|ul|ol|li|dl|dt|dd|hr|p|caption)\b", s, re.I):
                flush(); out.append(self.fmt(line)); continue
            para.append(line)
        flush()
        if cur:
            self._list_to(out, cur, "")
        res = "\n".join(out)
        if len(self.toc) >= 4 and "__NOTOC__" not in text:
            res = self._with_toc(res)
        return res.replace("__NOTOC__", "").replace("__TOC__", "").replace("__NOEDITSECTION__", "")

    def _with_toc(self, res):
        if getattr(self, "_toc_done", False):
            return res
        self._toc_done = True
        items = "".join('<li class="l%d"><a href="#%s">%s</a></li>' % (lvl, _html.escape(i, quote=True), _html.escape(t))
                        for lvl, i, t in self.toc)
        toc = '<div class="toc"><b>Contents</b><ul>%s</ul></div>' % items
        k = res.find("<h")
        return res[:k] + toc + res[k:] if k >= 0 else res

    # --------------------------------------------------------------- inline
    def inline(self, text):
        """Full inline pipeline for template args / refs / captions."""
        text = self.tokenize_templates(text)
        text = self.tokenize_links(text)
        return self.fmt(text)

    def ext_links(self, s):
        def br(m):
            url = m.group(1)
            if url.startswith("//"):
                url = "https:" + url
            label = m.group(2)
            lab = self.fmt(label) if label else "[link]"
            if FANDOM_URL.search(url):
                return self.tok('<span class="unlinked" title="External Wookieepedia link removed">%s</span>' % lab)
            return self.tok('<a class="ext" href="%s" rel="nofollow">%s</a>' % (_html.escape(url, quote=True), lab))
        s = re.sub(r"\[((?:https?:)?//[^\s\]\x00]+)(?:\s+([^\]]*))?\]", br, s)
        s = re.sub(r"(?<![\"'=>\x00\w])(https?://[^\s<>\]\x00\"]+)",
                   lambda m: self.tok('<span class="unlinked">%s</span>' % _html.escape(m.group(1))) if FANDOM_URL.search(m.group(1)) else self.tok('<a class="ext" href="%s" rel="nofollow">%s</a>' %
                                      (_html.escape(m.group(1), quote=True), _html.escape(m.group(1)))), s)
        return s

    def fmt(self, s):
        s = self.ext_links(s)
        s = re.sub(r"&(#?\w+);", "\x02\\1;", s)
        s = _html.escape(s, quote=False)
        s = s.replace("\x02", "&")

        def tag(m):
            close, name, attrs, selfc = m.group(1), m.group(2).lower(), m.group(3), m.group(4)
            if name not in ALLOWED_TAGS:
                return m.group(0)
            if name in VOID:
                return "<%s>" % name
            if close:
                return "</%s>" % name
            return "<%s%s>" % (name, sanitize_attrs(_html.unescape(attrs)))
        s = re.sub(r"&lt;(/?)([A-Za-z][A-Za-z0-9]*)\b([^<>]*?)(/?)&gt;", tag, s)
        out = []
        for ln in s.split("\n"):
            ln = re.sub(r"'''''(.+?)'''''", r"<b><i>\1</i></b>", ln)
            ln = re.sub(r"'''(.+?)'''", r"<b>\1</b>", ln)
            ln = re.sub(r"''(.+?)''", r"<i>\1</i>", ln)
            out.append(ln)
        return "\n".join(out)
