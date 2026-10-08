# sys-include additions

`fenv.h` (C99 floating-point environment, header-only, through the FPU's FPCR and FPSR) and `uchar.h` (C11 `char16_t`/`char32_t`) for libnix, which has neither. `scripts/build.sh` copies them into amiga-gcc's `sys-include`. MIT licence, Copyright (c) 2026 Dalsin Limited.
