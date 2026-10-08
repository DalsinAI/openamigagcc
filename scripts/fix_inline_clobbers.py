#!/usr/bin/env python3
"""fix_inline_clobbers.py FILE...
GCC 15 and later refuse an asm statement whose clobber list names a register
that an input register variable sits in. Inline headers made by sfdc and
fd2pragma for the 68k Amiga (here Roadshow's bsdsocket.h and usergroup.h)
list d0, d1, a0 and a1 as clobbered even where the arguments sit in them.
For each such call this makes the clashing registers dummy outputs instead,
which says the same thing (the library call may change them) in a form GCC
accepts. Nothing else changes. GPL-3.0-or-later. Copyright (c) 2026 Dalsin Limited."""
import re
import sys

ASM = re.compile(r'(?P<head>__asm volatile \("jsr [^"]*"[ \t]*\\\n)'
                 r'(?P<i1>[ \t]*): (?P<outs>[^\n]*?)[ \t]*\\\n'
                 r'(?P<i2>[ \t]*): (?P<ins>[^\n]*?)[ \t]*\\\n'
                 r'(?P<i3>[ \t]*): (?P<clob>[^\n]*?)\);')
DECL = re.compile(r'register [^;]*?(\w+) __asm\("(\w+)"\)')
for path in sys.argv[1:]:
    data = open(path, "rb").read().decode("latin-1")
    out, pos, n = [], 0, 0
    for m in ASM.finditer(data):
        start = data.rfind("#define ", 0, m.start())
        regs = {v: r for v, r in DECL.findall(data[start:m.start()])}
        ins = re.findall(r'"r"\((\w+)\)', m.group("ins"))
        in_regs = {regs[v] for v in ins if v in regs}
        clob = [c.strip().strip('"') for c in m.group("clob").split(",") if c.strip()]
        clash = [c for c in clob if c in in_regs and c in ("d0", "d1", "a0", "a1")]
        if not clash:
            continue
        n += 1
        decls = "".join('register int __oag_%s __asm("%s"); ' % (r, r) for r in clash)
        outs = m.group("outs").strip()
        extra = ", ".join('"=r" (__oag_%s)' % r for r in clash)
        outs = extra if not outs else outs + ", " + extra
        keep = ", ".join('"%s"' % c for c in clob if c not in clash)
        out.append(data[pos:m.start()])
        out.append("{ " + decls + m.group("head") + "%s: %s \\\n%s: %s \\\n%s: %s); }"
                   % (m.group("i1"), outs, m.group("i2"), m.group("ins"), m.group("i3"), keep))
        pos = m.end()
    out.append(data[pos:])
    open(path, "wb").write("".join(out).encode("latin-1"))
    print("%s: %d calls" % (path, n))
