/* Only OS-dependent errno storage and reporting are replaced. Conversion,
 * character classification and wide-digit checking come from built libnix. */
#include <stddef.h>
static int error_value;
int *__errno = &error_value;
int printf(const char *format, ...) { (void)format; return 0; }
char *strcpy(char *out, const char *in) {
    char *p = out;
    while ((*p++ = *in++)) {}
    return out;
}
size_t strlen(const char *s) {
    size_t n = 0;
    while (s[n]) ++n;
    return n;
}
