# libpthread: a running thread's record moved under it

**Patch:** `patches/aros-stuff/0001-pthreads-a-running-thread-s-ThreadInfo-never-moves.patch`
**Reproducer:** `tests/pthreads/t3race.cpp` (on the Amiga)

## Symptom

The stove qualification test t3 crashes or hangs about half the time, or more. It runs one consumer and four producers; each producer uses a C++ `thread_local` and `std::call_once`. Crashes are Software Failure 80000003 (address error) or 80000006 in "pthread thread #1" or "#2". Each piece passes when run alone, and so does `malloc` in four threads at once.

## Cause

libpthread (bebbo's aros-stuff `pthreads`, built by amiga-gcc) keeps every thread's `ThreadInfo` in one array. `pthread_create` grows that array with `realloc`, from 1 slot to 4, 10, 22 and so on.

A thread holds a pointer to its own `ThreadInfo` in `StarterFunc` for its whole life. It uses that pointer again after its start routine returns, in the loop that runs the TLS key destructors. So when the 4th, 10th, 22nd... thread is created while earlier threads are running, the array moves under them. When they end, they read and write the freed block.

That is harmless until three things meet:
- a TLS key with a destructor (libgcc's emutls key, made by the first `thread_local` or `call_once`);
- the freed block being reused by `malloc`;
- an earlier thread then ending.

Then the loop calls the emutls destructor on whatever now sits in the old block. The code after the loop already says "inf may be invalid due to realloc" and looks the record up again, but the loop before it doesn't.

## Fix

The table is an array of `PTHREAD_THREADS_MAX` pointers (8 KB), allocated once. Each `ThreadInfo` is allocated once, when its slot is first needed, and never moves. Nothing else changes.

## Results

Instance-32 (AmigaOS 3.2 on AmiCradle), 11 October 2026. Each run was started with `Run`, 3 seconds apart, after a reset:

| t3 linked with | Runs | `t3 OK` |
| --- | ---: | ---: |
| the stove's libpthread (`-O2`), runs by the Team earlier | 8 | 4 (4 crashed in thread #1 or #2) |
| the stove's libpthread (`-O2`) | 10 | 0 (none finished) |
| aros-stuff c0a06b4, unpatched, `-Os` | 6 | 0 (none finished) |
| aros-stuff c0a06b4 with this patch, `-Os` | 10 | 10 |

The unpatched and patched builds use the same source and the same flags, and differ only by this patch.

**Not done yet:** a full stove build with `scripts/build.sh`, which builds libpthread at `-O2` for every multilib.
