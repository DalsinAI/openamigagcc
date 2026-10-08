/* Explicit memmove with a constant size and overlapping buffers
   (destination above source): must copy backwards. */
/* __builtin_memmove: what loop distribution and code without <string.h> get */
#define memmove __builtin_memmove
extern void puts_(const char *); extern void puti(long);
int v[20]; short h[200];
__attribute__((noinline)) void up(int *a) { memmove(a + 1, a, 16 * sizeof(int)); }
__attribute__((noinline)) void uph(short *a) { memmove(a + 1, a, 190 * sizeof(short)); }
__attribute__((noinline)) void down(int *a) { memmove(a, a + 1, 16 * sizeof(int)); }
/* Two unrelated pointers: the direction is only known at run time. */
__attribute__((noinline)) void mv(int *d, const int *s) { memmove(d, s, 16 * sizeof(int)); }
__attribute__((noinline)) void mvb(char *d, const char *s) { memmove(d, s, 37); }
char c[64];
int main(void) {
  int bad = 0;
  for (int i = 0; i < 20; i++) v[i] = i + 1;
  up(v);
  for (int i = 1; i <= 16; i++) if (v[i] != i) bad++;
  for (int i = 0; i < 200; i++) h[i] = i;
  uph(h);
  for (int i = 1; i <= 190; i++) if (h[i] != i - 1) bad++;
  for (int i = 0; i < 20; i++) v[i] = i;
  down(v);
  for (int i = 0; i < 16; i++) if (v[i] != i + 1) bad++;
  for (int i = 0; i < 20; i++) v[i] = i;
  mv(v + 3, v);                         /* destination above the source */
  for (int i = 0; i < 16; i++) if (v[i + 3] != i) bad++;
  for (int i = 0; i < 20; i++) v[i] = i;
  mv(v, v + 3);                         /* destination below the source */
  for (int i = 0; i < 16; i++) if (v[i] != i + 3) bad++;
  for (int i = 0; i < 64; i++) c[i] = i;
  mvb(c + 5, c + 1);                    /* odd sizes and addresses */
  for (int i = 0; i < 37; i++) if (c[i + 5] != i + 1) bad++;
  for (int i = 0; i < 64; i++) c[i] = i;
  mvb(c + 1, c + 6);
  for (int i = 0; i < 37; i++) if (c[i + 1] != i + 6) bad++;
  puts_(bad ? "memmove: WRONG (" : "memmove: right (");
  puti(bad); puts_(" bad)\n");
  return bad != 0;
}
