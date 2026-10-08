/* calls the libnix helpers directly with UtilityBase NULL; writes q,r,p for each pair */
void *UtilityBase = 0;
extern unsigned long __udivsi3(unsigned long, unsigned long), __umodsi3(unsigned long, unsigned long);
extern long __divsi3(long, long), __modsi3(long, long), __mulsi3(long, long);
static unsigned long s = 12345;
static unsigned long rnd(void) { s ^= s << 13; s ^= s >> 17; s ^= s << 5; return s; }
#define N 20000
int go(void) {
  unsigned long *o = (unsigned long *)0x00200000; int i;
  for (i = 0; i < N; i++) {
    unsigned long a = rnd(), b = rnd();
    int k = i & 7;
    if (k == 1) b >>= (rnd() & 31);          /* small divisors */
    if (k == 2) a >>= (rnd() & 31);
    if (k == 3) b |= 0x80000000;            /* huge divisor */
    if (k == 4) b = (rnd() & 7) + 1;
    if (k == 5) a = 0x80000000;
    if (b == 0) b = 1;
    *o++ = a; *o++ = b;
    *o++ = __udivsi3(a, b); *o++ = __umodsi3(a, b);
    *o++ = (unsigned long)__divsi3((long)a, (long)b); *o++ = (unsigned long)__modsi3((long)a, (long)b);
    *o++ = (unsigned long)__mulsi3((long)a, (long)b);
  }
  return N * 7 * 4;
}
