/* The vregs pass must leave no virtual register.  strcat(want, phrase),
   want a local array and phrase a constant, became a call to strlen and an
   inline copy to want + strlen(want), whose address was loaded with one lea
   of virtual-stack-vars + length - 600.  vregs instantiated only operands
   that are registers or memory, not this address, so the virtual register
   stayed, combine then dropped it, and the copy went to strlen(want) - 600,
   an absolute address.  GFOffice's OWFLibTest (owf_lib_checks.c), reduced.
   MIT licence, Copyright (c) 2026 AmigaChrome Team. */
#include <string.h>
extern void puts_(const char *);
#define PHRASE "owf.library 2 inflates this with libowf's own inflate. "
#define TAIL "Gruesse aus Koeln.\n"

__attribute__((noinline)) int texts_differ(void)
{
  static const char phrase[] = PHRASE;
  static const char expect[] = PHRASE PHRASE PHRASE PHRASE PHRASE PHRASE TAIL;
  char want[600];
  int i, n;
  want[0] = 0;
  for (i = 0; i < 6; i++)
    strcat(want, phrase);
  strcat(want, TAIL);
  for (n = 0; expect[n] && want[n] == expect[n]; n++)
    ;
  return want[n] != expect[n];
}

int main(void)
{
  int bad = texts_differ();
  puts_(bad ? "vregs: WRONG (strcat into a local array made another text)\n"
            : "vregs: right (strcat into a local array)\n");
  return bad;
}
