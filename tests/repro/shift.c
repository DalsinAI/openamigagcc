/* Loop-shift reproducer: an overlapping "shift up" loop with a constant count.
   Loop distribution turns it into memmove (to, from overlap: to = from + 1
   element); the m68k back end must not expand it as a forward copy. */
extern void puts_(const char *); extern void puti(long);
#define N 16
int v[N + 1];
unsigned char b[40];
short h[200];
__attribute__((noinline)) void shift_up(int *a) { for (int i = N; i > 0; --i) a[i] = a[i - 1]; }
__attribute__((noinline)) void shift_up_b(unsigned char *a) { for (int i = 33; i > 0; --i) a[i] = a[i - 1]; }
__attribute__((noinline)) void shift_up_h(short *a) { for (int i = 190; i > 0; --i) a[i] = a[i - 1]; }
int main(void) {
  int bad = 0;
  for (int i = 0; i <= N; i++) v[i] = i + 1;
  shift_up(v);
  for (int i = 1; i <= N; i++) if (v[i] != i) bad++;
  for (int i = 0; i < 40; i++) b[i] = i;
  shift_up_b(b);
  for (int i = 1; i <= 33; i++) if (b[i] != i - 1) bad++;
  for (int i = 0; i < 200; i++) h[i] = i;
  shift_up_h(h);
  for (int i = 1; i <= 190; i++) if (h[i] != i - 1) bad++;
  puts_(bad ? "shift: WRONG (" : "shift: right (");
  puti(bad); puts_(" bad)\n");
  return bad != 0;
}
