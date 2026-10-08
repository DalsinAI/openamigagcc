# libnix: `__stack` doesn't give a program its stack

**Patch:** `patches/libnix/0001-swapstack-move-the-stack-in-assembler-a-__stack-defi.patch`
**Reproducer:** `tests/libnix/stackdeep.c` (and `cxx.cpp`)

## Symptom

libnix documents that a program asks for its stack with one line:

```c
unsigned long __stack = 300000;
```

With the GCC 16.2 stove's libnix this did two wrong things:

1. **Nothing happened.** A program defining only `__stack` still ran on the 4 KB a default Shell gives it. Nothing referenced the swap module (`swapstack.o` in `libnix20.a`), so the linker never took it out of the library.
2. **Pulling the module in crashed.** The old workaround, naming `__stkinit` as well (`void *__x = __stkinit;`), linked the swap. The program then ran `main()` on the new stack, but exit went wrong: Software Failure 80000004, or the program never returned to the Shell.

## Cause

`__stkinit` kept the new stack's top in A2 (`register UWORD *upper asm("a2")`) across its call to `__MyStackSwap`. That function loads A2 and A6 with its own values and doesn't save them, though both are registers a callee must preserve. So `__SaveSP`, the stack pointer exit returns through, was moved by `&stack - stk_Upper`, not by the distance the stack had moved.

## Fix

- **The move is one assembler routine,** `__stkmove(lower, upper, &__SaveSP, top)`:
  - it copies the live stack below the new top, swaps `tc_SPLower`/`tc_SPUpper` and moves `sp` under `Disable()`;
  - it adds the distance to `__SaveSP`, and to A5 when a frame pointer points into the moved stack (a libnix built without `-fomit-frame-pointer`);
  - it saves every register it uses and reaches no global, so it is the same code in every variant (plain, `-fbaserel`, `-fbaserel32`, resident).

  No register, frame or pointer chosen by the compiler lives across the switch. `__stkexit` moves back the same way, copying only what lies below `__SaveSP` (the old stack above it was never touched), then frees the new stack.
- **Defining `__stack` is enough.** Every start code (`ncrt0`, `nbcrt0`, `nlbcrt0`, `nrcrt0`, `nlrcrt0`) now references `__stkinit`, so the swap module is always linked. A default `unsigned long __stack = 0;` (keep the stack the program was started with) sits in an object of its own, `__stack.o`, which a program's own definition replaces. Programs that don't define `__stack` don't swap. Each program grows by about 650 bytes.
- `detach.o` can still be linked with it: its init runs first (an object comes before the libraries). The parent never returns from it, and the child gets exactly `__stack`, so no swap happens there.

## Results

The tests ran on AmigaOS 3.2.3 (68040) under AmigaChrome, from a Shell with `Stack 4096` and from Workbench (`wbgo`, an icon with a 4096-byte stack). `stackdeep` checks the stack it runs on, then recurses about 190 KB deep.

| Test | Old libnix | Patched |
| --- | --- | --- |
| `__stack` only, `-O0` and `-O2`, Shell | runs on 4096 bytes (FAIL) | 300000 bytes, recursion done, rc 0 |
| same, from Workbench | 4096 bytes (FAIL) | 300000 bytes, rc 0 |
| `__stack` + `__stkinit` named (`-DFORCE`) | `main` runs on the new stack, then never returns | 300000 bytes, rc 0 |
| `-fbaserel`, `-fbaserel32`, `-resident`, `-resident32`, `-m68000`, `-mcrt=nix13` | 4096 bytes (FAIL) | 300000 bytes, rc 0 (Shell and Workbench) |
| C++: static constructor, exception, `__stack` | 4096 bytes | 200000 bytes, all PASS |
| Shell `Stack 400000` (already bigger) | – | no swap, runs on 400000 bytes |
| `Avail FLUSH TOTAL` before and after three runs | – | the same |

## Running the reproducers

```bash
GCC_PREFIX=/opt/amiga tests/libnix/build.sh OLD_PREFIX NEW_PREFIX out
```

`OLD_PREFIX` and `NEW_PREFIX` are prefixes holding an unpatched and a patched libnix install (`make -f Makefile.gcc6 ... install PREFIX=...`). Copy `out/` to the Amiga, then run each program from a Shell with `Stack 4096`, and through `wbgo` with a tool icon whose stack is 4096. Each one appends a line to `DH1:Lab/results.log`; change the path in `stackdeep.c` for another disk.
