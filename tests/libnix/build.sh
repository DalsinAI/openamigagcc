#!/bin/bash
# build.sh OLD NEW [OUTDIR]: builds every reproducer twice, against the libnix installed in
# the prefix OLD (unpatched) and in NEW (patched): OUTDIR/<test>-old and OUTDIR/<test>-new.
set -e
cd "$(dirname "$0")"
O=${3:-bin}; mkdir -p $O
GP=${GCC_PREFIX:-/opt/amiga}
for v in old new; do
  [ $v = old ] && L=$1 || L=$2
  ./cc.sh $L $O/stk-O0-$v    -m68020 -m68881 -O0 -DNAME="\"stk-O0-$v\"" stackdeep.c
  ./cc.sh $L $O/stk-O2-$v    -m68020 -m68881 -O2 -DNAME="\"stk-O2-$v\"" stackdeep.c
  ./cc.sh $L $O/stkF-O2-$v   -m68020 -m68881 -O2 -DFORCE -DNAME="\"stkF-O2-$v\"" stackdeep.c
  ./cc.sh $L $O/stk-b32-$v   -fbaserel32 -m68020 -O2 -DNAME="\"stk-b32-$v\"" stackdeep.c
  ./cc.sh $L $O/stk-b16-$v   -fbaserel -m68020 -O2 -DNAME="\"stk-b16-$v\"" stackdeep.c
  ./cc.sh $L $O/stk-r32-$v   -resident32 -fbaserel32 -m68020 -O2 -DNAME="\"stk-r32-$v\"" stackdeep.c
  ./cc.sh $L $O/stk-r16-$v   -resident -fbaserel -m68020 -O2 -DNAME="\"stk-r16-$v\"" stackdeep.c
  ./cc.sh $L $O/stk-000-$v   -m68000 -O0 -DNAME="\"stk-000-$v\"" stackdeep.c
  ./cc.sh $L $O/empty-b32-$v -fbaserel32 -m68020 -O2 empty.c
  ./cc.sh $L $O/rc7-b32-$v   -fbaserel32 -m68020 -O2 -DRC=7 empty.c
  ./cc.sh $L $O/exit5-b32-$v -fbaserel32 -m68020 -O2 -DEXIT=5 empty.c
  ./cc.sh $L $O/rc7-plain-$v -m68020 -O2 -DRC=7 empty.c
  ./cc.sh $L $O/utilbase-$v  -m68000 -O2 utilbase.c
  N=$L/m68k-amigaos/libnix/lib
  $GP/bin/m68k-amigaos-gcc -B$N/ -nodefaultlibs -mcrt=nix13 -m68020 -O2 -fno-delete-null-pointer-checks \
    -DNAME="\"stk-n13-$v\"" stackdeep.c -o $O/stk-n13-$v \
    -Wl,-\( $N/libm020/libnix13.a $N/libm020/libnixmain.a $N/libm020/libnix.a $N/libm020/libstubs.a -lamiga -lgcc -Wl,-\)
  $GP/bin/m68k-amigaos-g++ -B$N/ -nodefaultlibs -fexceptions -m68020 -m68881 -O2 -fno-delete-null-pointer-checks \
    cxx.cpp -o $O/stkcxx-$v \
    -Wl,-\( -lstdc++ -lpthread -latomic $N/libm020/libnix20.a $N/libm020/libnixmain.a $N/libm020/libnix.a \
    $N/libm020/libstubs.a $N/libm020/libm881/libm.a -lamiga -lgcc -Wl,-\) || echo "stkcxx-$v skipped (needs libstdc++ and libpthread)"
done
$GP/bin/m68k-amigaos-gcc -m68020 -O2 -fno-delete-null-pointer-checks wbgo.c -o $O/wbgo
ls $O
