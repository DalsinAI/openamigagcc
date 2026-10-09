#!/bin/bash
# build.sh WORK PREFIX NDK_LHA [JOBS]
# Builds OpenAmigaGCC (GCC 16.2 for m68k-amigaos with libnix) into PREFIX from
# the sources fetch.sh put in WORK, with the patches in this repository.
#   NDK_LHA  the AmigaOS 3.2 NDK archive (NDK3.2.lha), which you supply: it is
#            not free software and is never fetched or kept here.
# Nothing is fetched: the build runs without network access when `unshare` can
# take it away, so a missing source stops the build instead of downloading.
# Extra libnix patches can be given in LIBNIX_PATCHES (a folder of *.patch).
# GPL-3.0-or-later, like the patches it goes with. Copyright (c) 2026 Dalsin Limited.
set -euo pipefail
WORK=$(cd "$1" && pwd); PREFIX=$2; NDK=$3; JOBS=${4:-$(nproc)}
HERE=$(cd "$(dirname "$0")/.." && pwd)
mkdir -p "$PREFIX"; PREFIX=$(cd "$PREFIX" && pwd)
LOGS=$WORK/openamigagcc-logs; mkdir -p "$LOGS"
NOFETCH=""
if unshare -n --map-current-user true 2>/dev/null; then NOFETCH="unshare -n --map-current-user"; fi
say() { echo "== $*"; }

# 1. The pinned commits.
grep -v '^#' "$HERE/scripts/sources.lock" | while read -r name url commit dir; do
  [ -n "$name" ] || continue
  have=$(git -C "$WORK/$dir" rev-parse HEAD 2>/dev/null || echo none)
  # gcc and libnix may already carry this repository's patches as commits on top
  if [ "$have" != "$commit" ] && ! git -C "$WORK/$dir" merge-base --is-ancestor "$commit" HEAD 2>/dev/null; then
    echo "$name is at $have, not $commit (scripts/sources.lock)"; exit 1
  fi
done

# 2. Patches, each applied once: WORK/.openamigagcc-applied lists the ones in.
STAMP=$WORK/.openamigagcc-applied; touch "$STAMP"
apply() {   # apply DIR PATCH...
  local d=$1; shift
  for p in "$@"; do
    [ -f "$p" ] || continue
    local id; id="$(basename "$p") $(sha256sum < "$p" | cut -c1-16)"
    if grep -qxF "$id" "$STAMP"; then echo "already in: $(basename "$p")"; continue; fi
    git -C "$d" apply --check "$p" 2>/dev/null || { echo "does not apply: $p"; exit 1; }
    git -C "$d" apply "$p"; echo "$id" >> "$STAMP"; echo "applied $(basename "$p")"
  done
}
say patches
apply "$WORK/projects/gcc" "$HERE"/patches/gcc/*.patch
apply "$WORK" "$HERE"/patches/amiga-gcc/*.patch
apply "$WORK/projects/libnix" "$HERE"/patches/libnix/*.patch ${LIBNIX_PATCHES:+"$LIBNIX_PATCHES"/*.patch}
cp "$HERE"/sys-include/*.h "$WORK/sys-include/"
# Roadshow's bsdsocket.h and usergroup.h inlines (amiga-netinclude, installed
# beside the NDK's) clobber registers their arguments sit in; GCC 16 refuses
# that. Make those registers dummy outputs (idempotent).
python3 "$HERE/scripts/fix_inline_clobbers.py" "$WORK"/projects/amiga-netinclude/include/inline/*.h

# 3. The NDK, from you.
mkdir -p "$WORK/download"
[ -f "$WORK/download/NDK3.2.lha" ] || cp "$NDK" "$WORK/download/NDK3.2.lha"

# 4. libnix's headers go in first: with no -mcrt the driver means -mcrt=nix20
#    (patch 0001), which looks for them, and libnix's own build has files
#    compiled without -mcrt.
mkdir -p "$PREFIX/m68k-amigaos/libnix/include"
rsync -a --no-group "$WORK/projects/libnix/sources/headers/" "$PREFIX/m68k-amigaos/libnix/include/"

# 5. The toolchain: binutils, GCC, libnix, libpthread, the NDK's headers and
#    libraries.
say "amiga-gcc (logs in $WORK/log)"
( cd "$WORK" && $NOFETCH make -j"$JOBS" binutils gcc gprof libnix libpthread ndk ndk13 \
    PREFIX="$PREFIX" THREADS=posix NDK=3.2 CFLAGS_FOR_TARGET="-O2 -fomit-frame-pointer" ) > "$LOGS/make.log" 2>&1 || true
grep -aE '(make|install) [a-z0-9 ]*\.\.\.(done|failed)' "$LOGS/make.log" | sed 's/\x1b\[[0-9;]*[mK]//g' | sort -u
for d in binutils/_done gcc/_done libnix/_done libpthread/_done; do
  [ -f "$WORK/build-Linux-m68k-amigaos/$d" ] || { echo "the amiga-gcc build stopped at ${d%/_done} (see $LOGS/make.log and $WORK/log)"; exit 1; }
done

# 6. libgcc, libstdc++ and the other target libraries, against libnix's
#    headers, so libstdc++'s configure sees C99 maths, dirent and chdir.
say "target libraries against libnix"
T=$PREFIX/m68k-amigaos
FFT="-B$T/bin/ -B$T/lib/ -B$T/libnix/lib/ -isystem $T/include -isystem $T/libnix/include -isystem $T/ndk-include -isystem $T/sys-include"
B=$WORK/build-Linux-m68k-amigaos/gcc
( cd "$B" && $NOFETCH make -j"$JOBS" all-target FLAGS_FOR_TARGET="$FFT" && $NOFETCH make install-target FLAGS_FOR_TARGET="$FFT" ) > "$LOGS/target-libs.log" 2>&1 \
  || { echo "target libraries failed (see $LOGS/target-libs.log)"; exit 1; }
# fenv.h (sys-include) is header-only: tell libstdc++ it is there.
for f in $(find "$PREFIX/lib/gcc/m68k-amigaos" -path "*include/c++*" -name c++config.h); do
  for d in _GLIBCXX_HAVE_FENV_H _GLIBCXX_USE_C99_FENV _GLIBCXX_USE_C99_FENV_TR1; do
    grep -q "define $d 1" "$f" || sed -i "s|^/\* #undef $d \*/|#define $d 1|" "$f"
  done
done

# 6b. libnix4.a (the static part of the shared libnix, for -mcrt=library). The
#     shared libnix4.library itself does not link (a duplicate
#     __vfwprintf_total_size export); static programs don't need it.
echo done > "$WORK/build-Linux-m68k-amigaos/gcc/_libgcc_done"   # step 6 built and installed them
( cd "$WORK" && $NOFETCH make libnix4.library PREFIX="$PREFIX" THREADS=posix NDK=3.2 ) > "$LOGS/libnix4.log" 2>&1 || true
if [ -f "$WORK/build-Linux-m68k-amigaos/libnix/libb/libnix4.a" ]; then
  cp "$WORK/build-Linux-m68k-amigaos/libnix/libb/libnix4.a" "$PREFIX/m68k-amigaos/libnix/lib/libb/"
fi

# 7. Checks.
say checks
CC="$PREFIX/bin/m68k-amigaos-gcc"
C=$LOGS/check; mkdir -p "$C"
printf 'volatile unsigned long s;\nint main(void) { s = *(volatile unsigned long *)0; return 0; }\n' > "$C/nullread.c"
"$CC" -O2 -c -o "$C/nullread.o" "$C/nullread.c"
if "$PREFIX/bin/m68k-amigaos-objdump" -d "$C/nullread.o" | grep -qE 'trap +#7'; then echo "a read of address 0 still compiles to trap #7"; exit 1; fi
printf '#include <stdio.h>\n#include <stdlib.h>\nint main(void) { char *p = calloc(4, 4); printf("hello %%d\\n", p ? p[3] : -1); free(p); return 0; }\n' > "$C/hello.c"
"$CC" -O2 -o "$C/hello" "$C/hello.c" -Wl,-Map,"$C/hello.map"
grep -q 'libnix' "$C/hello.map" || { echo "hello did not link libnix"; exit 1; }
"$PREFIX/bin/m68k-amigaos-g++" -O2 -std=c++23 -o "$C/hellocxx" -x c++ - -x none -lpthread -latomic <<'CXX'
#include <vector>
#include <algorithm>
#include <cstdio>
int main() { std::vector<int> v{3, 1, 2}; std::sort(v.begin(), v.end()); std::printf("%d%d%d\n", v[0], v[1], v[2]); }
CXX
echo "defaults: $("$CC" -### -c -x c /dev/null 2>&1 | grep -o -- '-fno-[a-z-]*' | sort -u | tr '\n' ' ')"
echo "OpenAmigaGCC built in $PREFIX"
