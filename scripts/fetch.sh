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
clone() {   # clone COMMIT DEST URL...: clone (no checkout) the first URL that answers and has COMMIT
  local commit=$1 dest=$2 first=$3 err u; shift 2
  for u in "$@"; do
    rm -rf "$dest"
    if err=$(git clone -q --no-checkout "$u" "$dest" 2>&1) &&
       { git -C "$dest" cat-file -e "$commit^{commit}" 2>/dev/null ||
         err=$(git -C "$dest" fetch -q --depth 1 origin "$commit" 2>&1); }; then
      [ "$u" = "$first" ] || say warning "$commit: cloned from $u"
      return 0
    fi
    say warning "$u: $err"
  done
  rm -rf "$dest"; say error "no source answered with $commit: $*"; return 1
}
grep -v '^#' "$HERE/sources.lock" | while read -r name url commit dir; do
  [ -n "$name" ] || continue
  dest="$WORK/$dir"
  src=$url; [ -z "$MIRROR" ] || src="$MIRROR/$dir"
  # bebbo's repositories are on franke.ms; when it does not answer, copies of
  # them elsewhere are tried, and only one that has the pinned commit is used.
  alt=
  case $src in https://franke.ms/git/bebbo/*)
    r=${src#https://franke.ms/git/bebbo/}
    alt="https://codeberg.org/bebbo/$r https://zff.dev/bebbo/$r https://github.com/AmigaPorts/$r" ;;
  esac
  if [ -d "$dest/.git" ]; then
    echo "$name: already in $dest"
  elif [ "$dir" = . ]; then
    clone "$commit" "$WORK/.amiga-gcc-clone" "$src" $alt
    mv "$WORK/.amiga-gcc-clone/.git" "$WORK/.git" && rmdir "$WORK/.amiga-gcc-clone"
    git -C "$WORK" checkout -q "$commit"
  else
    mkdir -p "$(dirname "$dest")"
    clone "$commit" "$dest" "$src" $alt
  fi
  git -C "$dest" cat-file -e "$commit^{commit}" 2>/dev/null || git -C "$dest" fetch -q --depth 1 origin "$commit"
  git -C "$dest" -c advice.detachedHead=false checkout -q "$commit"
  echo "$name: $(git -C "$dest" rev-parse --short HEAD)"
done
