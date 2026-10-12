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
| Loop distribution off by default (patch 0006) made shift-up and sorted-insert loops 3.8 and 1.3 times slower on the AC090 | GCC driver default | fixed: on again ([docs](docs/loop-distribution.md)) |
| `-resident32` alone links the plain `libm020` libraries | GCC multilib setup | fixed ([docs](docs/resident32-multilib.md)) |
| A 64-bit libcall argument pushed from a stack slot reads the wrong word (`-m68040`/`-m68060` tuning) | GCC m68k back end | fixed ([docs](docs/push64-stack-slot.md)) |
| Roadshow's socket inlines are refused by GCC 16 (argument registers in the clobber list) | amiga-netinclude headers | fixed by the recipe ([docs](docs/netinclude-inline-clobbers.md)) |
| `__stack` doesn't give a program its stack; the stack swap clobbers A2 (80000004) | libnix | fixed: `patches/libnix/0001` ([docs](docs/libnix-stack-swap.md)) |
| Plain `-fbaserel32` programs never return to the Shell (they return the stack size) | libnix start code | fixed: `patches/libnix/0002` ([docs](docs/libnix-baserel32-exit.md)) |
| A program's own `UtilityBase`, still NULL, crashes 32-bit multiply/divide (80000004) | libnix | fixed: `patches/libnix/0003` ([docs](docs/libnix-utilitybase.md)) |
| Soft-float doubles (`-m68060`, or `-m68020` without `-m68881`) rounded to single precision on an Amiga with an FPU: OS 3.2's IEEE libraries set FPCR when libnix opens them | libnix start code | fixed: `patches/libnix/0004` ([docs](docs/libnix-fpcr.md)) |
| A thread that was running when a later thread was created reads freed memory as it ends: C++ `thread_local` or `call_once` in several threads crashes (80000003, 80000006) or hangs | libpthread (aros-stuff) | fixed: `patches/aros-stuff/0001` ([docs](docs/pthreads-thread-table.md)) |
| `pthread_detach` was a stub (`std::thread::detach` threw "No such process"); a detached thread's slot was never given back; `pthread_join` returned errors with its semaphore held, hanging the next pthread call | libpthread (aros-stuff) | fixed: `patches/aros-stuff/0002` (amigachrome-stoves' t19) |
| A `thread_local`'s destructor never ran (namespace scope or static member): GCC registers it only with `-fuse-cxa-atexit`, and libnix had no `__cxa_atexit` or `__dso_handle` | GCC default, libnix | fixed: `-fuse-cxa-atexit` by default (`patches/gcc/0010`), `__cxa_atexit` and `__dso_handle` in libnix (`patches/libnix/0005`) ([docs](docs/cxa-atexit.md)) |
| C++ streams formatting or reading numbers in several threads at once hang the program or the system (amigachrome-stoves' t18): libstdc++ calls `setlocale()` for every number, and libnix's `setlocale()` freed its returned name and closed the locale in use on every call | libnix | fixed: `patches/libnix/0006` ([docs](docs/libnix-setlocale.md)) |
| C++ startup in base-relative programs read the exception-frame and constructor lists through A4, but they are in the code hunk: `-fbaserel` C++ failed to link, `-fbaserel32` C++ hung before `main` | libnix | fixed: `patches/libnix/0007` ([findings](tests/baserel/FINDINGS.md)) |
| A new thread in a base-relative program ran with no A4 of its own and hung reading its first global | libpthread (aros-stuff) | fixed: `patches/aros-stuff/0005` ([findings](tests/baserel/FINDINGS.md)) |

Each fix comes with a small reproducer that is wrong on the old compiler and right on the new one: `tests/repro/prove.sh` runs the GCC ones and libnix's FPCR one under `qemu-m68k`, the other libnix ones are in `tests/libnix/`, and the libpthread one is `tests/pthreads/t3race.cpp`. How to build: [docs/building.md](docs/building.md).

C++ destructors are registered the C++ ABI's way (`-fuse-cxa-atexit`, patch 0010): `thread_local` destructors run, and static objects are destroyed in the reverse order of construction, interleaved with `atexit()` functions. `-fno-use-cxa-atexit` gives the old way back.

The Open family's libraries and apps use a lean C++ (no exceptions, no RTTI, no static constructors in libraries, C at each library's entry points): [docs/lean-cxx.md](docs/lean-cxx.md). `tests/cxx/lean-check.sh` checks a build against it.

The driver adds two safe defaults, each of which a build can turn back on with the positive option: `-fno-delete-null-pointer-checks` and `-fno-malloc-memset-to-calloc`. Loop distribution stays on (patch 0009): with the memmove fix it is correct, and a shift or insert loop that becomes one block move runs several times faster than the loop. A library that defines its own `memcpy`, `memmove`, `memset` or `calloc` as a loop builds with `-fno-tree-loop-distribute-patterns` (libnix's build does), or the loop becomes a call to itself.

## Mixing compilers

Programs built with GCC 6.5 (the older `os32` stove) calling libraries built with GCC 16 must avoid struct returns (GCC 6.5 passes the address in A0, GCC 16 in A1) and assume `-m68881` for floating point. See `docs/abi-notes.md`.

## Licence

GCC is GPL-3.0 (with the GCC Runtime Library Exception), and the patches to it here are GPL-3.0 too; see `LICENSE`. libnix's patches follow libnix's own licence, and the libpthread patch follows aros-stuff's pthreads licence (zlib-style). No AmigaOS NDK or other non-free files are kept here; the build recipe expects the NDK to be supplied separately.

Part of the Open family by the Team · github.com/DalsinAI
