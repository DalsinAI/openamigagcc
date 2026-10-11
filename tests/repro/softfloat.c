/* Soft-float conversions between 64-bit integers and double or float, as a
   -m68060 build does them (no -m68881). libgcc's __floatundidf, __fixunsdfdi
   and the rest are right, but their arithmetic goes through libnix's
   __muldf3, __adddf3, __subdf3, ..., which call mathieeedoubbas.library.
   On an Amiga with an FPU that library works under the task's FPCR, and OS
   3.2.3's IEEE libraries set FPCR in the task that opens them: mathieeedoubbas
   to round toward zero ($10), the ROM's mathieeesingbas to single precision
   ($40). libnix opens them at startup; a program that uses floats as well as
   doubles opens mathieeesingbas last, and every double operation is then
   rounded to single. On Instance-32, t7_64bit -m68060 printed u2d
   00000c22e4500000 (PC 00000c22e4506728) and d2u 14d1120000000000 (PC
   14d1120d7b160000); values 0 and 1 below are those two lines.
   mathieee.s models the libraries and exec's OldOpenLibrary; libnix's own
   __initlibraries opens them, as a program's start code does.
   With -DHOST it prints the expected values instead.
   MIT licence, Copyright (c) 2026 Dalsin Limited. */
typedef unsigned long long u64; typedef long long s64;
#define NI __attribute__((noinline, noclone))
NI double u2d(u64 x) { return (double)x; }
NI u64 d2u(double d) { return (u64)d; }
NI double s2d(s64 x) { return (double)x; }
NI s64 d2s(double d) { return (s64)d; }
NI float u2f(u64 x) { return (float)x; }
NI u64 f2u(float f) { return (u64)f; }
NI float s2f(s64 x) { return (float)x; }
NI s64 f2s(float f) { return (s64)f; }
static u64 dbits(double d) { union { double d; u64 u; } v; v.d = d; return v.u; }
static u64 fbits(float f) { union { float f; unsigned int u; } v; v.f = f; return v.u; }

volatile u64 vu[] = { 0x0123456789abcdefULL, 0x89abcdefULL, 0x1fffffffffffffULL, 0xfedcba9876543210ULL, 0xffffffULL };
volatile double vd[] = { 1.5e18, 4294967295.0, 12884901893.0, 9007199254740991.0, 1.8e19, -1.5e18, -4294967297.0, 3.0 };
volatile float vf[] = { 3.25e12f, 1.0e19f, -3.25e12f };
#define N 21

static void results(u64 *r)
{
  r[0] = (u64)(u2d(vu[0] >> 11) / vd[7]);      /* t7's u2d line */
  r[1] = d2u(vd[0]);                            /* t7's d2u line */
  r[2] = dbits(u2d(vu[1]));                     /* below 2^32 */
  r[3] = dbits(u2d(vu[2]));                     /* 2^53 - 1 */
  r[4] = dbits(u2d(vu[0]));                     /* above 2^53: rounds */
  r[5] = dbits(u2d(vu[3]));                     /* above 2^63 */
  r[6] = d2u(vd[1]); r[7] = d2u(vd[2]); r[8] = d2u(vd[3]); r[9] = d2u(vd[4]);
  r[10] = dbits(s2d(-(s64)vu[0])); r[11] = dbits(s2d(-5 - (s64)vu[1]));
  r[12] = (u64)d2s(vd[5]); r[13] = (u64)d2s(vd[6]);
  r[14] = fbits(u2f(vu[0])); r[15] = fbits(u2f(vu[3])); r[16] = fbits(u2f(vu[4]));
  r[17] = f2u(vf[0]); r[18] = f2u(vf[1]);
  r[19] = fbits(s2f(-(s64)vu[0])); r[20] = (u64)f2s(vf[2]);   /* t7's f2s line */
}

#ifdef HOST
#include <stdio.h>
int main(void) { u64 r[N]; results(r); for (int i = 0; i < N; i++) printf("  0x%016llxULL,%s", r[i], i % 3 == 2 ? "\n" : ""); printf("\n"); return 0; }
#else
static const u64 want[N] = {
  0x00000c22e4506728ULL,  0x14d1120d7b160000ULL,  0x41e13579bde00000ULL,
  0x433fffffffffffffULL,  0x43723456789abcdfULL,  0x43efdb97530eca86ULL,
  0x00000000ffffffffULL,  0x0000000300000005ULL,  0x001fffffffffffffULL,
  0xf9ccd8a1c5080000ULL,  0xc3723456789abcdfULL,  0xc1e13579be800000ULL,
  0xeb2eedf284ea0000ULL,  0xfffffffeffffffffULL,  0x000000005b91a2b4ULL,
  0x000000005f7edcbbULL,  0x000000004b7fffffULL,  0x000002f4b3180000ULL,
  0x8ac7230000000000ULL,  0x00000000db91a2b4ULL,  0xfffffd0b4ce80000ULL
};
extern void puts_(const char *); extern void puti(long);
extern void __initlibraries(void);
extern void fake_OldOpenLibrary(void), missing(void);
extern void dp_add(void), dp_sub(void), dp_mul(void), dp_div(void), dp_cmp(void), dp_tst(void), dp_neg(void), dp_abs(void), dp_fix(void), dp_flt(void);
extern void sp_add(void), sp_sub(void), sp_mul(void), sp_div(void), sp_cmp(void), sp_tst(void), sp_neg(void), sp_abs(void), sp_fix(void), sp_flt(void);
extern void dt_tieee(void), dt_fieee(void);

/* exec and three libraries: jmp vectors below each base; exec's AttnFlags
   (offset 296) say 68060 with FPU, as 68060.library leaves them */
static unsigned short mem[4][(516 + 300) / 2];
#define BASE(i) ((char *)mem[i] + 516)
char *SysBase;
static void vec(char *base, int lvo, void (*fn)(void))
{ unsigned short *p = (unsigned short *)(base - lvo); p[0] = 0x4ef9; p[1] = (unsigned long)fn >> 16; p[2] = (unsigned short)(unsigned long)fn; }
static void set_fpcr(unsigned long v) { __asm__ volatile ("fmove.l %0,fpcr" : : "d"(v)); }
static unsigned long get_fpcr(void) { unsigned long v; __asm__ volatile ("fmove.l fpcr,%0" : "=d"(v)); return v; }
static int same(const char *a, const char *b) { while (*a && *a == *b) a++, b++; return *a == *b; }

void *fake_open(const char *name)
{
  if (same(name, "mathieeedoubbas.library")) { set_fpcr(0x10); return BASE(1); }
  if (same(name, "mathieeesingbas.library")) { set_fpcr(0x40); return BASE(2); }
  if (same(name, "mathieeedoubtrans.library")) return BASE(3);
  puts_("softfloat: WRONG (opened "); puts_(name); puts_(", which is not modelled)\n");
  return 0;
}

static void puthex(unsigned long v, int n) { char b[9]; b[n] = 0; while (n--) { b[n] = "0123456789abcdef"[v & 15]; v >>= 4; } puts_(b); }

int main(void)
{
  u64 r[N]; int bad = 0;
  for (int i = 0; i < 4; i++) for (int lvo = 6; lvo <= 510; lvo += 6) vec(BASE(i), lvo, missing);
  SysBase = BASE(0); *(unsigned short *)(SysBase + 296) = 0xff;
  vec(SysBase, 408, fake_OldOpenLibrary);
  void (*dp[])(void) = { dp_fix, dp_flt, dp_cmp, dp_tst, dp_abs, dp_neg, dp_add, dp_sub, dp_mul, dp_div };
  void (*sp[])(void) = { sp_fix, sp_flt, sp_cmp, sp_tst, sp_abs, sp_neg, sp_add, sp_sub, sp_mul, sp_div };
  for (int i = 0; i < 10; i++) { vec(BASE(1), 30 + 6 * i, dp[i]); vec(BASE(2), 30 + 6 * i, sp[i]); }
  vec(BASE(3), 102, dt_tieee); vec(BASE(3), 108, dt_fieee);
  __initlibraries();
  unsigned long fpcr = get_fpcr();
  results(r);
  for (int i = 0; i < N; i++)
    if (r[i] != want[i]) {
      bad++; puts_("  value "); puti(i); puts_(": "); puthex(r[i] >> 32, 8); puthex(r[i], 8);
      puts_(", PC "); puthex(want[i] >> 32, 8); puthex(want[i], 8); puts_("\n");
    }
  puts_(bad ? "softfloat: WRONG (" : "softfloat: right ("); puti(bad); puts_(" of 21 values wrong; FPCR $");
  puthex(fpcr, 2); puts_(" once libnix had opened the IEEE libraries)\n");
  return bad != 0;
}
#endif
