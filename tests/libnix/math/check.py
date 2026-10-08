import sys, struct
d = sys.stdin.buffer.read(); n = len(d) // 28; bad = 0
def s32(x): return x - (1 << 32) if x & 0x80000000 else x
for i in range(n):
    a, b, q, r, sq, sr, p = struct.unpack(">7I", d[i*28:i*28+28])
    eq, er = a // b, a % b
    sa, sb = s32(a), s32(b)
    if sa == -2**31 and sb == -1: esq, esr = sa, 0     # overflow: anything goes for q
    else:
        esq = abs(sa) // abs(sb) * (1 if (sa < 0) == (sb < 0) else -1); esr = sa - esq * sb
    ep = (a * b) & 0xffffffff
    ok = (q, r, p) == (eq, er, ep) and (s32(sq), s32(sr)) == (esq, esr)
    if not ok:
        bad += 1
        if bad < 5: print("BAD", hex(a), hex(b), hex(q), hex(r), hex(sq), hex(sr), hex(p))
print(f"{n} cases, {bad} wrong")
