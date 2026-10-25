/* A move whose source post-increments or pre-decrements an address register
   must not address its destination through that register: the 68k works out
   the destination after the source's increment.  GCC 16's late-combine pass
   put a store's address, computed from the register a copy loop steps, into
   the move: "move.b (a2)+,(a0,a2.l)", so each byte landed one late.
   fmt is GFOffice's owf_number_text (libowf), reduced: 6.5 came out "6.w".
   The copy loops are PR123853's (SImode, HImode, SFmode), and the same for
   bytes, 64-bit and 96-bit values (DImode, DFmode, XFmode).
   MIT licence, Copyright (c) 2026 AmigaChrome Team. */
extern void puts_(const char *); extern void puti(long);

__attribute__((noinline)) void fmt(char *out, const char *src, int nd, int e)
{
  char digits[16], *p = out;
  int i;
  for (i = 0; i < 15; i++)
    digits[i] = src[i];
  if (e >= 15 || e < -9) {
    *p++ = digits[0];
    if (nd > 1) {
      *p++ = '.';
      for (i = 1; i < nd; i++)
        *p++ = digits[i];
    }
    *p++ = 'E';
    *p++ = e < 0 ? '-' : '+';
    if (e < 0)
      e = -e;
    if (e >= 100) {               /* no division: a 68000 has none */
      char h = '0';
      for (; e >= 100; e -= 100)
        h++;
      *p++ = h;
    }
    char t = '0';
    for (; e >= 10; e -= 10)
      t++;
    *p++ = t;
    *p++ = (char)('0' + e);
  } else if (e >= 0) {
    for (i = 0; i <= e; i++)
      *p++ = i < nd ? digits[i] : '0';
    if (nd > e + 1) {
      *p++ = '.';
      for (; i < nd; i++)
        *p++ = digits[i];
    }
  } else {
    *p++ = '0';
    *p++ = '.';
    for (i = -1; i > e; i--)
      *p++ = '0';
    for (i = 0; i < nd; i++)
      *p++ = digits[i];
  }
  *p = 0;
}

/* dst[i] = src[i] downwards ("move.l -(a0),(a0,d1.l)") and upwards
   ("move.l (a0)+,(a0,d1.l)"); the count is the source's first byte */
struct hdr { char n; };
#define COPY(T, x) \
  int base_##x; struct hdr *hdr_##x; long i_##x; \
  __attribute__((noinline)) void down_##x(void) { \
    T *dst = (T *)base_##x; \
    i_##x = hdr_##x->n; \
    for (; i_##x; i_##x--) dst[i_##x] = ((T *)hdr_##x)[i_##x]; } \
  __attribute__((noinline)) void up_##x(long n) { \
    T *dst = (T *)base_##x, *src = (T *)hdr_##x; \
    for (long i = 0; i < n; i++) dst[i] = src[i]; }
COPY(char, b) COPY(short, w) COPY(int, l) COPY(float, f)
COPY(long long, q) COPY(double, d) COPY(long double, x)

static long check(void (*down)(void), void (*up)(long), int *base, struct hdr **hdr, int size)
{
  static unsigned char src[16 * 12] __attribute__((aligned(4))), dst[16 * 12] __attribute__((aligned(4)));
  long bad = 0;
  for (int i = 0; i < (int)sizeof src; i++) src[i] = (unsigned char)(i * 7 + 1);
  src[0] = 9;
  for (int pass = 0; pass < 2; pass++) {
    for (int i = 0; i < (int)sizeof dst; i++) dst[i] = 0xEE;
    *base = (int)dst; *hdr = (struct hdr *)src;
    if (pass == 0) down(); else up(10);
    /* down copies elements 9..1, up copies 0..9 */
    for (int i = pass ? 0 : size; i < 10 * size; i++) if (dst[i] != src[i]) { bad++; break; }
    if (dst[10 * size] != 0xEE) bad++;
  }
  return bad;
}

int main(void)
{
  static const struct { const char *digits; int nd, e; const char *want; } t[] = {
    { "65", 2, 0, "6.5" }, { "314159265358979", 15, 0, "3.14159265358979" },
    { "125", 3, 1, "12.5" }, { "15", 2, 4, "15000" }, { "5", 1, -1, "0.5" },
    { "123", 3, 20, "1.23E+20" }, { "7", 1, -12, "7E-12" },
  };
  char out[40], digits[16];
  long bad = 0;
  for (int k = 0; k < (int)(sizeof t / sizeof t[0]); k++) {
    int n = 0;
    while (t[k].digits[n]) { digits[n] = t[k].digits[n]; n++; }
    while (n < 15) digits[n++] = '0';
    fmt(out, digits, t[k].nd, t[k].e);
    for (n = 0; out[n] == t[k].want[n] && out[n]; n++)
      ;
    if (out[n] != t[k].want[n]) bad++;
  }
  bad += check(down_b, up_b, &base_b, &hdr_b, 1) + check(down_w, up_w, &base_w, &hdr_w, 2)
       + check(down_l, up_l, &base_l, &hdr_l, 4) + check(down_f, up_f, &base_f, &hdr_f, 4)
       + check(down_q, up_q, &base_q, &hdr_q, 8) + check(down_d, up_d, &base_d, &hdr_d, 8)
       + check(down_x, up_x, &base_x, &hdr_x, (int)sizeof(long double));
  puts_(bad ? "autoinc: WRONG (" : "autoinc: right ("); puti(bad); puts_(" of 21 results wrong)\n");
  return bad != 0;
}
