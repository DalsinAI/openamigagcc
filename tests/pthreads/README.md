# libpthread reproducer

`t3race.cpp`: one consumer and four producers on a `condition_variable`; each producer uses a `thread_local` and `std::call_once`, then a `std::async`. Creating the fifth thread grows libpthread's thread table while three threads run.

Build it with the C++ flags the stove uses, run it on an Amiga ten times with `Run`, and count the runs that print `t3 OK`:

```bash
m68k-amigaos-g++ -m68020 -m68881 -O2 -fomit-frame-pointer -std=gnu++23 -o t3race t3race.cpp -lpthread -latomic -lstdc++
```

This needs a real AmigaOS: qemu-m68k's user mode has no exec tasks.

`t3w_warm.cpp`: the same test after a warm-up that has five threads alive at once. With the stove's unpatched library it hung once on Instance-32 (11 Oct 2026), and the agent's next command, which needed DH1:, never ran. The warm-up is the case `patches/aros-stuff/0001` fixes: the stock library kept its threads in one array that it grew with `realloc` (1, 4, 10 slots, slot 0 being the main task), and the 4th warm-up thread is created while threads 1-3 still run. When those end, each writes `finished` into the freed array and `Signal`s the `parent` it reads from there, so a stale task pointer can be signalled and the whole machine, the agent with it, stops. With 0001 each ThreadInfo is allocated once and never moves. Run it 20 times with the patched library: every run should print `t3w OK`.
