# Base-relative C++ repro (os32-gcc16)

`build.sh` builds `t3_threads.cpp` plain, with `-fbaserel32` and with `-fbaserel`.
Seen on daletop on 12 October 2026 (stove from openamigagcc main f9efa3d, AmigaOS 3.2.3 lab, AC090 68040):

| Build | Link | On the Amiga |
| --- | --- | --- |
| plain | OK | `t3 OK`, rc 0 |
| `-fbaserel32` | OK, with 25 lines `.data.rel.local.LDFCM0 reloc for .data.rel.local.LDFCM0 is out of range: 00000000` | hangs before printing anything; the task waits on signal `80000000` (received `00000100`) |
| `-fbaserel` | fails: `libnix.a(cxxglue.o): in function '__init_eh': relocation truncated to fit: DREL16 against '.list___EH_FRAME_BEGIN'` (plus the same 25 lines) | — |

The `LDFCM` sections are not FPU constants: they are 4-byte pointers to exception typeinfo, which `.gcc_except_table` reaches with a 32-bit PC-relative relocation across hunks (see `FINDINGS.md`, B). That is the still-open catch-by-type problem.

With libnix 0007, aros-stuff 0005 and the base-relative `libos32compat` builds (amigachrome-stoves #7: `compat/libb`, `compat/libb32`), `-fbaserel32` and `-fbaserel` both print `t3 OK`. `build.sh` links each variant with the matching compat archive.
