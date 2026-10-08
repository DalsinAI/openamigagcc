# Overlapping memmove copied forwards

**Fixed by** `patches/gcc/0004-m68k-movmemsi-memmove-copies-overlapping-blocks-the-.patch`.

## What went wrong

Since GCC 10 the `movmem` pattern means memmove: the two blocks may overlap.
The m68k back end's `movmemsi` shared `cpymemsi`'s (memcpy's) forward copy and
only turned it round when both blocks had the same base and constant offsets
in their memory expressions. Everything else was copied forwards with
`move.l (a1)+,(a0)+`. With a constant size, at `-O1`, `-O2` and `-Os`:

- an overlapping "shift up" loop, which loop distribution turns into memmove
  (`-O2`, `-Os`):
  ```c
  for (i = n; i > 0; --i) v[i] = v[i - 1];
  ```
- `__builtin_memmove`, and so code that calls `memmove` without libnix's
  `<string.h>` (which routes it to `bcopy`);
- C++ `std::copy_backward` and `std::move_backward` on trivial types, which
  libstdc++ implements with `__builtin_memmove`.

In each case the first element was smeared over the whole block. OpenCrypto's
sntrup761 broke this way.

`-fno-tree-loop-distribute-patterns` only covers the first case.

## The fix

`movmemsi` now:
- copies backwards (`-(a1),-(a0)` from the ends) when the destination is
  proved to start inside the source: the same base register with constant
  offsets, or the same base pointer found through the SSA pointer arithmetic
  that made the two addresses;
- copies forwards when that is proved safe, including two different declared
  objects;
- otherwise compares the two addresses at run time and runs a forward or a
  backward copy. At `-Os` it calls `memmove` instead, which is smaller.

A backward copy moves the odd trailing bytes first, so its long words sit
where a forward copy's do (aligned on a 68000). `cpymemsi` (memcpy) is
unchanged.

## Reproducers

- `tests/repro/shift.c`: the shift-up loop on `int`, `char` and `short` arrays.
- `tests/repro/memmove.c`: `__builtin_memmove` up and down, proved and
  run-time directions, odd sizes and addresses.
- `tests/repro/copyback.cpp`: `std::copy_backward`.

`tests/repro/prove.sh` runs them under `qemu-m68k` at `-O1`, `-O2` and `-Os`
(and at `-m68000`).

| Compiler | shift | memmove | copy_backward | 68000 shift / memmove |
| --- | --- | --- | --- | --- |
| GCC 16.2.0b as released | wrong at -O2, -Os | wrong at -O1, -O2, -Os | wrong at -O1, -O2, -Os | wrong |
| OpenAmigaGCC | right | right | right | right |
| OpenAmigaGCC with `-ftree-loop-distribute-patterns` | right | right | right | right |
