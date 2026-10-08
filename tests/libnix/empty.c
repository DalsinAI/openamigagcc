/* empty: must return to the Shell. -DRC=n returns n, -DEXIT=n calls exit(n). */
#include <stdlib.h>
int main(void) {
#ifdef EXIT
	exit(EXIT);
#endif
#ifdef RC
	return RC;
#else
	return 0;
#endif
}
