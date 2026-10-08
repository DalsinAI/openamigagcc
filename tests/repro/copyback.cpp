// std::copy_backward / std::move_backward on trivial types use __builtin_memmove.
#include <algorithm>
extern "C" void puts_(const char *); extern "C" void puti(long);
int v[20];
__attribute__((noinline)) void up(int *a) { std::copy_backward(a, a + 16, a + 17); }
extern "C" int main() {
  int bad = 0;
  for (int i = 0; i < 20; i++) v[i] = i + 1;
  up(v);
  for (int i = 1; i <= 16; i++) if (v[i] != i) bad++;
  puts_(bad ? "copy_backward: WRONG (" : "copy_backward: right (");
  puti(bad); puts_(" bad)\n");
  return bad != 0;
}
