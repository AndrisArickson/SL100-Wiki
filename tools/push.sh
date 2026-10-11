#!/usr/bin/env bash
# Commit and push the wiki to GitHub in chunks (a 100k+ file wiki in one commit/push is fragile).
#   ./wiki.sh push            chunks of 1500 files, pushing after each chunk
#   CHUNK=800 ./wiki.sh push
#   REMOTE=git@github.com:AndrisArickson/SL100-Wiki.git ./wiki.sh push     (use SSH instead of HTTPS)
set -eu
cd "$(dirname "$0")/.."
REMOTE="${REMOTE:-https://github.com/AndrisArickson/SL100-Wiki.git}"
BRANCH="${BRANCH:-main}"
CHUNK="${CHUNK:-1500}"

[ -d .git ] || { git init -q -b "$BRANCH"; echo "initialised git repo"; }
git remote get-url origin >/dev/null 2>&1 || git remote add origin "$REMOTE"
git checkout -q -B "$BRANCH" 2>/dev/null || true
# external/NTFS drives often trip git's ownership & line-ending checks
git config core.autocrlf false
git config --local safe.directory "$(pwd)" 2>/dev/null || true

# Never push copyrighted source-book extracts
if git ls-files --error-unmatch private >/dev/null 2>&1; then
  echo "ERROR: private/ is tracked by git - remove it with: git rm -r --cached private"; exit 1
fi

git add -A -- . ':!pages' ':!images' 2>/dev/null || git add -A
git diff --cached --quiet || git commit -q -m "Tools, docs and metadata update"

n=0
while : ; do
  # next chunk of untracked or modified files
  git ls-files -m -o --exclude-standard | head -n "$CHUNK" > /tmp/sl100_chunk.$$ || true
  [ -s /tmp/sl100_chunk.$$ ] || break
  n=$((n+1))
  git add --pathspec-from-file=/tmp/sl100_chunk.$$
  git commit -q -m "Wiki sync batch $n ($(wc -l < /tmp/sl100_chunk.$$) files)"
  echo "batch $n committed; pushing..."
  git push -u origin "$BRANCH" || { echo "push failed - fix auth/network and run again; nothing is lost"; rm -f /tmp/sl100_chunk.$$; exit 1; }
done
rm -f /tmp/sl100_chunk.$$
git push -u origin "$BRANCH" 2>/dev/null || true
echo "Push complete."
