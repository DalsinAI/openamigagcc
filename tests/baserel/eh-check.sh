#!/bin/bash
# eh-check.sh PREFIX
# Static check of patches/gcc/0011 (EH data always absolute): catch.cpp's
# throws and catches by type, linked -fbaserel32, -resident32 and -fbaserel,
# print no "out of range" relocations, and the base-relative libstdc++ and
# libsupc++ hold no LDFCM typeinfo pools (the PC-relative indirect EH data
# that crossed hunks). Running catch.cpp needs an Amiga (the lab). C++ with
# exceptions links -lpthread: libstdc++'s eh_globals and libgcc's unwinder use it.
# GPL-3.0-or-later, like the patches it goes with. Copyright (c) 2026 AmigaChrome Team.
set -u
P=$1; CXX="$P/bin/m68k-amigaos-g++"; OBJDUMP="$P/bin/m68k-amigaos-objdump"
D=$(cd "$(dirname "$0")" && pwd); O=$(mktemp -d); bad=0
for m in -fbaserel32 -resident32 -fbaserel; do
  if ! "$CXX" -m68040 -O2 $m -o "$O/catch$m" "$D/catch.cpp" -lpthread > "$O/catch$m.log" 2>&1; then
    echo "$m: WRONG (did not link)"; sed 's/^/  /' "$O/catch$m.log" | head -20; bad=1
  elif n=$(grep -c 'out of range' "$O/catch$m.log"); [ "$n" != 0 ]; then
    echo "$m: WRONG ($n 'out of range' lines)"; grep -m3 'out of range' "$O/catch$m.log"; bad=1
  else echo "$m: right (links with no 'out of range' lines)"; fi
done
n=0
while IFS= read -r a; do
  c=$("$OBJDUMP" -h "$a" 2>/dev/null | grep -c 'LDFCM')
  if [ "$c" != 0 ]; then echo "${a#"$P"/}: WRONG ($c LDFCM sections)"; bad=1; fi
  n=$((n+1))
done < <(find "$P" \( -path '*libb*' \) \( -name libstdc++.a -o -name libsupc++.a \))
[ "$n" -gt 0 ] || { echo "no base-relative libstdc++.a or libsupc++.a found under $P"; bad=1; }
[ "$bad" = 0 ] && echo "base-relative libstdc++/libsupc++: right ($n archives, no LDFCM sections)"
rm -rf "$O"
exit $bad
