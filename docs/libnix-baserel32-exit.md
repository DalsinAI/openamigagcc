# libnix: plain `-fbaserel32` programs never return to the Shell

**Patch:** `patches/libnix/0002-nlbcrt0-read-the-exit-code-before-restoring-sp.patch`
**Reproducer:** `tests/libnix/empty.c`

## Symptom

A program linked plain `-fbaserel32` (start code `nlbcrt0.o`) seemed never to return to the Shell, even with an empty `main()`. `-resident32` programs and 16-bit `-fbaserel` programs returned normally.

## Cause

`nlbcrt0`'s exit path restored `sp` from `__SaveSP` first and then read the exit code at `sp@(4)`. That address is above the saved stack pointer, where the Shell keeps the stack size. So every plain `-fbaserel32` program returned its stack size, whatever `main()` returned or `exit()` was given: 4096 from a default Shell.

A script with `FailAt` below that value (the usual 10 or 21) stops at the program, so nothing after it runs. That looked like the program never returning. `ncrt0` and `nlrcrt0` read the code first.

## Fix

The exit code is now read before `sp` is restored, as in the other start codes (a two-line swap).

## Results

The tests ran on AmigaOS 3.2.3 (68040), from a Shell with `Stack 4096`. The table shows `$RC` after each program:

| Program | Old libnix | Patched |
| --- | --- | --- |
| empty `main`, `-fbaserel32` | 4096 | 0 |
| `return 7`, `-fbaserel32` | 4096 | 7 |
| `exit(5)`, `-fbaserel32` | 4096 | 5 |
| `return 7`, `-resident32 -fbaserel32` (control) | 7 | 7 |
| `return 7`, plain (control) | 7 | 7 |

`tests/libnix/build.sh` builds them (`empty-b32-*`, `rc7-b32-*`, `exit5-b32-*`).
