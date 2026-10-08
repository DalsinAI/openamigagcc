/*
 * utilbase: defines its own UtilityBase (so libnix doesn't open it) and prints
 * numbers before opening it. Built -m68000, where division goes through libnix.
 */
#include <stdio.h>
#include <proto/exec.h>
struct Library *UtilityBase;
int main(void) {
	volatile unsigned long a = 4000000000UL, b = 7;
	volatile long c = -1000000, d = 3;
	char buf[80];
	FILE *f;
	snprintf(buf, sizeof buf, "%lu %lu %ld %ld %ld", a / b, a % b, c / d, c % d, c * d);
	f = fopen("DH1:Lab/results.log", "a");
	if (f) {
		fprintf(f, "utilbase: %s (%s)\n", buf, __builtin_strcmp(buf, "571428571 3 -333333 -1 -3000000") ? "FAIL" : "PASS");
		fclose(f);
	}
	return 0;
}
