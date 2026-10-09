/* A C library's own memset written with a helper loop. With loop distribution
   on, the helper's loop becomes a call to memset, and memset calls the helper:
   endless recursion. A library that defines memcpy/memmove/memset/calloc
   builds with -fno-tree-loop-distribute-patterns (libnix's build does); this
   is the check that the option still keeps the loop a loop. */
#include <stddef.h>
static __attribute__((noinline)) void fill_bytes(unsigned char *p, int c, size_t n)
{
  while (n--) *p++ = (unsigned char)c;
}
void *memset(void *s, int c, size_t n) { fill_bytes(s, c, n); return s; }
