# Mixing GCC 6.5 and GCC 16 code on AmigaOS 3.x

- **Struct returns:** GCC 6.5 passes the address of a returned struct in **A0**; GCC 16 takes it in **A1**. A GCC 6.5 program calling a GCC 16-built function that returns a struct gets garbage, and the callee writes 12–16 bytes wherever A1 points. Libraries meant for both compilers should return structs through a pointer argument instead. (Found with SDL 2's GUID and binding calls.)
- **Floating point:** functions returning `float` or `double` need both sides built with `-m68881`; a soft-float caller reads the result wrongly.
- **NULL reads:** build with `-fno-delete-null-pointer-checks` on both compilers, or provable NULL reads become `trap #7`.
