#!/bin/bash
# eh-check.sh PREFIX
# Static check of patches/gcc/0011 (EH data always absolute): a throw and a
# catch by type, linked -fbaserel32, -resident32 and -fbaserel,
# print no "out of range" relocations, and the base-relative libstdc++ and
# libsupc++ hold no LDFCM typeinfo pools (the PC-relative indirect EH data
# that crossed hunks). Running it is catch.cpp's job, on an Amiga.
# GPL-3.0-or-later, like the patches it goes with. Copyright (c) 2026 Dalsin Limited.
set -u
P=$1; CXX="$P/bin/m68k-amigaos-g++"; OBJDUMP="$P/bin/m68k-amigaos-objdump"
O=$(mktemp -d); bad=0
cat > "$O/eh.cpp" <<'CXX'
#include <stdexcept>
#include <vector>
struct Mine { int v; };
int main() {
  int got = 0;
  try { throw Mine{7}; } catch (const Mine &m) { got += m.v; }
  try { std::vector<int> v; v.at(3); } catch (const std::out_of_range &) { got += 1; }
  return got == 8 ? 0 : 1;
}
CXX
for m in -fbaserel32 -resident32 -fbaserel; do
  if ! "$CXX" -m68020 -O2 $m -o "$O/eh$m" "$O/eh.cpp" > "$O/eh$m.log" 2>&1; then
    echo "$m: WRONG (did not link)"; sed 's/^/  /' "$O/eh$m.log" | head -20; bad=1
  elif n=$(grep -c 'out of range' "$O/eh$m.log"); [ "$n" != 0 ]; then
    echo "$m: WRONG ($n 'out of range' lines)"; grep -m3 'out of range' "$O/eh$m.log"; bad=1
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
