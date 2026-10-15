#!/usr/bin/env python3
"""Bring in the approved changes from GitHub:   ./wiki.sh pull

A plain `git pull` refuses to run once one of your own submissions has been merged: the page or picture you edited is
still changed (or, for a new picture, untracked) on your computer, and Git will not overwrite it even though GitHub now
holds exactly the same file. This script fetches first, clears every such file whose content already matches the
incoming version (nothing is lost: the same bytes arrive with the pull), then pulls. A file you changed that differs
from the incoming version is left alone and listed, so nobody's work is overwritten.
"""
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def git(*args, check=True):
    r = subprocess.run(["git", *args], cwd=ROOT, capture_output=True)
    if check and r.returncode != 0:
        sys.exit("git %s failed:\n%s" % (" ".join(args), r.stderr.decode("utf-8", "replace").strip()))
    return r


def blob(ref, path):
    r = git("show", "%s:%s" % (ref, path), check=False)
    return r.stdout if r.returncode == 0 else None


def main():
    branch = git("rev-parse", "--abbrev-ref", "HEAD").stdout.decode().strip()
    upstream = git("rev-parse", "--abbrev-ref", "--symbolic-full-name", "@{u}", check=False).stdout.decode().strip()
    remote, _, rbranch = (upstream.partition("/") if upstream else ("origin", "", branch))
    print("Fetching %s/%s ..." % (remote, rbranch))
    git("fetch", remote, rbranch)
    incoming = "FETCH_HEAD"
    changed = [p for p in git("diff", "--name-only", "-z", "HEAD", incoming).stdout.decode("utf-8").split("\0") if p]
    if not changed:
        print("Already up to date.")
        return
    dirty = set(p for p in git("ls-files", "-z", "--modified", "--others", "--exclude-standard", "--", *changed)
                .stdout.decode("utf-8").split("\0") if p)
    cleared, differ = [], []
    for path in sorted(dirty):
        mine, theirs = (ROOT / path), blob(incoming, path)
        if theirs is not None and mine.is_file() and mine.read_bytes() == theirs:
            if blob("HEAD", path) is None:
                mine.unlink()                               # an untracked new file: the pull brings the same file
            else:
                git("checkout", "HEAD", "--", path)         # a changed file: the pull brings the same change
            cleared.append(path)
        else:
            differ.append(path)
    if differ:
        print("Not pulled. These files are changed on this computer and differ from the version on GitHub:")
        for p in differ:
            print("   " + p)
        print("Keep a copy of each (for a page, its text from the Edit box), discard the draft from Review changes,\n"
              "run ./wiki.sh pull again, then make your edit again on top of the new version.")
        sys.exit(1)
    if cleared:
        print("Already merged on GitHub, cleared here first: %d file(s)" % len(cleared))
    r = git("merge", "--ff-only", incoming, check=False)
    if r.returncode != 0:
        r = git("merge", "--no-edit", incoming, check=False)
    sys.stdout.write(r.stdout.decode("utf-8", "replace"))
    if r.returncode != 0:
        sys.exit(r.stderr.decode("utf-8", "replace").strip())
    print("Up to date. Restart ./wiki.sh serve if it is running, so it shows the new pages.")


if __name__ == "__main__":
    main()
