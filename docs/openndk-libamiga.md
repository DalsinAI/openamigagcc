# libamiga.a is OpenNDK's

GCC's link spec for `m68k-amigaos` always adds `-lamiga`, so every program
links `libamiga.a`: NewList, CreatePort, BeginIO, DoMethod, the varargs stubs
such as OpenWindowTags, SetRexxVar and the rest.

## Before open3

bebbo's amiga-gcc framework keeps a prebuilt `libamiga.a` in its `lib/` and
`lib/libb/` folders, made from Commodore's `amiga.lib`, and its `libamiga`
step copies them into the toolchain. open1 and open2 shipped those two files
in both release tarballs (the toolchain and the source). They are not free
software, and programs built with the toolchain carried their objects.

## From open3

- `build.sh` step 2b removes the two prebuilt files from the work folder
  before amiga-gcc's build runs, so they are never installed.
- Step 5b builds OpenNDK's `libamiga.a` (DalsinAI/openamigasdk, pinned in
  `scripts/sources.lock`) with the new compiler, three times: plain,
  `-fbaserel` and `-fbaserel32`. It puts one in every multilib folder that
  `-print-multi-lib` lists: the plain build in `.`, `libm020`, `libm060` and
  `libm020/libm881`; the `-fbaserel` build under `libb`; the `-fbaserel32`
  build under `libb32`.
- Each old file is removed before the new one is copied, so a stove whose
  `libamiga.a` is a link gets a new file and the link's target is untouched.
- Step 7 checks that every `libamiga.a` in the toolchain has OpenNDK's
  `rexxvar.o` (Commodore's has no such member), that each multilib's
  `-print-file-name=libamiga.a` is the file in its own folder, and that a
  NewList program links.

OpenNDK is built for the 68040, as the Team's builds are.

## Not changed

libnix and the target libraries are still compiled against the NDK 3.2
headers you supply (`NDK3.2.lha`). No NDK file is installed in the release
tarball, and none is linked into a program by default.
