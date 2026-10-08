#!/bin/bash
# fetch.sh WORK [MIRROR]
# Puts the sources in scripts/sources.lock into WORK (amiga-gcc's framework at
# WORK, its modules under WORK/projects), each at its pinned commit.
# With MIRROR (a folder holding an earlier amiga-gcc checkout, laid out the
# same way), every repository is cloned from there instead of the network.
# The AmigaOS NDK is not fetched: build.sh takes it from you.
# GPL-3.0-or-later, like the patches it goes with. Copyright (c) 2026 Dalsin Limited.
set -euo pipefail
WORK=$1; MIRROR=${2:-}
HERE=$(cd "$(dirname "$0")" && pwd)
mkdir -p "$WORK"
grep -v '^#' "$HERE/sources.lock" | while read -r name url commit dir; do
  [ -n "$name" ] || continue
  dest="$WORK/$dir"
  src=$url; [ -z "$MIRROR" ] || src="$MIRROR/$dir"
  if [ -d "$dest/.git" ]; then
    echo "$name: already in $dest"
  elif [ "$dir" = . ]; then
    git clone -q --no-checkout "$src" "$WORK/.amiga-gcc-clone"
    mv "$WORK/.amiga-gcc-clone/.git" "$WORK/.git" && rmdir "$WORK/.amiga-gcc-clone"
    git -C "$WORK" checkout -q "$commit"
  else
    mkdir -p "$(dirname "$dest")"
    git clone -q --no-checkout "$src" "$dest"
  fi
  git -C "$dest" cat-file -e "$commit^{commit}" 2>/dev/null || git -C "$dest" fetch -q --depth 1 origin "$commit"
  git -C "$dest" -c advice.detachedHead=false checkout -q "$commit"
  echo "$name: $(git -C "$dest" rev-parse --short HEAD)"
done
