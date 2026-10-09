# A 64-bit argument pushed from a stack slot read the wrong word

**Fixed by** `patches/gcc/0008-m68k-a-DImode-shift-by-32-pushed-from-a-stack-slot-r.patch`.

## What went wrong

For a 64-bit libcall such as `(s64)m * 4294967296 / det` (`__divdi3`), GCC
pushes the argument `m << 32` in two halves: first the zero low word, then
`m`'s low word as the high word. When `m` was in a stack slot, `(sp,N)`, the
split that makes the two pushes addressed the second one as if the first had
not moved the stack pointer. It read the word 4 bytes below `m`'s low word
(its sign word), so the quotient was 0 or -1.

GCC chooses that push sequence when tuning for the 68040 or 68060 without a
frame pointer: `-m68040`, `-m68060` or `-m68020 -mtune=68040` at `-O1`,
`-O2` and `-Os`. `-fno-omit-frame-pointer`, `-mtune=68020` and `-O0` hid it.
OpenGPU's affine compositing (ops 5 and 6 of its v1.2 golden scene) came out
wrong; any `-m68040` or `-m68060` program doing 64-bit division by such a
value was exposed.

## The fix

The second push now reads the stack slot where it is after the first push.
The split for storing `(u64)x >> 32` through a post-increment had the
mirror-image problem and gets the same correction.

## Reproducer

`tests/repro/push64.c` is OpenGPU's 64-bit affine arithmetic, reduced.

| Compiler | `-O1 -m68040` | `-O1`, `-O2`, `-Os` with `-m68060` | OpenGPU golden v1.2 at `-O2 -m68040` |
| --- | --- | --- | --- |
| GCC 16.2.0b as released | wrong (3 of 9 values) | wrong (2 or 3 of 9) | wrong (ops 5 and 6) |
| OpenAmigaGCC | right | right | right |

The same fault showed with `-m68060 -O2` in the inverse matrix of OpenGPU's affine code (`i11` became 0): the high word of `m << 32` was read from the sign half of the sign-extended `m`'s stack slot, `move.l 64(sp),-(sp)` after three pushes where `68(sp)` is right.
