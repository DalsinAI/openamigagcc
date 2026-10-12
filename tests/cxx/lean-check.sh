#!/bin/bash
# lean-check.sh: compile lean.cpp with the lean C++ library profile
# (docs/lean-cxx.md) and fail if the object needs anything the profile forbids.
#   CXX  the compiler (default m68k-amigaos-g++)   NM  its nm (default m68k-amigaos-nm)
# MIT. Copyright (c) 2026 Dalsin Limited.
set -euo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
CXX=${CXX:-m68k-amigaos-g++}; NM=${NM:-m68k-amigaos-nm}
FLAGS=${FLAGS:--m68020 -O2 -fomit-frame-pointer}
PROFILE="-std=gnu++23 -fno-exceptions -fno-rtti -fno-threadsafe-statics -fno-asynchronous-unwind-tables -fno-unwind-tables"
OUT=$(mktemp -d); trap 'rm -rf "$OUT"' EXIT
# shellcheck disable=SC2086
"$CXX" $FLAGS $PROFILE -c -o "$OUT/lean.o" "$HERE/lean.cpp"
syms=$("$NM" "$OUT/lean.o")
# Anything exception, RTTI, static-constructor or guard related, and an
# undefined (libstdc++) operator new or delete; our own, defined here, are fine.
bad=$({ grep -E '__cxa_throw|__cxa_begin_catch|__gxx_personality|_ZTI|_ZTS|_GLOBAL__sub_I_|__cxa_guard|_ZGV|_Unwind_' <<<"$syms"
        grep -E ' U _?_Z(nw|na|dl|da)' <<<"$syms"; } || true)
if [ -n "$bad" ]; then echo "lean.o needs what the profile forbids:"; echo "$bad"; exit 1; fi
echo "lean.o: no exceptions, RTTI, static constructors, guards or libstdc++ new"
