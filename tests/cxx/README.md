# C++ runtime tests

These need a real AmigaOS: qemu-m68k's user mode has no exec tasks. Build each test with the stove's usual C++ flags and nothing else. In particular, don't add `-fuse-cxa-atexit` or a `__dso_handle`: what is being tested is the default.

```bash
m68k-amigaos-g++ -m68020 -m68881 -O2 -fomit-frame-pointer -std=gnu++23 -o dtors dtors.cpp -lpthread
```

`dtors.cpp` tests C++ destructors at thread exit and at program exit ([docs/cxa-atexit.md](../../docs/cxa-atexit.md)). It prints two lines.

| Line | With gcc 0010 and libnix 0005 | Before |
| --- | --- | --- |
| first | `thread_local destroyed when its thread ended: yes` | `... no` |
| second, printed at exit | `dtors OK` | `dtors FAILED: g (want tm b g a )` |

It returns 0 when the thread's `thread_local` was destroyed in time, and 20 otherwise.
