# Building OpenAmigaGCC

The recipe builds GCC 16.2 for `m68k-amigaos` with binutils, libnix,
libpthread, libgcc and libstdc++, from bebbo's amiga-gcc line at pinned
commits, with the patches in `patches/`.

## What it needs

- An x86 or ARM64 Linux system with the usual GCC build tools (a C and C++
  compiler, make, bison, flex, gperf, texinfo, gmp/mpfr/mpc development
  files, rsync, git, lhasa).
- The AmigaOS 3.2 NDK archive, `NDK3.2.lha`, which you supply. It is not free
  software, so it is never fetched or kept here.
- About 9 GB of disk and 45 minutes on 8 cores.

## Steps

```bash
scripts/fetch.sh WORK                # clones the sources in scripts/sources.lock (network)
scripts/build.sh WORK PREFIX /path/to/NDK3.2.lha [JOBS]
```

For ARM64 Linux hosts, a Canadian cross on x86-64 (needs
`aarch64-linux-gnu-gcc` and `-g++`; GMP, MPFR and MPC are built in-tree from
their release tarballs):

```bash
scripts/build-arm64.sh WORK X86PREFIX ARMPREFIX TARBALLS
```

It builds the programs for ARM64 and copies the target libraries and headers,
which are the same for every host, from the x86-64 build.

`fetch.sh WORK MIRROR` clones from an earlier amiga-gcc checkout instead of
the network. `build.sh` never fetches: when `unshare` is there it builds with
no network at all, so a missing source stops it.

`build.sh`:
1. checks every source is at its pinned commit;
2. applies `patches/gcc`, `patches/amiga-gcc` and `patches/libnix` (each once)
   and copies `sys-include/fenv.h` and `uchar.h`;
3. installs libnix's headers first (with no `-mcrt`, the driver means
   `-mcrt=nix20`, and libnix compiles some files that way);
4. runs amiga-gcc's `make binutils gcc gprof libnix libpthread ndk ndk13`;
5. builds libgcc, libstdc++ and the other target libraries against libnix's
   headers, and tells libstdc++ that the header-only `fenv.h` is there;
6. checks that a read of address 0 is not `trap #7`, that a C program links
   with libnix and that a C++23 program links.

Then `tests/repro/prove.sh PREFIX/bin` runs every reproducer (it needs
`qemu-m68k`).

## Using it

Programs are AmigaOS 3.x hunk executables linked with libnix:

```bash
m68k-amigaos-gcc -m68020 -O2 -o hello hello.c
```

The driver adds `-fno-delete-null-pointer-checks`,
`-fno-malloc-memset-to-calloc` and `-fno-tree-loop-distribute-patterns`
unless a build passes the positive form; see `m68k-amigaos-gcc -### -c x.c`.
