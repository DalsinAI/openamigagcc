#!/bin/bash
# run.sh LIBNIX: runs the nix20 multiply/divide helpers of the 68000 libnix20.a in the prefix
# LIBNIX with UtilityBase NULL, 20000 pairs, on qemu-m68k, and checks every result.
set -e
cd "$(dirname "$0")"
P=${GCC_PREFIX:-/opt/amiga}/bin
T=$(mktemp -d)
(cd $T && $P/m68k-amigaos-ar x $1/m68k-amigaos/libnix/lib/libnix20.a __udivsi3.o __divsi3.o __mulsi3.o)
$P/m68k-amigaos-as -m68020 crt.s -o $T/crt.o
$P/m68k-amigaos-gcc -m68000 -O2 -fno-builtin -c go.c -o $T/go.o
$P/m68k-amigaos-gcc -nostartfiles -nostdlib -o $T/t.srec $T/crt.o $T/go.o $T/__udivsi3.o $T/__divsi3.o $T/__mulsi3.o \
  -Wl,-Ttext=0x10000 -Wl,--oformat=srec
python3 mkelf.py $T/t.srec $T/t.elf && chmod +x $T/t.elf
qemu-m68k -cpu m68040 $T/t.elf | python3 check.py
