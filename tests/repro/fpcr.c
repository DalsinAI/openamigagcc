/* FPCR clash reproducer (-m68040): (int)float with the store address indexed
   by a register; GCC must not save FPCR into that index register. */
extern void puts_(const char *); extern void puti(long);
int out[256]; float val[64]; unsigned char idx[64];
__attribute__((noinline)) void scatter(int *o, const unsigned char *ix, const float *f, int n) {
  for (int i = 0; i < n; i++) o[*ix++] = (int)f[i];
}
int main(void) {
  int bad = 0;
  for (int i = 0; i < 64; i++) { idx[i] = (unsigned char)(i * 3); val[i] = i + 0.75f; }
  scatter(out, idx, val, 64);
  for (int i = 0; i < 64; i++) if (out[i * 3] != i) bad++;
  puts_(bad ? "fpcr: WRONG (" : "fpcr: right ("); puti(bad); puts_(" bad)\n");
  return bad != 0;
}
