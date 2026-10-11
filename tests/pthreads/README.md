# libpthread reproducer

`t3race.cpp`: one consumer and four producers on a `condition_variable`; each producer uses a `thread_local` and `std::call_once`, then a `std::async`. Creating the fifth thread grows libpthread's thread table while three threads run.

Build it with the C++ flags the stove uses, run it on an Amiga ten times with `Run`, and count the runs that print `t3 OK`:

```bash
m68k-amigaos-g++ -m68020 -m68881 -O2 -fomit-frame-pointer -std=gnu++23 -o t3race t3race.cpp -lpthread -latomic -lstdc++
```

This needs a real AmigaOS: qemu-m68k's user mode has no exec tasks.

`t3w_warm.cpp`: the same test after a warm-up that has five threads alive at once, so libpthread's thread table has grown before any thread of the real test runs. With the stove's unpatched library it hung once on Instance-32 (11 Oct 2026), and the agent's next command, which needed DH1:, never ran. Not explained yet: build and run it the same way, and record whether a run hangs and where.
