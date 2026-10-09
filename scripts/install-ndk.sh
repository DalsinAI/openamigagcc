#!/bin/bash
# install-ndk.sh SRC PREFIX NDK3.2.lha
# Puts the AmigaOS 3.2 NDK into an OpenAmigaGCC toolchain at PREFIX: its
# headers into m68k-amigaos/ndk-include (with proto/, inline/ and lvo/ made
# from its SFD files), the 1.3 set into ndk13-include, FD/SFD/link libraries
# into m68k-amigaos/ndk, and Roadshow's network headers beside them.
#   SRC   the amiga-gcc folder of the OpenAmigaGCC source release
#   NDK3.2.lha  the NDK archive you have (Aminet dev/misc/NDK3.2.lha); it is
#               not free software and is not part of OpenAmigaGCC
# Needs lha (lhasa), a host C compiler (for fd2sfd and fd2pragma), make, rsync.
# GPL-3.0-or-later. Copyright (c) 2026 Dalsin Limited.
set -euo pipefail
SRC=$(cd "$1" && pwd); PREFIX=$(cd "$2" && pwd); NDK=$3
HERE=$(cd "$(dirname "$0")" && pwd)
mkdir -p "$SRC/download"
cp "$NDK" "$SRC/download/NDK3.2.lha"
export PATH="$PREFIX/bin:$PATH"
make -C "$SRC" ndk ndk13 netinclude PREFIX="$PREFIX" NDK=3.2
# Roadshow's socket inlines, made acceptable to GCC 16 (docs/netinclude-inline-clobbers.md)
python3 "$HERE/fix_inline_clobbers.py" "$PREFIX"/m68k-amigaos/ndk-include/inline/*.h
echo "NDK 3.2 installed in $PREFIX/m68k-amigaos"
