# -m68040 links the FPU libm

**For now:** `build/m68k-soft-m68040.specs`, passed with `-specs=`.
**For the next toolchain build:** the `LINK_CPU_SPEC` change below. No patch
yet, and nothing here rebuilds the toolchain.

## What goes wrong

`-m68040` without `-m68881` compiles soft float: doubles live in d0/d1 and
the arithmetic is `jsr ___muldf3` and the like. The link spec, though, adds
the libnix flavour `libm881` for any `-mcpu=6804*`:

```
*link_cpu:
%{m6802*|mc6802*|m6803*|m6804*|m6806*|m6808*|mcpu=6802*|mcpu=6803*|mcpu=6804*|mcpu=6806*|mcpu=6808*:-fl libm020} %{mhard-float|m68881|mcpu=6804*|mcpu=6806*|mcpu=6808*:-fl libm881}
```

So a soft-float `-m68040` program links `libm020/libm881/libm.a`:

- its `strtod`, `strtold`, `atof` and `ldexp` return in fp0, while the
  soft-float caller reads d0/d1: wrong values (measured in a lab: strtod and
  atof wrong, `printf("%f")` printed 0.000000);
- its other functions run FPU instructions, which crash on a 68LC040 or
  68EC040.

Both stoves do this (os32-gcc16 and os32, GCC 6.5).

## The rule

Soft float by default: one binary runs on a full 68040 and on an LC/EC040.
libnix's soft `libm020` does its maths through the Amiga's mathieee
libraries, and they use the FPU when there is one. Only `-m68881` or
`-mhard-float` (or a 68060) links `libm881`.

## Now: the specs file

`build/m68k-soft-m68040.specs` replaces `*link_cpu` with the same spec less
`mcpu=6804*` in the `libm881` part:

```
m68k-amigaos-gcc -m68040 -specs=path/to/m68k-soft-m68040.specs -O2 -o hello hello.c -lm
```

Check: link with `-Wl,-Map,x.map` and `libm020/libm881` is not in the map.
It is harmless on compiles and `-nostdlib` links, so a build can put it next
to `-m68040` in its flags. With `-m68040 -m68881` the program is hard float
and still links `libm881`, as it must.

## Next toolchain build: gcc/config/m68k/m68kamigaos.h

```diff
 #define LINK_CPU_SPEC \
   "%{m6802*|mc6802*|m6803*|m6804*|m6806*|m6808*|mcpu=6802*|mcpu=6803*|mcpu=6804*|mcpu=6806*|mcpu=6808*:-fl libm020} " \
-  "%{mhard-float|m68881|mcpu=6804*|mcpu=6806*|mcpu=6808*:-fl libm881}"
+  "%{mhard-float|m68881|mcpu=6806*|mcpu=6808*:-fl libm881}"
```

`mcpu=6804*` drops out of the `libm881` condition. libm881 returns floats in
fp0, which is only right for a hard-float caller. A soft-float `-m68040`
program should reach the FPU through the mathieee libraries, which also work
on an LC/EC040. Once a stove has this, the specs file is no longer needed
(and still harmless).

## Making the 68040 the default

The compiler's default CPU is still the 68000 (configured without
`--with-cpu`), and `-m68040` uses the `libm020` multilib (`MULTILIB_MATCHES`
maps `mcpu=68040` to `mcpu=68020`). A `libm040` multilib, or configuring with
`--with-cpu=68040`, would make the 68040 the default, so a build without a
CPU flag would no longer get 68000 code and libraries. That is a toolchain
decision for a later build; it is not made here.
