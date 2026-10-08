/* Null-read reproducer: address 0 is memory on a 68k Amiga.
   GCC must read it, not emit TRAP #7. */
extern void puts_(const char *);
volatile unsigned long sink;
__attribute__((noinline)) unsigned long rd(unsigned long *p) { return *p; }
int main(void) {
  unsigned long *p = 0;
  sink = *p;            /* provably null: -fdelete-null-pointer-checks makes this TRAP #7 */
  puts_("null: right (address 0 read)\n");
  return 0;
}
