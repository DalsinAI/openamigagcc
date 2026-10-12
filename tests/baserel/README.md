# Base-relative C++ repro (os32-gcc16)

`build.sh` builds `t3_threads.cpp` plain, with `-fbaserel32` and with `-fbaserel`.
Seen on daletop on 12 October 2026 (stove from openamigagcc main f9efa3d, AmigaOS 3.2.3 lab, AC090 68040):

| Build | Link | On the Amiga |
| --- | --- | --- |
| plain | OK | `t3 OK`, rc 0 |
| `-fbaserel32` | OK, with 25 lines `.data.rel.local.LDFCM0 reloc for .data.rel.local.LDFCM0 is out of range: 00000000` | hangs before printing anything; the task waits on signal `80000000` (received `00000100`) |
| `-fbaserel` | fails: `libnix.a(cxxglue.o): in function '__init_eh': relocation truncated to fit: DREL16 against '.list___EH_FRAME_BEGIN'` (plus the same 25 lines) | — |

The `LDFCM` sections are GCC's constant pools for `long double` (FPU) constants in `.data.rel.local`.
