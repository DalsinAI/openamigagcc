/* calloc reproducer: a program's own calloc built from malloc+memset.
   GCC must not turn it into a call to calloc (itself). */
#include <stddef.h>
extern void puts_(const char *);
void *memset(void *, int, size_t);
static unsigned char pool[4096]; static size_t used;
__attribute__((noinline)) void *malloc(size_t n) { void *p = pool + used; used += (n + 7) & ~7u; return p; }
void free(void *p) { (void)p; }
static int depth;
void *calloc(size_t a, size_t b) {
  if (++depth > 1) { puts_("calloc: WRONG (calloc called itself)\n"); return 0; }
  size_t n = a * b; void *v = malloc(n);
  if (v) memset(v, 0, n);
  depth--; return v;
}
int main(void) {
  for (int i = 0; i < 64; i++) pool[i] = 0xAA;
  unsigned char *p = calloc(8, 8);
  if (!p) return 1;
  for (int i = 0; i < 64; i++) if (p[i]) { puts_("calloc: WRONG (not zeroed)\n"); return 1; }
  puts_("calloc: right\n");
  return 0;
}
