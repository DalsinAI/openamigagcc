# Socket library inlines refused by GCC 16

**Fixed by** `scripts/fix_inline_clobbers.py`, which `scripts/build.sh` runs on
amiga-netinclude before the build.

Roadshow's `inline/bsdsocket.h` and `inline/usergroup.h` (from amiga-netinclude,
installed beside the NDK's headers) list d0, d1, a0 and a1 as clobbered in
calls whose arguments sit in those registers. GCC 15 and later refuse that
("'asm' specifier for variable ... conflicts with 'asm' clobber list"), so any
program calling, for example, `SetSocketSignals` or `SetErrnoPtr` did not
compile. 31 calls were affected: 16 in `bsdsocket.h` and 15 in `usergroup.h`.

The script makes only the clashing registers dummy outputs of the call, which
tells GCC the same thing (the library may change them) in a form it accepts.
The code GCC makes for the call is unchanged. Running it again changes
nothing. No other inline header in the toolchain or the NDK 3.2 set has the
clash.

## Check

```c
#include <proto/bsdsocket.h>
struct Library *SocketBase;
int main(void) { SetSocketSignals(1, 1, 1); return socket(2, 1, 0); }
```

| Headers | GCC 16 |
| --- | --- |
| amiga-netinclude as published | error, 2 per call |
| after `fix_inline_clobbers.py` | compiles; same call sequence |
