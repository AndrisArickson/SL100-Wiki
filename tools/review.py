"""Reviewer workflow for the local wiki: drafts, diffs and submitting changes to GitHub as a pull request.

An edit made in the wiki is saved to pages/ straight away (so the wiki shows it) and recorded as a draft in
data/drafts.json. An image downloaded from Wookieepedia or uploaded (tools/imagefetch.py) is a draft the same way. The page carries an "Edited - not yet submitted" banner until the draft is submitted or discarded.
Submitting sends every chosen draft to GitHub as one commit on a new branch and opens a pull request against the
main branch; the project owner reviews and merges it there. Once the merge has been pulled, a draft whose page
matches the pulled version is cleared by itself.

The GitHub token and reviewer name live in data/reviewer.json (data/ is never committed). Standard library only.
"""
import base64
import difflib
import hashlib
import html
import json
import os
import re
import subprocess
import time
import urllib.error
import urllib.parse
import urllib.request

from common import DATA_DIR, ROOT, now_iso

DRAFTS = DATA_DIR / "drafts.json"
SETTINGS = DATA_DIR / "reviewer.json"
DEFAULTS = {"name": "", "token": "", "repo": "AndrisArickson/SL100-Wiki", "base": "main", "fork": ""}
API = os.environ.get("SL100_GITHUB_API", "https://api.github.com")


# ------------------------------------------------------------------ storage
def _load(path, default):
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, ValueError):
        return default


def _save(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_suffix(".tmp")
    tmp.write_text(json.dumps(data, indent=1, ensure_ascii=False), encoding="utf-8")
    os.replace(tmp, path)


def settings():
    s = dict(DEFAULTS)
    s.update(_load(SETTINGS, {}))
    if not s["token"]:
        s["token"] = os.environ.get("GITHUB_TOKEN", "")
    return s


def save_settings(form):
    s = dict(DEFAULTS)
    s.update(_load(SETTINGS, {}))
    for k in ("name", "repo", "base", "fork"):
        if k in form:
            s[k] = form[k].strip()
    if form.get("token", "").strip():          # an empty box keeps the saved token
        s["token"] = form["token"].strip()
    if form.get("forget_token"):
        s["token"] = ""
    _save(SETTINGS, s)
    return s


def path_of(rec):
    """Repository path of a draft's file (drafts saved before images were added only have "rel" under pages/)."""
    return rec.get("path") or "pages/" + rec["rel"]


def paths_of(rec):
    """Every file the draft touches: the file itself, and for an image the copy in the other format it replaced."""
    return [path_of(rec)] + [p for p in rec.get("removed", []) if p != path_of(rec)]


def drafts():
    """{key: {path, kind, editors, summaries, first, last, state, pr}}. The key is the page title, or "File:<name>" for
    an image. Drafts whose file matches the pulled version are removed."""
    d = _load(DRAFTS, {})
    changed = False
    for key in list(d):
        if all(current_bytes(p) == base_bytes(p) for p in paths_of(d[key])):
            del d[key]
            changed = True
    if changed:
        _save(DRAFTS, d)
    return d


def _record(key, path, kind, editor, summary, removed=()):
    d = _load(DRAFTS, {})
    rec = d.get(key) or {"editors": [], "summaries": [], "first": now_iso(), "state": "draft", "pr": ""}
    old = path_of(rec) if ("path" in rec or "rel" in rec) else None
    gone = set(rec.get("removed", [])) | set(removed)
    if old and old != path:
        gone.add(old)                          # e.g. a WebP replaced by an SVG: the WebP goes
    gone.discard(path)
    rec["removed"] = sorted(gone)
    rec["path"], rec["kind"] = path, kind
    rec.pop("rel", None)
    if editor and editor not in rec["editors"]:
        rec["editors"].append(editor)
    if summary:
        rec["summaries"].append(summary)
    rec["last"] = now_iso()
    rec["state"] = "draft"                     # a new edit after submitting needs submitting again
    d[key] = rec
    _save(DRAFTS, d)


def record_edit(title, rel, editor, summary):
    """A page saved in the wiki (rel is its path under pages/)."""
    _record(title, "pages/" + rel, "page", editor, summary)


def record_image(name, path, editor, summary, removed=()):
    """An image downloaded or uploaded into the wiki (path is its repository path, images/full/...; removed lists the
    copy in the other format, WebP or SVG, that it replaces)."""
    _record("File:" + name, path, "image", editor, summary, removed)


def forget(keys):
    d = _load(DRAFTS, {})
    for k in keys:
        d.pop(k, None)
    _save(DRAFTS, d)


# ------------------------------------------------------------------ the version last pulled from GitHub
def _git(*args):
    try:
        return subprocess.run(["git", *args], cwd=ROOT, capture_output=True, timeout=30)
    except (OSError, subprocess.SubprocessError):
        return None


def base_bytes(path):
    """The file as it is in the last commit pulled (git HEAD); None for a file that is new in this draft."""
    r = _git("show", "HEAD:" + path)
    if r is None or r.returncode != 0:
        return None
    return r.stdout


def current_bytes(path):
    f = ROOT / path
    return f.read_bytes() if f.is_file() else None


def blob_sha(data):
    return hashlib.sha1(b"blob %d\0" % len(data) + data).hexdigest()


def discard(key):
    """Put the file back as it was pulled (or remove a new one) and forget the draft."""
    rec = _load(DRAFTS, {}).get(key)
    if not rec:
        return False
    for path in paths_of(rec):
        cur, base = ROOT / path, base_bytes(path)
        if base is None:
            if cur.exists():
                cur.unlink()
        else:
            cur.parent.mkdir(parents=True, exist_ok=True)
            cur.write_bytes(base)
    forget([key])
    return True


def diff_html(key, context=3):
    rec = _load(DRAFTS, {}).get(key)
    if not rec:
        return "<p>No draft.</p>"
    path = path_of(rec)
    old, new = base_bytes(path), current_bytes(path)
    if rec.get("kind") == "image":
        for r in rec.get("removed", []):
            old = old or base_bytes(r)                 # the picture it replaces, in the other format
        def pic(data, label):
            if not data:
                return '<figure><figcaption>%s</figcaption><p class="hint">none (placeholder)</p></figure>' % label
            svg = data.lstrip()[:5] in (b"<?xml", b"<svg ") or b"<svg" in data[:2048]
            return ('<figure><img src="data:%s;base64,%s" style="max-width:360px"><figcaption>%s, %s, %s KB</figcaption></figure>'
                    % ("image/svg+xml" if svg else "image/webp", base64.b64encode(data).decode("ascii"), label,
                       "SVG" if svg else "WebP", max(1, round(len(data) / 1024))))
        return '<div class="imgdiff">%s%s</div>' % (pic(old, "Pulled"), pic(new, "Draft"))
    old_lines = (old or b"").decode("utf-8", errors="replace").splitlines()
    new_lines = (new or b"").decode("utf-8", errors="replace").splitlines()
    rows = []
    for ln in difflib.unified_diff(old_lines, new_lines, "pulled", "draft", n=context, lineterm=""):
        if ln.startswith(("---", "+++")):
            continue
        cls = "ctx"
        if ln.startswith("@@"):
            cls = "hunk"
        elif ln.startswith("+"):
            cls = "add"
        elif ln.startswith("-"):
            cls = "del"
        rows.append('<div class="d-%s">%s</div>' % (cls, html.escape(ln) or "&nbsp;"))
    return '<div class="diff">%s</div>' % ("".join(rows) or "<div class='d-ctx'>No differences.</div>")


# ------------------------------------------------------------------ GitHub
class GitHubError(Exception):
    pass


def _api(method, path, token, body=None):
    req = urllib.request.Request(API + path, method=method,
                                 data=json.dumps(body).encode("utf-8") if body is not None else None,
                                 headers={"Authorization": "Bearer " + token, "Accept": "application/vnd.github+json",
                                          "X-GitHub-Api-Version": "2022-11-28", "User-Agent": "SL100-Wiki-review",
                                          "Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(req, timeout=60) as r:
            raw = r.read()
            return json.loads(raw) if raw else {}
    except urllib.error.HTTPError as e:
        try:
            msg = json.loads(e.read()).get("message", "")
        except ValueError:
            msg = ""
        raise GitHubError("%s %s: %s %s" % (method, path, e.code, msg))
    except urllib.error.URLError as e:
        raise GitHubError("could not reach GitHub (%s)" % e.reason)


def submit(titles, pr_title, description):
    """Send the chosen drafts as one commit on a new branch and open a pull request. Returns the PR URL."""
    s = settings()
    if not s["token"]:
        raise GitHubError("no GitHub token: add one under Reviewer settings")
    d = _load(DRAFTS, {})
    chosen = [t for t in titles if t in d]
    if not chosen:
        raise GitHubError("no drafts chosen")
    upstream, base = s["repo"], s["base"]
    target = s["fork"] or upstream                 # where the branch is pushed
    tok = s["token"]

    # 1. Refuse pages that changed on GitHub since this computer pulled them, so nobody's edit is overwritten.
    stale = []
    for t in chosen:
        for path in paths_of(d[t]):
            pulled = base_bytes(path)
            try:
                remote = _api("GET", "/repos/%s/contents/%s?ref=%s" % (upstream, _q(path), base), tok)
                remote_sha = remote.get("sha")
            except GitHubError as e:
                if " 404 " not in str(e) + " ":
                    raise
                remote_sha = None
            if (pulled is None) != (remote_sha is None) or (pulled is not None and blob_sha(pulled) != remote_sha):
                stale.append(t)
                break
    if stale:
        raise GitHubError("these changed on GitHub since you last pulled: %s. Pull (git pull), check your "
                          "draft still reads right, then submit again." % ", ".join(stale))

    # 2. One commit with every chosen page, on top of the current main branch.
    if s["fork"]:
        try:
            _api("POST", "/repos/%s/merge-upstream" % target, tok, {"branch": base})
        except GitHubError:
            pass                                   # already up to date, or the fork has its own changes
    head = _api("GET", "/repos/%s/git/ref/heads/%s" % (upstream, base), tok)["object"]["sha"]
    tree = _api("GET", "/repos/%s/git/commits/%s" % (upstream, head), tok)["tree"]["sha"]
    entries = []
    for t in chosen:
        path = path_of(d[t])
        data = current_bytes(path) or b""
        blob = _api("POST", "/repos/%s/git/blobs" % target, tok,
                    {"content": base64.b64encode(data).decode("ascii"), "encoding": "base64"})
        entries.append({"path": path, "mode": "100644", "type": "blob", "sha": blob["sha"]})
        for gone in paths_of(d[t])[1:]:
            if base_bytes(gone) is not None:           # delete the replaced copy (sha None removes it from the tree)
                entries.append({"path": gone, "mode": "100644", "type": "blob", "sha": None})
    new_tree = _api("POST", "/repos/%s/git/trees" % target, tok, {"base_tree": tree, "tree": entries})["sha"]
    who = s["name"] or "a reviewer"
    lines = ["- %s%s" % (t, (": " + "; ".join(d[t]["summaries"])) if d[t]["summaries"] else "") for t in chosen]
    msg = "%s\n\nWiki edits by %s:\n%s\n" % (pr_title, who, "\n".join(lines))
    commit = _api("POST", "/repos/%s/git/commits" % target, tok, {"message": msg, "tree": new_tree, "parents": [head]})["sha"]
    slug = re.sub(r"[^a-z0-9]+", "-", (s["name"] or "reviewer").lower()).strip("-") or "reviewer"
    branch = "review/%s-%s" % (slug, time.strftime("%Y%m%d-%H%M%S"))
    _api("POST", "/repos/%s/git/refs" % target, tok, {"ref": "refs/heads/" + branch, "sha": commit})

    # 3. The pull request, for the owner to review and merge.
    body = "%s\n\n**Pages and images:**\n%s\n\nSubmitted from the wiki by %s." % (description.strip() or "Wiki edits.", "\n".join(lines), who)
    head_ref = ("%s:%s" % (target.split("/")[0], branch)) if s["fork"] else branch
    pr = _api("POST", "/repos/%s/pulls" % upstream, tok, {"title": pr_title, "head": head_ref, "base": base, "body": body})
    for t in chosen:
        d[t]["state"] = "submitted"
        d[t]["pr"] = pr.get("html_url", "")
    _save(DRAFTS, d)
    return pr.get("html_url", "")


def _q(path):
    return "/".join(urllib.parse.quote(p, safe="") for p in path.split("/"))
