# libnix patches

These apply to bebbo's libnix at commit `5707d0b` ("__amigapath: read NOIXPATHS after environ is filled"), the libnix the GCC 16.2 stove is built from. In amiga-gcc's `projects/libnix`:

```bash
git am /path/to/patches/libnix/*.patch      # or: patch -p1 < each file, in order
```

| Patch | Fixes | Notes |
| --- | --- | --- |
| `0001-swapstack-…` | `__stack` ignored; the stack swap clobbers A2 (80000004) | `docs/libnix-stack-swap.md` |
| `0002-nlbcrt0-…` | plain `-fbaserel32` programs return the stack size instead of their exit code | `docs/libnix-baserel32-exit.md` |
| `0003-nix20-math-…` | 32-bit multiply/divide jump through a NULL `UtilityBase` (80000004) | `docs/libnix-utilitybase.md` |

Then rebuild libnix (`make libnix` in amiga-gcc, or `Makefile.gcc6 all install`). Built with the GCC 16.2 stove at `-O2`, the unpatched source gives a `libnix20.a`, `libnix13.a` and start code byte-identical to the stove's.

**Licence:** libnix is public domain, as its README states. These patches are public domain too.
