# libnix strtol/strtoul: end pointer on empty input

The native GCC 16.2.0-open3 libraries fail three of fourteen ordinary
conversion controls: `strtol("")`, `strtol(" ")`, and `strtoul("")` do not
return the original input pointer through `endptr`. Both functions return
before assigning it on empty input. In addition, `strtol` strips whitespace
and passes an uninitialised local end pointer to `strtoul`, which previously
left it untouched when that stripped string was empty.

A caller that consumes a token only when `end != input` can consequently
continue after the final token, copy from an invalid address or overwrite
its output array. The OpenTyrian native trace reached its first shop
inventory line before stopping; its `str_pop_int` loop uses this contract.
Replacing just these two library implementations allowed the same engine
objects to reach the shop and the first level.

Patch 0008 initialises the end pointer before early returns and initialises
`strtol`'s local pointer. It preserves the existing errno policy and changes
no public ABI. This is a common libc correction, not game-specific parsing.
The patch applies to the libnix source pinned by this repository's build
recipe and was checked through its `git apply` path.

## Native control, 25 October 2026

Build `tests/libnix/strtol_endptr.c` with the selected target compiler and
libnix. Its volatile function pointers exercise the actual library entries.
It tests empty strings, whitespace-only strings, non-numeric input, zero,
multiple numbers, a suffix and a negative value for both signed and unsigned
conversion. An end pointer is checked against the exact expected position.

On an isolated AC090 lab, 68040/FPU:

- Original 16.2.0-open3 libraries: three failures, RC 20.
- Same compiler with the two corrected libc objects: zero failures, RC 0.
- The unchanged OpenTyrian engine objects, relinked with those objects and
  tested with a separate shared SDL window-resize candidate, reached the
  shop and launched the first level. This is bounded port evidence, not a
  full game release or complete compiler qualification.

The qualification used explicit replacement objects before the installed
libraries. A simple `-L` overlay did not override GCC's multilib selection;
that unsuccessful overlay is not evidence of the correction. Link maps
confirmed the corrected objects supplied the tested symbols. Installed
compiler prefixes, live instances and SDK releases were not changed.

Before shipping, rebuild libnix through the normal compiler recipe for all
supported CPU, floating-point and base-relative profiles, repeat this native
control and the existing compiler qualification gates, and rebuild consumers.
The initial local objects are only a 68040/FPU test candidate. No upload,
upstream CI, merge, or toolchain release is implied by these local results.
