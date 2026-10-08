/* Minimal runtime for the reproducers: raw 68k images run under qemu-m68k
   (Linux syscalls through trap #0). MIT licence, Copyright (c) 2026 Dalsin Limited. */
#include <stddef.h>
extern int sys_write(const void *, size_t);
void *memcpy(void *d, const void *s, size_t n) { volatile unsigned char *a = d; const unsigned char *b = s; while (n--) *a++ = *b++; return d; }
void *memmove(void *d, const void *s, size_t n) { volatile unsigned char *a = d; const volatile unsigned char *b = s; if (a < b) while (n--) *a++ = *b++; else { a += n; b += n; while (n--) *--a = *--b; } return d; }
void *memset(void *d, int c, size_t n) { volatile unsigned char *a = d; while (n--) *a++ = (unsigned char)c; return d; }
void *__bcopz(const void *s, void *d, size_t n) { return memmove(d, s, n); }
void puts_(const char *s) { size_t n = 0; while (s[n]) n++; sys_write(s, n); }
/* No division: a 68000 has no 32-bit divide, and no libgcc is linked. */
void putu(unsigned long v) { static const unsigned long p[] = { 1000000000, 100000000, 10000000, 1000000, 100000, 10000, 1000, 100, 10, 1 };
  char b[12]; int n = 0; for (int i = 0; i < 10; i++) { char d = '0'; while (v >= p[i]) { v -= p[i]; d++; } if (d != '0' || n || i == 9) b[n++] = d; } b[n] = 0; puts_(b); }
void puti(long v) { if (v < 0) { puts_("-"); putu(-v); } else putu(v); }
