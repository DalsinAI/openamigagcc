# -resident32 linked the wrong libraries

**Fixed by** `patches/gcc/0007-amigaos-resident-and-resident32-pick-the-base-relati.patch`.

`-resident32` compiles as `-fbaserel32` (and `-resident` as `-fbaserel`), but
the multilib choice looked only at `-fbaserel`/`-fbaserel32`. So
`-m68020 -resident32` without `-fbaserel32` linked the plain `libm020` libgcc,
libnix and libstdc++ into base-relative code. The multilib matches now treat
`-resident32` as `-fbaserel32` and `-resident` as `-fbaserel`.

Check: `m68k-amigaos-gcc -m68020 -resident32 -print-multi-directory` prints
`libb32/libm020` (it printed `libm020`).
