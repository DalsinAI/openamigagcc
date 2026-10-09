# Loop distribution stays on

**Changed by** `patches/gcc/0009-amigaos-loop-distribution-stays-on-by-default.patch`
(it undoes the third default of `0006`) and `scripts/build.sh` (libnix is built
without loop distribution).

## What went wrong

`0006` made the driver add `-fno-tree-loop-distribute-patterns` to every
compile. The option stops GCC turning a loop into a call to `memset`, `memcpy`
or `memmove`. Two reasons were given for it:

- a C library's own `memset` written as a loop would call itself;
- a "shift up" loop became a `memmove` that copied forwards (the bug `0004`
  fixed).

With `0004` the second is gone. The first only concerns code that defines its
own `memcpy`, `memmove`, `memset` or `calloc`. For everyone else the default
cost speed: on the lab AC090 the shift-up loop ran 3.0 to 3.8 times slower
and a sorted-insert loop 1.2 to 1.3 times slower than with loop distribution
on, because the loop moved one long word per iteration where the block move
uses unrolled `move.l` runs.

| GccBench, best of 5 to 8 runs, microseconds | GCC 16.2.0b as released | 0006-0008 (off by default) | 0009 (on) |
| --- | --- | --- | --- |
| shift-up loop | 811 | 2505 | 821 |
| sorted insert | 3972 | 4898 | 3803 |
| sprintf, strlen, memcpy | 16360 | 16135 | 18851 (second run 16899) |

The other benchmarks (crc32, sieve, qsort, matrix) agree within the run-to-run
noise of the emulated machine, about 10 percent. The string row is that noise:
libnix's sprintf, strlen and memcpy code is the same in all three builds (a
comparison of every libnix object finds four unrelated loops different), and
the program's own string loop compiles to the same code.

## The change

- The driver adds only `-fno-delete-null-pointer-checks` and
  `-fno-malloc-memset-to-calloc`.
- `scripts/build.sh` builds libnix (and libpthread) with
  `-fno-tree-loop-distribute-patterns` (`CFLAGS_FOR_TARGET`). libnix is the
  library that defines `memcpy`, `memmove`, `memset`, `calloc`, `bcopy`,
  `bzero`, `mempcpy` and `wmemcpy`/`wmemmove`/`wmemset`. Its sources are
  written so that none of them calls itself today (they use `CopyMem` and
  inline assembler); the option keeps it so. The build's last step checks
  every one of those objects for a call to itself or to a block function.
- Anyone else who writes a C library with its own `mem*` or `calloc` as a loop
  adds `-fno-tree-loop-distribute-patterns` to that library's flags.
- The positive and the negative option both still work on the command line.

## Reproducers

`tests/repro/prove.sh` runs every reproducer with the defaults and with
`-fno-tree-loop-distribute-patterns`. `tests/repro/selfmem.c` is a `memset`
written with a helper loop: built with `-fno-tree-loop-distribute-patterns` it
stays a loop; without the option (and with loop distribution on) the helper
calls `memset` and `memset` calls the helper.
