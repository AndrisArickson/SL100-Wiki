#!/usr/bin/env bash
# One-off: remove the big JPG/PNG image blobs from git history (they now live as WebP in the repo and as
# masters in ../art_originals), then force-push. Run in YOUR terminal from the SL100-Wiki folder:
#     bash tools/purge_history.sh
# Needs git-filter-repo:  pip install --user git-filter-repo   (or your distro's package)
# Also strips the VPN configs (private keys) and the empty Proton Drive zip that were committed by mistake.
# Afterwards any OTHER clone of the repo must be re-cloned (old history is gone).
set -eu
cd "$(dirname "$0")/.."
command -v git-filter-repo >/dev/null || { echo "Install git-filter-repo first: pip install --user git-filter-repo"; exit 1; }
[ -z "$(git status --porcelain)" ] || { echo "Commit or push your changes first (./wiki.sh push), then re-run."; exit 1; }
REMOTE="$(git remote get-url origin)"
BACKUP="../SL100-Wiki-history-backup-$(date +%Y%m%d).bundle"
echo "1/4 Backing up full history to $BACKUP ..."
git bundle create "$BACKUP" --all
echo "    size before: $(git count-objects -vH | grep size-pack)"
echo "2/4 Removing old image blobs from history ..."
git filter-repo --force \
  --path-regex '^images/generated/.*\.jpg$' \
  --path-regex '^images/full/[^/]+/[^/]+\.(png|jpg|jpeg)$' \
  --path-regex '^[^/]+\.ovpn$' \
  --path-regex '^wg-[^/]*\.conf$' \
  --path-regex '^Proton Drive Download[^/]*\.zip$' \
  --invert-paths
git reflog expire --expire=now --all && git gc --prune=now --aggressive
echo "    size after:  $(git count-objects -vH | grep size-pack)"
echo "3/4 Restoring remote (filter-repo removes it) ..."
git remote add origin "$REMOTE" 2>/dev/null || git remote set-url origin "$REMOTE"
echo "4/4 Force-pushing rewritten history ..."
git push --force origin HEAD:main
echo "Done. Backup kept at $BACKUP (delete it once you're happy)."
