#!/usr/bin/env bash
# snapshot.sh — snapshot-style backups with rsync --link-dest
#
# Usage: snapshot.sh SOURCE_DIR BACKUP_ROOT
#
# Each run creates BACKUP_ROOT/<date-time>/ holding a full copy of
# SOURCE_DIR, and points BACKUP_ROOT/latest at it. Files that did
# not change since the previous snapshot are hardlinked to it
# instead of copied, so a snapshot costs roughly the size of what
# changed — while still reading as a complete, browsable tree.
#
# Delete an old snapshot and the files it shares with newer ones
# survive; the space comes back only when the last snapshot
# holding a version goes.

set -euo pipefail

src=$1
root=$2
stamp=$(date +%Y-%m-%d_%H%M%S)

mkdir -p "$root"
root=$(cd "$root" && pwd)   # --link-dest wants an unambiguous path

link_opt=()
if [ -L "$root/latest" ]; then
    link_opt=(--link-dest="$root/latest")
fi

rsync -a "${link_opt[@]}" "$src"/ "$root/$stamp/"
ln -sfn "$stamp" "$root/latest"
echo "snapshot: $root/$stamp"
