# -m68040 float-to-int stores through the FPCR register

**Fixed by** `patches/gcc/0003-m68k-early-clobber-the-m68040-fix_trunc-scratch-regi.patch`.

## What went wrong

The 68040 has no `fintrz` in hardware, so with `-m68040` GCC converts a float
to an integer by saving FPCR in a data register, switching to round-to-zero,
storing with `fmove.l` and putting FPCR back. The two scratch registers in the
`fix_trunc` patterns were plain `"=d"`, so GCC could give the saved FPCR the
very register the store's address indexes with:

```
move.b (a0)+,d1            | the index
fmovem.l fpcr,d1           | FPCR saved over it
moveq #16,d2 / or.l d1,d2 / and.w #-33,d2 / fmovem.l d2,fpcr
fmove.l fp0,(a2,d1.l*4)    | stored at FPCR*4, not at the index
fmovem.l d1,fpcr
```

It happened at `-O1` and `-O2`. tiny_jpeg (SDL2_image's JPEG writer) wrote
flat grey pictures. `-m68020 -m68881` and `-m68060` use `fintrz` and were
never affected.

## The fix

Both scratch registers are written before the store, so both are
early-clobbered (`"=&d"`): GCC may no longer give them a register the store's
address uses.

## Reproducer

`tests/repro/fpcr.c` scatters `(int)f[i]` into `out[*ix++]`.
`tests/repro/prove.sh` runs it under `qemu-m68k -cpu m68040` and also scans
the object for a store through the saved register, as `fpcr_check.py` does in
the Open family's builds.

| Compiler | `-O1 -m68040` | `-O2 -m68040` |
| --- | --- | --- |
| GCC 16.2.0b as released | wrong: 64 of 64 values misplaced | wrong: 64 of 64 |
| OpenAmigaGCC | right | right |
