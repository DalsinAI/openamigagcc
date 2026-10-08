# libnix: 32-bit multiply and divide jump through a NULL UtilityBase

**Patch:** `patches/libnix/0003-nix20-math-don-t-jump-through-a-NULL-UtilityBase.patch`
**Reproducers:** `tests/libnix/utilbase.c` (on the Amiga), `tests/libnix/math/` (qemu-m68k)

## Symptom

A 68000 program that defines its own `UtilityBase` crashed with Software Failure 80000004 at its first `printf("%lu")`, or at its first 32-bit multiply or divide, if that came before it opened utility.library itself.

## Cause

On 68000 builds, libnix's `__mulsi3`, `__divsi3`/`__modsi3` and `__udivsi3`/`__umodsi3` jump into utility.library (`UMult32`, `SDivMod32`, `UDivMod32`) through `UtilityBase`. libnix opens the library automatically only when its own `UtilityBase` is linked. A program that defines the symbol itself replaces it, so `UtilityBase` stays NULL until the program opens the library, and the helpers jump to NULL−138/150/156.

## Fix

When `UtilityBase` is NULL the helpers compute the result themselves: a shift-and-subtract division for the unsigned and signed cases, and three `MULU`s for the multiply. They give the same results as the library calls: the quotient truncates towards zero, and the remainder takes the dividend's sign. With the library open, nothing changes.

## Results

| Test | Old libnix | Patched |
| --- | --- | --- |
| `utilbase` on AmigaOS 3.2.3: own `UtilityBase`, never opened, `-m68000` | Software Failure 80000004 | `571428571 3 -333333 -1 -3000000`, PASS |
| `math/run.sh`: 20000 pairs on qemu-m68k with `UtilityBase` NULL, checked against the host | segmentation fault (jump to NULL) | 20000 cases, 0 wrong |

```bash
GCC_PREFIX=/opt/amiga tests/libnix/math/run.sh NEW_PREFIX
```
