# strcat into a local array wrote to an absolute address

**Fixed by** `patches/gcc/0014-vregs-virtual-registers-inside-an-address-operand-ar.patch`.

## What went wrong

GCC expands `strcat(want, phrase)`, with `phrase` a constant, into a call to
`strlen(want)` and a copy of `phrase` to `want + strlen(want)`. The m68k back
end copies small blocks inline, and loads the destination address with one
`lea`. With `want` a local array that address is, before the frame is laid
out,

```
(plus (plus (reg virtual-stack-vars) (reg 71)) (const_int -600))
```

GCC's vregs pass turns `virtual-stack-vars` into the frame or stack pointer,
but only in operands that are registers or memory. The `lea`'s operand is an
address (`address_operand`, the `"p"` constraint), so it kept the virtual
register; combine then dropped it, and the copy went to
`strlen(want) - 600`, an absolute address:

```
jsr _strlen
move.l d0,a0
add.w #-600,a0             | should be lea 12(sp,d0.l),a0
move.l (a1)+,(a0)+
```

GFOffice's OWFLibTest never built the text it checks `owf_inflate`'s output
against. It showed with `-m68020` and `-m68040` at `-O1` and `-O2`, not with
`-m68000` or at `-Os`; `-fno-builtin-strcat` hid it.

## The fix

The vregs pass now instantiates virtual registers inside an address operand
too, and computes the address into a register if the instruction no longer
takes it. The copy starts with `lea 12(sp,d0.l),a0`, the array plus its
length.

GCC's trunk has the same vregs code and the same `*lea` pattern; no upstream
report was found. Upstream's own expanders put addresses in registers with
`force_operand`, whose additions vregs does handle; the m68k inline block copy
(`m68k2.cc`) is bebbo's.

## Reproducer

`tests/repro/vregs.c` is OWFLibTest's `strcat`, reduced. `tests/repro/prove.sh`
runs it under `qemu-m68k` and checks the `-fdump-rtl-vregs` dump for any
virtual register.

| Compiler | `-O1` vregs dump | `-O2` vregs dump |
| --- | --- | --- |
| GCC 16.2.0b as released (GFOpenAmigaGCC 16.2.0-open3) | wrong: `virtual-stack-vars` left | wrong: `virtual-stack-vars` left |
| GFOpenAmigaGCC with patch 0014 | right: none | right: none |

GFOffice's `tests/library/owf_lib_checks.c`, built as OWFLibTest is (without
`-fno-builtin-strcat`): its vregs dump has no virtual register, and the copy's
`lea (-600,a3),a0` became `lea 1064(sp,d0.l),a0`, `want` plus its length.
