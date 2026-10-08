#!/usr/bin/env python3
# mkelf.py IN OUT.elf: load an AmigaOS hunk executable (linked with
# -nostartfiles -nostdlib, start code first) at 0x10000 as AmigaOS's loader
# would, apply its relocations, and wrap the image as a static big-endian ELF
# with one PT_LOAD, so qemu-m68k (user mode) can run it. The image talks to
# the outside through Linux m68k syscalls (trap #0): write and exit.
# MIT licence, Copyright (c) 2026 Dalsin Limited.
import struct
import sys

BASE = 0x10000
data = open(sys.argv[1], "rb").read()
pos = 0


def u32():
    global pos
    v = struct.unpack_from(">I", data, pos)[0]
    pos += 4
    return v


def u16():
    global pos
    v = struct.unpack_from(">H", data, pos)[0]
    pos += 2
    return v


assert u32() == 0x3F3, "not a hunk executable"
while u32():                       # resident library names (none)
    pass
count, first, last = u32(), u32(), u32()
sizes = [(u32() & 0x3FFFFFFF) * 4 for _ in range(last - first + 1)]
addrs, a = [], BASE
for s in sizes:
    addrs.append(a)
    a = (a + s + 7) & ~7
image = bytearray(a - BASE)
hunk = -1
while pos < len(data):
    t = u32() & 0x3FFFFFFF
    if t in (0x3E9, 0x3EA):                         # CODE, DATA
        hunk += 1
        n = u32() * 4
        o = addrs[hunk] - BASE
        image[o:o + n] = data[pos:pos + n]
        pos += n
    elif t == 0x3EB:                                # BSS
        hunk += 1
        u32()
    elif t == 0x3EC:                                # RELOC32
        while True:
            n = u32()
            if not n:
                break
            target = addrs[u32()]
            for _ in range(n):
                o = addrs[hunk] - BASE + u32()
                v = struct.unpack_from(">I", image, o)[0]
                struct.pack_into(">I", image, o, (v + target) & 0xFFFFFFFF)
    elif t in (0x3FC, 0x3F7):                       # RELOC32SHORT, DREL32
        start = pos
        while True:
            n = u16()
            if not n:
                break
            target = addrs[u16()]
            for _ in range(n):
                o = addrs[hunk] - BASE + u16()
                v = struct.unpack_from(">I", image, o)[0]
                struct.pack_into(">I", image, o, (v + target) & 0xFFFFFFFF)
        if (pos - start) & 2:
            pos += 2
    elif t == 0x3F0:                                # SYMBOL
        while True:
            n = u32()
            if not n:
                break
            pos += n * 4 + 4
    elif t == 0x3F1:                                # DEBUG
        pos += u32() * 4
    elif t == 0x3F2:                                # END
        pass
    else:
        sys.exit("mkelf.py: hunk type %#x not handled" % t)

memsz = 0xF01000 - BASE                             # room for the stack at 0xE00000
off = 0x1000
eh = struct.pack(">16sHHIIIIIHHHHHH", b"\x7fELF\x01\x02\x01" + b"\0" * 9,
                 2, 4, 1, BASE, 52, 0, 0, 52, 32, 1, 40, 0, 0)
ph = struct.pack(">IIIIIIII", 1, off, BASE, BASE, len(image), memsz, 7, 0x1000)
out = eh + ph
out += b"\0" * (off - len(out)) + bytes(image)
open(sys.argv[2], "wb").write(out)
