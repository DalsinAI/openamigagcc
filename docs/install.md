# Installing OpenAmigaGCC 16.2.0-open3

GCC 16.2 for AmigaOS 3.x on 68k (`m68k-amigaos`), including AmigaOS 3.2.3, with binutils 2.46, libnix, libpthread, libgcc and libstdc++ (C++23), and the Team's fixes. It is built from bebbo's amiga-gcc line (GCC 16.2.0b) and runs on x86-64 Linux. For ARM64 Linux, use 16.2.0-open1's toolchain until an open3 ARM64 build is published.

Programs it makes are AmigaOS 3.x hunk executables linked with libnix.

This release has no AmigaOS 4.1 (`ppc-amigaos`) compiler. The README's Systems table lists each system and its status.

## Files

| File | What |
| --- | --- |
| `openamigagcc-16.2.0-open3-x86_64-linux.tar.xz` | the toolchain for x86-64 Linux |
| `openamigagcc-16.2.0-open3-src.tar.xz` | the complete source, the patches and the scripts that built them |
| `SHA256SUMS` | checksums of the two |

## Install

The toolchain needs glibc 2.38 or later (Ubuntu 24.04 or later, Debian 13 or later, Fedora 39 or later) and the host's GMP, MPFR and MPC: `libgmp10`, `libmpfr6` and `libmpc3` on Debian and Ubuntu, which most systems with a GCC already have.


1. Check and unpack the toolchain for your machine. It works from any folder; `/opt` is used here:
   ```bash
   sha256sum -c --ignore-missing SHA256SUMS
   sudo tar -C /opt -xJf openamigagcc-16.2.0-open3-x86_64-linux.tar.xz
   export PATH=/opt/openamigagcc-16.2.0-open3-x86_64-linux/bin:$PATH
   ```
   Check it runs:
   ```bash
   m68k-amigaos-gcc --version
   ```
   The first line is `m68k-amigaos-gcc (OpenAmigaGCC 16.2.0-open3) 16.2.0b 20260930174807`. A plain C program that uses only the C library already compiles here; programs that use the AmigaOS headers need the NDK from step 2.
2. **Add the AmigaOS 3.2 NDK.** It is not free software, so it is not included. Get `NDK3.2.lha` from Aminet (`dev/misc/NDK3.2.lha`), then let the source release put it in place (this needs `lha` from the lhasa package, a host C compiler, make, rsync and Perl):
   ```bash
   tar -xJf openamigagcc-16.2.0-open3-src.tar.xz
   openamigagcc-16.2.0-open3-src/openamigagcc/scripts/install-ndk.sh \
       openamigagcc-16.2.0-open3-src/amiga-gcc /opt/openamigagcc-16.2.0-open3-x86_64-linux NDK3.2.lha
   ```
   The NDK goes into `m68k-amigaos/ndk-include`, `m68k-amigaos/ndk13-include` and `m68k-amigaos/ndk` inside the toolchain folder.
3. Optional developer headers, also not included: AHI (the `ahidev` archive on Aminet) and CyberGraphX (the CyberGraphX developer kit on Aminet). Copy their C `include` folders' contents into `m68k-amigaos/include`.

## Use

```bash
m68k-amigaos-gcc -m68040 -O2 -o hello hello.c
m68k-amigaos-g++ -m68040 -O2 -std=c++23 -o prog prog.cpp -lpthread -latomic
```

`-m68040` alone selects the 68020-or-later soft-float libraries. Add `-m68881` for a hard-float program; that selects the 68881 multilib explicitly. No external specs file is needed in open3. See [m68040-soft-float-link.md](m68040-soft-float-link.md).

The driver adds two safe defaults, each of which a build can turn back on with the positive option:
- `-fno-delete-null-pointer-checks`: address 0 is memory on an Amiga;
- `-fno-malloc-memset-to-calloc`: a program's own allocators stay as written;

`m68k-amigaos-gcc -### -c x.c` shows them.

C++ is compiled with `-fuse-cxa-atexit`, so `thread_local` destructors run when their thread ends; libnix provides `__cxa_atexit` and `__dso_handle`. A C++ program built for another C library (`-mcrt=clib2`, `ixemul`, `newlib`) with a static object that has a destructor needs `-fno-use-cxa-atexit`.

## Licences

- GCC, libgcc, libstdc++ and binutils: GPL-3.0-or-later. The GCC Runtime Library Exception applies to libgcc and libstdc++, so programs you build can be under any licence you choose.
- libnix: public domain. libpthread (aros-stuff): zlib licence. GMP, MPFR and MPC (LGPL-3.0-or-later) are not included: the toolchain uses the host's.
- The patches and scripts: GPL-3.0-or-later. `fenv.h` and `uchar.h`: MIT.
- bebbo's amiga-gcc framework (the source release's `amiga-gcc/`): GPL-2.0. Its prebuilt link libraries (`libamiga.a`, `libstubs.a` and the newlib `libc.a`/`libm.a`) are installed as the framework ships them.
- Not included, by design: the AmigaOS NDK, Roadshow's network headers (the NDK step installs them), and the AHI and CyberGraphX developer headers.

The source release holds the exact sources these binaries were built from, as the GPL requires.
