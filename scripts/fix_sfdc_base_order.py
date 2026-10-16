#!/usr/bin/env python3
"""fix_sfdc_base_order.py FILE...
sfdc's GCC inline macros (MacroGCC.pl, and the sfdc script built from it)
bind A6 to the library base before they evaluate the arguments. When an
argument is itself an inline library call, as in Stricmp(FilePart(x), ...),
that inner call puts its own base in A6 and the outer call jumps through the
wrong library: Stricmp ran dos.library's vector at -162. This moves the A6
binding after the arguments are in temporaries, as AmigaPorts sfdc 3332a96
("MacroGCC: bind the base register after evaluating the arguments") does.
Given inline headers (*.h) sfdc has already made, such as an installed
toolchain's ndk-include/inline/*.h, it moves the A6 line in each macro the
same way, so a toolchain can be fixed without a rebuild.
Idempotent: a file already in that order is left alone; a script with neither
order, or no file at all, stops the build.
GPL-3.0-or-later. Copyright (c) 2026 AmigaChrome Team."""
import os
import re
import sys

BASE = '      print "  register void * __p__in_base __asm(\\"a6\\") = (void *)(__in_base);\\\\\\n";\n'
ARGS = '      # Evaluate all parameters into local variables FIRST\n'
A6 = '__p__in_base __asm(\\"a6\\")'   # the binding, however later sfdc words it
RET = '      # Return register (always create for non-void)\n'
NOTE = ('      # Bind the base register only now: an argument expression may itself\n'
        '      # be an inline call that binds a6 to its own library base.\n')
# in a header: the A6 line, then the argument temporaries it must follow
HDR = re.compile(r'(  register void \* __p__in_base __asm\("a6"\) = \(void \*\)\(__in_base\);\\\n)'
                 r'((?:  (?!register )[^\n]*?__p_\w+ = [^\n]*;\\\n)+)')
bad, seen = 0, 0
for path in sys.argv[1:]:
    if not os.path.exists(path):   # an sfdc without the generated script checked in
        continue
    seen += 1
    if path.endswith(".h"):
        data = open(path, encoding="latin-1").read()
        fixed, n = HDR.subn(r"\2\1", data)
        if n:
            open(path, "w", encoding="latin-1").write(fixed)
        print("%s: %d calls" % (path, n))
        continue
    data = open(path, encoding="latin-1").read()
    if BASE + ARGS in data and data.count(BASE) == 1 and data.count(RET) == 1:
        data = data.replace(BASE + ARGS, ARGS).replace(RET, NOTE + BASE + "\n" + RET)
        open(path, "w", encoding="latin-1").write(data)
        print("%s: A6 now bound after the arguments" % path)
    elif ARGS in data and data.find(A6) > data.index(ARGS):
        print("%s: already binds A6 after the arguments" % path)
    else:
        print("%s: the A6 binding was not found where expected; check it by hand" % path)
        bad = 1
sys.exit(1 if bad or not seen else 0)
