/* Nested inline library calls: Stricmp(FilePart(path), ...) must call
   utility.library with UtilityBase in A6, not DOSBase. The NDK's inline
   headers come from sfdc; with A6 bound before the arguments were evaluated,
   FilePart's DOSBase was still in A6 when Stricmp's jsr -162(a6) ran.
   The two "libraries" here are jump tables built at run time, and each
   function records the A6 it was called with. */
#include <proto/dos.h>
#include <proto/utility.h>
extern void puts_(const char *); extern void puti(long);

__typeof__(DOSBase) DOSBase;                  /* each as the NDK declares it */
__typeof__(UtilityBase) UtilityBase;
void *dos_a6, *util_a6, *util_s1, *util_s2;
static unsigned short dosmem[480], utilmem[100];

/* FilePart returns path + 4 ("dir/"); Stricmp returns 0 */
__asm__("\t.text\n"
        "_fake_filepart:\n\tmove.l a6,_dos_a6\n\tmove.l d1,d0\n\taddq.l #4,d0\n\trts\n"
        "_fake_stricmp:\n\tmove.l a6,_util_a6\n\tmove.l a0,_util_s1\n\tmove.l a1,_util_s2\n\tmoveq #0,d0\n\trts\n");
extern void fake_filepart(void), fake_stricmp(void);

static void vector(void *base, int lvo, void (*fn)(void)) {
  volatile unsigned short *p = (volatile unsigned short *)((char *)base - lvo);
  p[0] = 0x4ef9;                              /* jmp fn */
  p[1] = (unsigned long)fn >> 16; p[2] = (unsigned long)fn;
}

static const char path[] = "dir/frame.config";
__attribute__((noinline)) LONG first(CONST_STRPTR f) { return Stricmp(FilePart(f), "frame.config"); }
__attribute__((noinline)) LONG second(CONST_STRPTR f) { return Stricmp("frame.config", FilePart(f)); }

int main(void) {
  int bad = 0;
  DOSBase = (void *)((char *)dosmem + 936);
  UtilityBase = (void *)((char *)utilmem + 192);
  vector(DOSBase, 870, fake_filepart);        /* FilePart: -870 */
  vector(UtilityBase, 162, fake_stricmp);     /* Stricmp: -162 */
  vector(DOSBase, 162, fake_stricmp);         /* so a call through the wrong base shows, not crashes */

  util_a6 = 0; first(path);
  if (dos_a6 != DOSBase || util_a6 != UtilityBase || util_s1 != path + 4) bad |= 1;
  util_a6 = 0; second(path);
  if (dos_a6 != DOSBase || util_a6 != UtilityBase || util_s2 != path + 4) bad |= 2;
  if (bad) { puts_("nested: WRONG (Stricmp ran with "); puts_(util_a6 == DOSBase ? "DOSBase" : "another base");
             puts_(" in A6, case "); puti(bad); puts_(")\n"); }
  else puts_("nested: right (Stricmp(FilePart(x)) calls utility.library with UtilityBase in A6)\n");
  return bad;
}
