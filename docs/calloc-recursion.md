# A program's own calloc turned into a call to calloc

**Fixed by** `patches/gcc/0005-fmalloc-memset-to-calloc-and-never-turn-calloc-s-own.patch`
and the driver default in `patches/gcc/0006-…`.

## What went wrong

GCC turns `p = malloc(n); memset(p, 0, n);` into `calloc(n, 1)`. A program
that replaces the allocator and writes its own calloc that way got a calloc
that calls itself until the stack runs out. On an Amiga that is a crash, or a
CPU jumping into data. `-fno-builtin-calloc` does not stop it; only
`-fno-builtin-malloc` or `-fno-optimize-strlen` did, and both cost
optimisations everywhere.

## The fix

- The transform is never made inside a function named `calloc`, nor in code
  inlined from one.
- A new option, `-fmalloc-memset-to-calloc` (on by default in GCC), turns the
  transform off as `-fno-malloc-memset-to-calloc`.
- OpenAmigaGCC's driver passes `-fno-malloc-memset-to-calloc` unless a build
  asks for the positive form, so allocators stay as written.

## Reproducer

`tests/repro/calloc.c` defines malloc and a calloc made from malloc + memset,
and counts calloc's depth.

| Compiler | run | code |
| --- | --- | --- |
| GCC 16.2.0b as released (`-O2`) | wrong: calloc called itself | `jsr _calloc` inside `_calloc` |
| OpenAmigaGCC (`-O2`) | right | no call |
| OpenAmigaGCC with `-fmalloc-memset-to-calloc` | right | no call |
