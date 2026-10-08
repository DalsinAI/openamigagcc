/*
 * stackdeep: defines __stack and nothing else about the stack. Reports the
 * stack it runs on, then recurses about 200 KB deep. Appends one line to
 * DH1:Lab/results.log (works from a Shell and from Workbench).
 * Built with -DFORCE it also names __stkinit, the old documented way to pull
 * in the swap module.
 */
#include <stdio.h>
#include <string.h>
#include <proto/exec.h>
#include <exec/tasks.h>

unsigned long __stack = 300000;
#ifdef FORCE
extern void __stkinit(void);
void *__x = __stkinit;
#endif
#ifndef NAME
#define NAME "stackdeep"
#endif

static int deep(int n) {
	volatile char buf[1024];
	buf[0] = (char) n;
	buf[1023] = (char) (n >> 1);
	if (n == 0)
		return buf[0] + buf[1023];
	return deep(n - 1) + buf[0] - buf[1023];
}

int main(int argc, char **argv) {
	struct Task *t = FindTask(NULL);
	unsigned long size = (char *) t->tc_SPUpper - (char *) t->tc_SPLower;
	char here;
	int ok = size >= 300000 && (char *) &here > (char *) t->tc_SPLower && (char *) &here < (char *) t->tc_SPUpper;
	int r = 0;
	FILE *f;

	if (ok)
		r = deep(190);	/* ~195 KB, only on a stack that has room */
	f = fopen("DH1:Lab/results.log", "a");
	if (f) {
		fprintf(f, "%s from %s: stack %lu bytes, sp %s, %s (r=%d)\n", NAME, argc ? "Shell" : "Workbench", size,
			((char *) &here > (char *) t->tc_SPLower && (char *) &here < (char *) t->tc_SPUpper) ? "inside" : "OUTSIDE",
			ok ? "PASS recursed 190 KB" : "FAIL stack too small, not recursing", r);
		fclose(f);
	}
	return ok ? 0 : 10;
}
