#!/bin/sh
# Copyright (c) 2026 Dalsin Limited. GPL-3.0-or-later, like the patches it goes with.
# Base-relative C++ with the os32-gcc16 stove: t3_threads.cpp (amigachrome-stoves
# os32-gcc16/tests/src) built three ways.
#   build.sh [OUT]     STOVE: a stove folder with prefix/ and compat/ (default ~/AmigaChrome/stoves/os32-gcc16)
#   t3-plain   links and runs (control)
#   t3-b32     -fbaserel32: links (with "out of range" messages), hangs on the Amiga before any output
#   t3-b16     -fbaserel: does not link (libnix cxxglue.o __init_eh: DREL16 against .list___EH_FRAME_BEGIN)
set -u
HERE=$(cd "$(dirname "$0")" && pwd)
STOVE=${STOVE:-$HOME/AmigaChrome/stoves/os32-gcc16}
OUT=${1:-$HERE/out}
P=$STOVE/prefix/bin/m68k-amigaos-
COMPAT="-L$STOVE/compat -los32compat -Wl,--wrap=malloc -Wl,--wrap=calloc -Wl,--wrap=realloc -Wl,--wrap=free -Wl,-u,___wrap_malloc -Wl,-u,___wrap_free -Wl,-u,___wrap_calloc -Wl,-u,___wrap_realloc"
LIBS="-lpthread -latomic -lstdc++ $COMPAT -fexceptions"
F="-m68020 -m68881 -O2 -fno-delete-null-pointer-checks -fomit-frame-pointer -std=gnu++23"
mkdir -p "$OUT"
for v in plain:"" b32:-fbaserel32 b16:-fbaserel; do
    n=${v%%:*}; f=${v#*:}
    # shellcheck disable=SC2086
    if "${P}g++" $F $f -o "$OUT/t3-$n" "$HERE/t3_threads.cpp" $LIBS > "$OUT/t3-$n.log" 2>&1; then
        echo "t3-$n: linked ($(wc -c < "$OUT/t3-$n") bytes, $(grep -c 'out of range' "$OUT/t3-$n.log") 'out of range' lines)"
    else
        echo "t3-$n: link FAILED:"; grep -v 'out of range' "$OUT/t3-$n.log"
    fi
done
