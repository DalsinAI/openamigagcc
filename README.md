# OpenAmigaGCC

GCC 16.2 for AmigaOS 3.x (`m68k-amigaos`), with the Team's fixes. This is the compiler behind AmigaChrome's `os32-gcc16` stove and the Open family's builds.

It builds on bebbo's amiga-gcc line (GCC for `m68k-amigaos` with libnix) and adds patches for bugs the Team has found and proved while building the Open family. The patches, the build recipe and the notes are here; GCC's and libnix's own sources are fetched from their upstreams by the recipe.

## Status

**Release candidate, 9 October 2026.** The fixes below are proved in a lab build; `16.2.0-open1` is being prepared and is not released yet.

| Bug | Where | Status |
| --- | --- | --- |
| `-m68040` float-to-int saves FPCR into the register the store's address indexes with | GCC m68k back end | fixed ([docs](docs/fpcr-clash.md)) |
| An overlapping memmove of constant size copies forwards: shift-up loops at `-O2`, `__builtin_memmove` and `std::copy_backward` at any `-O` | GCC m68k back end | fixed ([docs](docs/memmove-direction.md)) |
| Provable NULL reads become `trap #7` (Software Failure 80000027) | GCC default (`-fdelete-null-pointer-checks`) | driver default changed ([docs](docs/null-trap7.md)) |
| A function's own `calloc` (malloc + memset) is turned into a call to `calloc`, recursing | GCC middle end | fixed, and off by default ([docs](docs/calloc-recursion.md)) |
| `-resident32` alone links the plain `libm020` libraries | GCC multilib setup | fixed ([docs](docs/resident32-multilib.md)) |
| A 64-bit libcall argument pushed from a stack slot reads the wrong word (`-m68040`/`-m68060` tuning) | GCC m68k back end | fixed ([docs](docs/push64-stack-slot.md)) |
| Roadshow's socket inlines are refused by GCC 16 (argument registers in the clobber list) | amiga-netinclude headers | fixed by the recipe ([docs](docs/netinclude-inline-clobbers.md)) |
| `__stack` doesn't give a program its stack; the stack swap clobbers A2 (80000004) | libnix | fixed: `patches/libnix/0001` ([docs](docs/libnix-stack-swap.md)) |
| Plain `-fbaserel32` programs never return to the Shell (they return the stack size) | libnix start code | fixed: `patches/libnix/0002` ([docs](docs/libnix-baserel32-exit.md)) |
| A program's own `UtilityBase`, still NULL, crashes 32-bit multiply/divide (80000004) | libnix | fixed: `patches/libnix/0003` ([docs](docs/libnix-utilitybase.md)) |

Each fix comes with a small reproducer that is wrong on the old compiler and right on the new one: `tests/repro/prove.sh` runs the GCC ones under `qemu-m68k`, and the libnix ones are in `tests/libnix/`. How to build: [docs/building.md](docs/building.md).

The driver adds three safe defaults, each of which a build can turn back on with the positive option: `-fno-delete-null-pointer-checks`, `-fno-malloc-memset-to-calloc` and `-fno-tree-loop-distribute-patterns`. The last is no longer needed for correctness (the memmove fix covers it), but it keeps a program's own `memset`/`memcpy` loops from becoming calls to themselves.

## Mixing compilers

Programs built with GCC 6.5 (the older `os32` stove) calling libraries built with GCC 16 must avoid struct returns (GCC 6.5 passes the address in A0, GCC 16 in A1) and assume `-m68881` for floating point. See `docs/abi-notes.md`.

## Licence

GCC is GPL-3.0 (with the GCC Runtime Library Exception), and the patches to it here are GPL-3.0 too; see `LICENSE`. libnix's patches follow libnix's own licence. No AmigaOS NDK or other non-free files are kept here; the build recipe expects the NDK to be supplied separately.

Part of the Open family by the Team · github.com/DalsinAI
