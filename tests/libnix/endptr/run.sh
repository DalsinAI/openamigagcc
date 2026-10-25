#!/bin/bash
# Execute the native fourteen-case control with real built libnix objects.
# Raw 68040/qemu: this checks conversion, not AmigaOS startup or errno TLS.
set -euo pipefail
B=$(cd "$1" && pwd)
D=$(cd "$(dirname "$0")" && pwd)
O=$(mktemp -d)
trap 'rm -rf "$O"' EXIT
CC="$B/m68k-amigaos-gcc"
LIB="$B/../m68k-amigaos/libnix/lib/libm020/libnix.a"
(cd "$O" && "$B/m68k-amigaos-ar" x "$LIB" strtol.o strtoul.o _ctype_.o iswxdigit.o)
for file in strtol strtoul _ctype_ iswxdigit; do test -s "$O/$file.o"; done
"$CC" -m68040 -m68881 -O2 -fno-builtin -c "$D/../strtol_endptr.c" -o "$O/probe.o"
"$CC" -m68040 -O2 -fno-builtin -c "$D/raw_support.c" -o "$O/support.o"
"$CC" -m68040 -O2 -fno-builtin -c "$D/../../repro/rt.c" -o "$O/rt.o"
"$CC" -m68040 -nostartfiles -nostdlib -o "$O/probe.hunk" \
    "$D/../../repro/crt.s" "$O/probe.o" "$O/support.o" "$O/rt.o" \
    "$O/strtol.o" "$O/strtoul.o" "$O/_ctype_.o" "$O/iswxdigit.o"
python3 "$D/../../repro/mkelf.py" "$O/probe.hunk" "$O/probe.elf"
chmod +x "$O/probe.elf"
timeout 20 qemu-m68k -cpu m68040 "$O/probe.elf"
echo 'strtol/strtoul: fourteen value/end-pointer controls passed (built libnix, raw 68040)'
