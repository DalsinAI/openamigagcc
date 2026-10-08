// cxx: static constructor, exception, std::string, and __stack, on the patched start code
#include <cstdio>
#include <string>
#include <stdexcept>
#include <proto/exec.h>
extern "C" { unsigned long __stack = 200000; }
static std::string g("ctor-ran");
static int deep(int n) { volatile char b[512]; b[0] = n; return n ? deep(n - 1) + b[0] : 0; }
int main() {
	struct Task *t = FindTask(nullptr);
	unsigned long size = (char *) t->tc_SPUpper - (char *) t->tc_SPLower;
	std::string r;
	try { throw std::runtime_error("caught"); } catch (const std::exception &e) { r = e.what(); }
	int d = size >= 200000 ? deep(300) : -1;
	FILE *f = fopen("DH1:Lab/results.log", "a");
	int want = 0; for (int i = 1; i <= 300; i++) want += (char) i;
	bool ok = g == "ctor-ran" && r == "caught" && d == want;
	if (f) { fprintf(f, "cxx: %s %s stack %lu deep %d (%s)\n", g.c_str(), r.c_str(), size, d, ok ? "PASS" : "FAIL"); fclose(f); }
	return ok ? 0 : 10;
}
