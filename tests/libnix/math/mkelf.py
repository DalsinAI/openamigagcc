# mkelf.py SREC ELF: wraps a raw 68k S-record image loaded at 0x10000 as a static ELF for qemu-m68k
import sys, struct
def hexv(s): return int(s, 16)
mem = {}
for line in open(sys.argv[1]):
    if line[:2] not in ('S1', 'S2', 'S3'): continue
    al = {'S1': 2, 'S2': 3, 'S3': 4}[line[:2]]
    cnt = hexv(line[2:4]); a = hexv(line[4:4 + 2 * al])
    data = bytes.fromhex(line[4 + 2 * al: 4 + 2 * al + 2 * (cnt - al - 1)])
    for i, b in enumerate(data): mem[a + i] = b
lo, hi = min(mem), max(mem) + 1
img = bytes(mem.get(a, 0) for a in range(lo, hi))
base = 0x10000; assert lo == base
memsz = 0xf01000 - base
off = 0x1000
eh = struct.pack(">16sHHIIIIIHHHHHH", b"\x7fELF\x01\x02\x01" + b"\0" * 9, 2, 4, 1, base, 52, 0, 0, 52, 32, 1, 40, 0, 0)
ph = struct.pack(">IIIIIIII", 1, off, base, base, len(img), memsz, 7, 0x1000)
out = eh + ph
out += b"\0" * (off - len(out)) + img
open(sys.argv[2], "wb").write(out)
