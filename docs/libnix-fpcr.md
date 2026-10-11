# libnix: soft-float doubles rounded to single precision on an FPU Amiga

**Patch:** `patches/libnix/0004-__initlibraries-leave-FPCR-at-0-once-the-libraries-a.patch`
**Reproducer:** `tests/repro/softfloat.c` with `tests/repro/mathieee.s` (qemu-m68k, run by `tests/repro/prove.sh`)

## Symptom

`t7_64bit` built `-m68060 -O2 ... -lm` (soft float) matched the PC on Instance-32 (OS 3.2.3, 68060 with FPU) except two lines:

| Line | Instance-32 | PC |
| --- | --- | --- |
| `u2d`: `(uint64_t)(u2d(x >> 11) / 3.0)` | `00000c22e4500000` | `00000c22e4506728` |
| `d2u`: `d2u(1.5e18)` | `14d1120000000000` | `14d1120d7b160000` |

The same test built `-m68020 -m68881` was right.

## Cause

The conversions themselves are right. libgcc's `__floatundidf`, `__fixunsdfdi`, `__fixunsdfsi` (libm060) and its `__floatunsidf`, `__fixdfsi` (fpgnulib) were checked by disassembly. They do their arithmetic through `__muldf3`, `__adddf3`, `__subdf3` and `__gedf2`. These come from libnix's libm (for `-m68060` the `libm020/libm881` flavour, because the driver passes `-fl libm020 -fl libm881`), and each is one call into `mathieeedoubbas.library`.

On a machine with an FPU, OS 3.2's IEEE libraries set FPCR in the task that opens them. They do it in their Open function, when AttnFlags bit 4 (`AFB_68881`) is set:

- `mathieeedoubbas.library` 47.3 (Libs:) runs `moveq #16,d0; fmove.l d0,fpcr`, which means round toward zero.
- `mathieeesingbas.library` 47.1 (Kickstart 3.2.3 ROM, at `$F85892`) runs `moveq #64,d0; fmove.l d0,fpcr`, which means single precision.
- `mathieeedoubtrans.library` 47.2 leaves FPCR alone.

`mathieeedoubbas`'s FPU code moves the operands into FP0 with `fmove.d`, operates with `fadd.d`/`fsub.d`/`fmul.d`/`fdiv.d`, and moves FP0 back with `fmove.d`. All of that runs under the task's FPCR.

libnix opens every library a program references in the program's own task at startup (`__initlibraries`), in link order. `t7_64bit` also uses floats (`f2s` calls `__ltsf2`, which uses `mathieeesingbas`), so `mathieeesingbas` opens after `mathieeedoubbas`. FPCR is then `$40`, and every double operation is rounded to single precision, operands and result. This model reproduces both wrong lines exactly. A program that uses doubles only gets FPCR `$10` and rounds toward zero, which puts the last bit wrong whenever a result is inexact.

The bug is not specific to the 68060: `-m68020` soft-float builds (libnix's plain `libm020/libm.a`) give the same wrong values on a machine with an FPU. `-m68881` builds do their arithmetic inline and don't open these libraries, so they were right. They inherit FPCR from the Shell's process, though, which keeps whatever the previous program left (`$40` after a soft-float program, `$10` after rexxsyslib).

## Fix

When AttnFlags shows an FPU, `__initlibraries` now sets FPCR to 0 once the libraries are open: round to nearest, extended precision, no exception enabled. That is the FPU's reset value, and what C expects at program start. It also matches the platform rule the Team already follows ("set FPCR to 0 when doubles matter"). On a machine without an FPU nothing changes.

## Results

`tests/repro/prove.sh` with the live os32-gcc16 stove. The second run links the patched `__initlibraries.o` (libm020 flavour) ahead of the stove's libnix, through `NIXOBJ`:

| Reproducer | Stove libnix | Patched `__initlibraries.o` |
| --- | --- | --- |
| `[-O2 -m68060] softfloat` (qemu `-cpu m68060`) | WRONG: 14 of 21 values wrong, FPCR `$40` | right: 0 of 21, FPCR `$00` |
| `[-O2 -m68020] softfloat` (qemu `-cpu m68040`) | WRONG: 14 of 21 values wrong, FPCR `$40` | right: 0 of 21, FPCR `$00` |
| every other reproducer | right | right |

Values 0 and 1 of the reproducer are t7's two lines. On the stove's libnix they come out as `00000c22e4500000` and `14d1120000000000`, the numbers Instance-32 printed. The 21 values cover uint64 and int64 to and from double and float, below 2^32, near 2^53 and above 2^63. The expected values come from the PC (`gcc -DHOST`). A doubles-only variant gives FPCR `$10` and 2 wrong values (round toward zero) on the stove's libnix, and 0 with the patch.

```bash
tests/repro/prove.sh <stove>/prefix/bin                                  # the stove as it is
NIXOBJ=/path/to/__initlibraries.o tests/repro/prove.sh <stove>/prefix/bin   # with a fixed object
```

The full stove rebuild with the patch is still to do. The patched source compiles for the 68000, 68020, `-fbaserel` and `-fbaserel32` flavours. Built the way the stove builds libnix, the unpatched source gives the stove's `__initlibraries.o` instruction for instruction (68020 flavour compared).

## Limits

- `mathieee.s` is a model of the libraries' FPU path and Open side effects, written from their code. qemu-m68k can't run the ROM.
- With FPCR 0, `mathieeedoubbas`'s FPU code rounds to extended and then to double. In rare halfway cases a result can be one in the last place away from a correctly rounded double, as `-m68881` code is. FPCR `$80` would be exact for doubles, but it would cut `long double` and `-m68881` code to double, so the reset value is used.
- A program that opens an IEEE library itself, after startup, gets FPCR changed again. It should set FPCR to 0 afterwards.
- `-mcrt=clib2` and newlib programs don't use libnix's start code. They are not covered.
- Separately: `-m68060` soft-float programs link libnix's `libm881` helpers, which also copy each result into FP0 (`fmove.d`). Such a program therefore needs an FPU, and would take an F-line trap on a 68LC060 or 68EC060. That is not changed here.
