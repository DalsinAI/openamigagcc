/* wbgo NAME: starts NAME as if double-clicked on Workbench (workbench.library 44) */
#include <proto/exec.h>
#include <proto/wb.h>
#include <stdio.h>
struct Library *WorkbenchBase;
int main(int argc, char **argv) {
	int ok = 0;
	if (argc < 2) return 20;
	if ((WorkbenchBase = OpenLibrary("workbench.library", 44))) {
		ok = OpenWorkbenchObjectA((STRPTR) argv[1], NULL);
		CloseLibrary(WorkbenchBase);
	}
	printf("wbgo %s: %s\n", argv[1], ok ? "started" : "FAILED");
	return ok ? 0 : 10;
}
