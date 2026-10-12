# Nested inline library calls run with the wrong base in A6

**Fixed by** `scripts/fix_sfdc_base_order.py`, which `scripts/build.sh` runs on
sfdc before the build, so the NDK's `inline/*.h` come out right.
`scripts/install-ndk.sh` runs it on the headers it installs.

## The bug

```c
if (Stricmp(FilePart(name), "frame.config") == 0)
```

`Stricmp` ran with `DOSBase` in A6, so `jsr -162(a6)` called dos.library's
vector at -162 instead of utility.library's `Stricmp`. Zune's datatypes cache
(OpenUp 0.7.4) and OpenTypes hit it on 9 and 11 October; AmigaPorts saw it in
dopus5 as `RawDoFmt(GetString(...))`.

It is in the headers, not in the compiler. sfdc writes the NDK's GCC inlines
(`--mode=macros`), and its macros bound A6 first and evaluated the
arguments after:

```c
#define __Stricmp_base(__in_base, ___string1, ___string2) ({\
  register void * __p__in_base __asm("a6") = (void *)(__in_base);\
  STRPTR __p____string1 = (STRPTR)(___string1);   /* FilePart(...) runs here */\
  ...
```

The inner `FilePart` binds A6 to `DOSBase` while the outer A6 variable is
still live. Two variables want A6 at once, and GCC keeps the inner one:
the outer call's `move.l UtilityBase,a6` is dropped. GCC 6.5 (the os32
stove) and GCC 16 both did this in Amiga builds, and GCC 14 does it at
`-O1`, `-O2` and `-Os`. The macros in
`inline/macros.h` (`LP2` and the others) and Roadshow's socket inlines
already evaluate the arguments first and are not affected.

## The fix

The A6 line moves after the argument temporaries, as AmigaPorts sfdc did on 6
September 2026 (3332a96, "MacroGCC: bind the base register after evaluating
the arguments"). The script changes sfdc's `MacroGCC.pl` and the `sfdc`
script built from it. Given headers sfdc already made, it moves the same line
in each macro, which fixes an installed toolchain without a rebuild:

```sh
python3 scripts/fix_sfdc_base_order.py "$PREFIX"/m68k-amigaos/ndk-include/inline/*.h
```

Running it again changes nothing. Headers fixed this way are byte for byte
what the fixed sfdc makes.

## Check

`tests/repro/nested.c` builds two jump tables at run time, for dos.library's
`FilePart` (-870) and utility.library's `Stricmp` (-162), with the NDK's own
`proto/dos.h` and `proto/utility.h`. Each fake function records the A6 it was
called with. `tests/repro/prove.sh` runs it at `-O1`, `-O2` and `-Os`.

The results below were taken with GCC 14 (m68k-linux under qemu-m68k) and
headers made by bebbo's sfdc; CI runs it with OpenAmigaGCC itself.

| Headers | Result |
| --- | --- |
| bebbo's sfdc (A6 first) | `nested: WRONG (Stricmp ran with DOSBase in A6, case 3)` |
| after `fix_sfdc_base_order.py` | `nested: right` |

Until a toolchain has the fix, take the inner call's result first:

```c
CONST_STRPTR leaf = FilePart(name);
if (Stricmp(leaf, "frame.config") == 0)
```
