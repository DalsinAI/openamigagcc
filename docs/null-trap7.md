# Provable NULL reads become trap #7

**Fixed by** the driver default in `patches/gcc/0006-amigaos-safe-defaults-in-the-driver-null-checks-call.patch`.

Address 0 is memory on a 68k Amiga: chip RAM, with exec's base pointer at 4.
GCC assumes nothing lives there. At `-O2` and `-Os` it replaces a read through
a pointer it has proved null with `trap #7`, which AmigaOS reports as Software
Failure 80000027, and it drops null checks that follow a read.

OpenAmigaGCC's driver adds `-fno-delete-null-pointer-checks` unless a build
passes `-fdelete-null-pointer-checks`. The default is built into the driver
(`DRIVER_SELF_SPECS`), not a `specs` file: a `specs` file beside libgcc
replaced the driver's `-mcrt` link setup, and programs lost libnix.

## Reproducer

`tests/repro/null.c` reads address 0. The read can't be run under qemu-m68k
(address 0 isn't mapped in user mode), so `prove.sh` checks the code.

| Compiler | `-O2` | `-Os` |
| --- | --- | --- |
| GCC 16.2.0b as released | wrong: `trap #7` | wrong: `trap #7` |
| OpenAmigaGCC | right: address 0 is read | right |
