# OpenAmigaGCC

GCC 16.2 for AmigaOS 3.x (`m68k-amigaos`), with the Team's fixes. This is the compiler behind AmigaChrome's `os32-gcc16` stove and the Open family's builds.

It builds on bebbo's amiga-gcc line (GCC for `m68k-amigaos` with libnix) and adds patches for bugs the Team has found and proved while building the Open family. The patches, the build recipe and the notes are here; GCC's and libnix's own sources are fetched from their upstreams by the recipe.

## Status

**In progress, 8 October 2026.** The fixes below are being written and proved in a lab build. Nothing here is a release yet.

| Bug | Where | Status |
| --- | --- | --- |
| `-m68040` float-to-int saves FPCR into the register the store's address indexes with | GCC m68k back end | being fixed |
| An overlapping "shift up" loop becomes an inline memmove that copies forwards (`-O2` loop distribution) | GCC m68k back end | being fixed |
| Provable NULL reads become `trap #7` (Software Failure 80000027) | GCC default (`-fdelete-null-pointer-checks`) | driver default being changed |
| A function's own `calloc` (malloc + memset) is turned into a call to `calloc`, recursing | GCC builtin | driver default being changed |
| `__stack` doesn't give a program its stack; the stack swap clobbers A2 (80000004) | libnix | fixed, proved in a lab: `patches/libnix/0001`, `docs/libnix-stack-swap.md` |
| Plain `-fbaserel32` programs never return to the Shell (they return the stack size) | libnix start code | fixed, proved in a lab: `patches/libnix/0002`, `docs/libnix-baserel32-exit.md` |
| A program's own `UtilityBase`, still NULL, crashes 32-bit multiply/divide (80000004) | libnix | fixed, proved in a lab: `patches/libnix/0003`, `docs/libnix-utilitybase.md` |

Each fix comes with a small reproducer that is wrong on the old compiler and right on the new one; see `docs/`. The libnix reproducers are in `tests/libnix/`.

## Mixing compilers

Programs built with GCC 6.5 (the older `os32` stove) calling libraries built with GCC 16 must avoid struct returns (GCC 6.5 passes the address in A0, GCC 16 in A1) and assume `-m68881` for floating point. See `docs/abi-notes.md`.

## Licence

GCC is GPL-3.0 (with the GCC Runtime Library Exception), and the patches to it here are GPL-3.0 too; see `LICENSE`. libnix's patches follow libnix's own licence. No AmigaOS NDK or other non-free files are kept here; the build recipe expects the NDK to be supplied separately.

Part of the Open family by the Team · github.com/DalsinAI
