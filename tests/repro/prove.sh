#!/bin/bash
# prove.sh BINDIR [extra flags...]
# Builds each reproducer with BINDIR's m68k-amigaos-gcc/g++ and runs it as a raw
# 68k image under qemu-m68k -cpu m68040; checks the code where running can't
# show the bug (a read of address 0 is not mapped under qemu-m68k).
# Prints one line per reproducer, "right" or "WRONG", and exits 1 if any is wrong.
# Extra flags go to every compile: run it plain (loop distribution is on by
# default) and with -fno-tree-loop-distribute-patterns; the memmove and shift
# reproducers must be right either way.
# NIXOBJ (optional): objects linked ahead of the stove's libnix in the softfloat
# reproducer, such as a fixed __initlibraries.o, to prove a libnix fix before a
# stove rebuild.
# MIT licence, Copyright (c) 2026 AmigaChrome Team.
set -u
B=$1; shift
D=$(cd "$(dirname "$0")" && pwd)
O=${OUT:-$(mktemp -d)}; mkdir -p "$O"
CC="$B/m68k-amigaos-gcc"; CXX="$B/m68k-amigaos-g++"; OBJDUMP="$B/m68k-amigaos-objdump"
bad=0

image() {   # image NAME [CPU [LIBS]]: link $O/NAME.o into $O/NAME.elf
  local n=$1 cpu=${2:--m68040} libs=${3:-}
  "$CC" $cpu -O1 -fno-builtin -c "$D/rt.c" -o "$O/rt.o" || return 2
  "$CC" $cpu -nostartfiles -nostdlib -o "$O/$n.hunk" "$D/crt.s" "$O/$n.o" "$O/rt.o" $libs || return 2
  python3 "$D/mkelf.py" "$O/$n.hunk" "$O/$n.elf" && chmod +x "$O/$n.elf"
}
run() {     # run NAME LABEL [QEMUCPU]: run the image, print its line
  local out; out=$(timeout 20 qemu-m68k -cpu "${3:-m68040}" "$O/$1.elf" 2>&1); local rc=$?
  out=$(printf '%s' "$out" | grep -m1 -E 'right|WRONG' || echo "$2: WRONG (crashed, exit $rc)")
  echo "$out"; case $out in *WRONG*) bad=1;; esac
}
built() {   # built LABEL: a reproducer that did not compile, link or convert is a failure too
  echo "$1: WRONG (did not build)"; bad=1
}

for opt in -O1 -O2 -Os; do
  "$CC" -m68040 $opt "$@" -c "$D/shift.c" -o "$O/shift.o" && image shift && echo -n "[$opt] " && run shift shift || built "[$opt] shift"
  "$CC" -m68040 $opt "$@" -c "$D/memmove.c" -o "$O/memmove.o" && image memmove && echo -n "[$opt] " && run memmove memmove || built "[$opt] memmove"
  "$CXX" -m68040 $opt "$@" -fno-exceptions -c "$D/copyback.cpp" -o "$O/copyback.o" && image copyback && echo -n "[$opt] " && run copyback copy_backward || built "[$opt] copy_backward"
done

# a nested inline library call, Stricmp(FilePart(x), ...), with the NDK's own inline headers
NDKINC="-isystem $B/../m68k-amigaos/ndk-include"
for opt in -O1 -O2 -Os; do
  "$CC" -m68040 $opt "$@" $NDKINC -c "$D/nested.c" -o "$O/nested.o" && image nested && echo -n "[$opt] " && run nested nested || built "[$opt] nested"
done

# 68000: byte copies when the alignment is unknown, and odd sizes backwards
for opt in -O2 -Os; do
  "$CC" -m68000 $opt "$@" -c "$D/shift.c" -o "$O/shift.o" && image shift -m68000 && echo -n "[$opt -m68000] " && run shift shift m68000 || built "[$opt -m68000] shift"
  "$CC" -m68000 $opt "$@" -c "$D/memmove.c" -o "$O/memmove.o" && image memmove -m68000 && echo -n "[$opt -m68000] " && run memmove memmove m68000 || built "[$opt -m68000] memmove"
done

for opt in -O1 -O2; do
  rm -f "$O/fpcr.o"
  "$CC" -m68040 -m68881 $opt "$@" -c "$D/fpcr.c" -o "$O/fpcr.o" 2>/dev/null && image fpcr && echo -n "[$opt -m68040] " && run fpcr fpcr || built "[$opt -m68040] fpcr"
  # and the static check every -m68040 build can run: no float-to-int store through the saved FPCR register
  if [ ! -f "$O/fpcr.o" ]; then built "[$opt -m68040] fpcr code"
  elif "$OBJDUMP" -m m68k:68040 -d "$O/fpcr.o" | awk '
      /fmovel %?fpcr,%?d[0-7]/ { match($0, /d[0-7]$/); r = substr($0, RSTART, 2); next }
      r != "" && /fmovel %?fp[0-7],/ { split($0, a, ","); if (index(substr($0, index($0, ",")), r)) bad = 1; r = "" }
      END { exit bad ? 1 : 0 }'; then echo "[$opt -m68040] fpcr code: right (no store through the FPCR register)"
  else echo "[$opt -m68040] fpcr code: WRONG (a store indexes with the FPCR register)"; bad=1; fi
done

# 64-bit libcall arguments pushed from stack slots, when tuned for the 68040/060
for opt in "-O1 -m68040" "-O2 -m68040" "-O1 -m68060" "-O2 -m68060" "-Os -m68060"; do
  "$CC" $opt "$@" -c "$D/push64.c" -o "$O/push64.o" && image push64 -m68040 -lgcc && echo -n "[$opt] " && run push64 push64 || built "[$opt] push64"
done

# soft-float doubles (-m68060, and -m68040 without -m68881) on a machine with an FPU:
# libnix's own __initlibraries opens the IEEE libraries (mathieee.s models OS 3.2.3's,
# which set the task's FPCR when opened) and must leave FPCR at 0 for their FPU code
NIXLIBS="${NIXOBJ:-} -L$B/../m68k-amigaos/libnix/lib -Wl,--start-group -lm -lnix -lstubs -lgcc -Wl,--end-group"
for c in "-m68060 m68060" "-m68040 m68040"; do
  cpu=${c% *}; qcpu=${c#* }
  # -m68040 soft float links libnix's soft libm020 only with the specs file (docs/m68040-soft-float-link.md)
  sp=; [ "$cpu" = -m68040 ] && sp="-specs=$D/../../build/m68k-soft-m68040.specs"
  "$CC" $cpu $sp -O2 "$@" -c "$D/softfloat.c" -o "$O/softfloat.o" && "$CC" $cpu -c "$D/mathieee.s" -o "$O/mathieee.o" &&
    image softfloat "$cpu $sp" "$O/mathieee.o $NIXLIBS" && echo -n "[-O2 $cpu] " && run softfloat softfloat "$qcpu" || built "[-O2 $cpu] softfloat"
done

rm -f "$O/calloc.o"
"$CC" -m68040 -O2 "$@" -c "$D/calloc.c" -o "$O/calloc.o" && image calloc && echo -n "[-O2] " && run calloc calloc || built "[-O2] calloc"
if [ ! -f "$O/calloc.o" ]; then built "[-O2] calloc code"
elif "$OBJDUMP" -d "$O/calloc.o" | awk '/<_calloc>:/,/rts/' | grep -q 'jsr.*_calloc\|jra.*_calloc\|bsr.*_calloc'; then
  echo "[-O2] calloc code: WRONG (calloc calls calloc)"; bad=1
else echo "[-O2] calloc code: right (calloc doesn't call itself)"; fi

# a library's own memset with a helper loop: -fno-tree-loop-distribute-patterns keeps the loop a loop
for opt in -O2 -Os; do
  rm -f "$O/selfmem.s"
  if ! "$CC" -m68040 $opt "$@" -fno-tree-loop-distribute-patterns -S -o "$O/selfmem.s" "$D/selfmem.c"; then built "[$opt] selfmem"
  elif awk '/^_fill_bytes:/,/rts/' "$O/selfmem.s" | grep -q 'jsr.*_memset\|jbsr.*_memset\|bsr.*_memset'; then
    echo "[$opt] selfmem: WRONG (the helper loop became a call to memset)"; bad=1
  else echo "[$opt] selfmem: right (with -fno-tree-loop-distribute-patterns an own memset loop stays a loop)"; fi
done

for opt in -O2 -Os; do
  rm -f "$O/null.o"
  if ! "$CC" -m68040 $opt "$@" -c "$D/null.c" -o "$O/null.o"; then built "[$opt] null"
  elif "$OBJDUMP" -d "$O/null.o" | grep -qE 'trap +#7'; then echo "[$opt] null: WRONG (trap #7)"; bad=1
  else echo "[$opt] null: right (address 0 is read, no trap #7)"; fi
done
exit $bad
