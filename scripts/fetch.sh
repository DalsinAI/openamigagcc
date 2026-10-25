#!/bin/bash
# fetch.sh WORK [MIRROR]
# Puts the sources in scripts/sources.lock into WORK (amiga-gcc's framework at
# WORK, its modules under WORK/projects), each at its pinned commit.
# With MIRROR (a folder holding an earlier amiga-gcc checkout, laid out the
# same way), every repository is cloned from there instead of the network.
# The AmigaOS NDK is not fetched: build.sh takes it from you.
# GPL-3.0-or-later, like the patches it goes with. Copyright (c) 2026 AmigaChrome Team.
set -euo pipefail
WORK=$1; MIRROR=${2:-}
HERE=$(cd "$(dirname "$0")" && pwd)
mkdir -p "$WORK"
say() {     # say LEVEL TEXT: to stderr, and as an annotation in GitHub Actions
  echo "$2" >&2
  [ -z "${GITHUB_ACTIONS:-}" ] || echo "::$1::${2//$'\n'/ | }"
}
clone() {   # clone URL ALT DEST: clone URL (no checkout), or ALT when URL does not answer
  local err
  err=$(git clone -q --no-checkout "$1" "$3" 2>&1) && return 0
  rm -rf "$3"
  if [ -z "$2" ]; then say error "cloning $1 failed: $err"; return 1; fi
  say warning "cloning $1 failed ($(echo "$err" | head -1)); cloning $2 instead"
  err=$(git clone -q --no-checkout "$2" "$3" 2>&1) && return 0
  say error "cloning $2 failed: $err"; return 1
}
grep -v '^#' "$HERE/sources.lock" | while read -r name url commit dir; do
  [ -n "$name" ] || continue
  dest="$WORK/$dir"
  src=$url; [ -z "$MIRROR" ] || src="$MIRROR/$dir"
  # bebbo's repositories are on franke.ms, with a copy on Codeberg that he keeps
  # in step; the pinned commit is checked out either way.
  alt=; case $src in https://franke.ms/git/bebbo/*) alt="https://codeberg.org/bebbo/${src#https://franke.ms/git/bebbo/}" ;; esac
  if [ -d "$dest/.git" ]; then
    echo "$name: already in $dest"
  elif [ "$dir" = . ]; then
    clone "$src" "$alt" "$WORK/.amiga-gcc-clone"
    mv "$WORK/.amiga-gcc-clone/.git" "$WORK/.git" && rmdir "$WORK/.amiga-gcc-clone"
    git -C "$WORK" checkout -q "$commit"
  else
    mkdir -p "$(dirname "$dest")"
    clone "$src" "$alt" "$dest"
  fi
  git -C "$dest" cat-file -e "$commit^{commit}" 2>/dev/null || git -C "$dest" fetch -q --depth 1 origin "$commit"
  git -C "$dest" -c advice.detachedHead=false checkout -q "$commit"
  echo "$name: $(git -C "$dest" rev-parse --short HEAD)"
done
