#!/bin/bash
# cc.sh LIBNIX OUT [gcc args...]
# Compiles and links with the GCC 16.2 m68k-amigaos compiler in $GCC_PREFIX (default /opt/amiga),
# but against the libnix installed in the prefix LIBNIX (the directory holding m68k-amigaos/libnix).
# The driver puts its own libnix directories first on the link line, so the libraries are named in full.
set -e
LIBNIX=$1; OUT=$2; shift 2
G=${GCC_PREFIX:-/opt/amiga}/bin/m68k-amigaos-gcc
N=$LIBNIX/m68k-amigaos/libnix/lib
md=$($G "$@" -print-multi-directory)
d=$md; while [ ! -e $N/$d/libnix20.a ]; do d=$(dirname $d); done
stubs=$N/$d/libstubs.a; [ "$d" = "." ] && stubs=$LIBNIX/m68k-amigaos/lib/libstubs.a
exec $G -B$N/ -nodefaultlibs -fno-delete-null-pointer-checks "$@" -o "$OUT" \
  -Wl,-\( $N/$d/libnix20.a $N/$d/libnixmain.a $N/$d/libnix.a $stubs -lamiga -lgcc -Wl,-\)
