#!/bin/bash
# fetch-ndk.sh DEST: downloads the AmigaOS 3.2 NDK named in scripts/ndk.lock
# into DEST and checks its sha256. For CI: the NDK is not free software and is
# never kept in this repository or in a release.
# GPL-3.0-or-later. Copyright (c) 2026 Dalsin Limited.
set -euo pipefail
DEST=$1; HERE=$(cd "$(dirname "$0")" && pwd)
read -r name url sum < <(grep -v '^#' "$HERE/ndk.lock" | grep -m1 .)
mkdir -p "$DEST"
curl -fsSL --retry 4 --retry-delay 5 -o "$DEST/$name" "$url"
have=$(sha256sum "$DEST/$name" | cut -d' ' -f1)
if [ "$sum" = unpinned ]; then
  echo "::warning::$name is not pinned in scripts/ndk.lock; its sha256 is $have"
elif [ "$have" != "$sum" ]; then
  echo "$name: sha256 $have, scripts/ndk.lock says $sum"; exit 1
fi
echo "$DEST/$name ($have)"
