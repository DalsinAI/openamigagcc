| Models of OS 3.2.3's IEEE maths libraries on an Amiga with an FPU, and of
| exec's OldOpenLibrary, for softfloat.c (raw 68k image under qemu-m68k).
| What is modelled, from the OS files themselves (Instance-32, 11 October 2026):
|  - mathieeedoubbas.library 47.3 (Libs:): with an FPU (AttnFlags bit 4), Open
|    runs "moveq #16,d0; fmove.l d0,fpcr" in the opening task: round toward
|    zero. IEEEDPAdd/Sub/Mul/Div move the operands through the stack into FP0
|    (fmove.d), do the operation (fadd.d etc.) and move FP0 back (fmove.d): all
|    under the task's FPCR.
|  - mathieeesingbas.library 47.1 (Kickstart 3.2.3 ROM, $F85892): with an FPU,
|    Open runs "moveq #64,d0; fmove.l d0,fpcr": single precision.
|  - mathieeedoubtrans.library 47.2: Open leaves FPCR alone.
| The vectors are filled in by softfloat.c; the Open side effects are in
| softfloat.c's fake_open. MIT licence, Copyright (c) 2026 Dalsin Limited.
	.text
	.globl _fake_OldOpenLibrary
_fake_OldOpenLibrary:			| a1 = name; d0 = base
	move.l a1,-(sp)
	jsr _fake_open
	addq.l #4,sp
	rts

	.globl _missing
_missing:				| a vector nobody modelled
	pea nomodel
	jsr _puts_
	moveq #1,d1
	moveq #1,d0
	trap #0

	.globl _exit
_exit:					| libnix's __openliberror ends with exit(20)
	move.l 4(sp),d1
	moveq #1,d0
	trap #0

| mathieeedoubbas: doubles in d0:d1 and d2:d3, result in d0:d1
	.globl _dp_add,_dp_sub,_dp_mul,_dp_div,_dp_cmp,_dp_tst,_dp_neg,_dp_abs,_dp_fix,_dp_flt
_dp_add:
	movem.l d0-d3,-(sp)
	fmove.d (sp)+,fp0
	fadd.d (sp),fp0
	fmove.d fp0,(sp)
	movem.l (sp)+,d0-d1
	rts
_dp_sub:
	movem.l d0-d3,-(sp)
	fmove.d (sp)+,fp0
	fsub.d (sp),fp0
	fmove.d fp0,(sp)
	movem.l (sp)+,d0-d1
	rts
_dp_mul:
	movem.l d0-d3,-(sp)
	fmove.d (sp)+,fp0
	fmul.d (sp),fp0
	fmove.d fp0,(sp)
	movem.l (sp)+,d0-d1
	rts
_dp_div:
	movem.l d0-d3,-(sp)
	fmove.d (sp)+,fp0
	fdiv.d (sp),fp0
	fmove.d fp0,(sp)
	movem.l (sp)+,d0-d1
	rts
_dp_cmp:				| d0 = 1, 0 or -1 as a >, = or < b
	movem.l d0-d3,-(sp)
	fmove.d (sp)+,fp0
	fcmp.d (sp)+,fp0
	bra fsign
_dp_tst:
	movem.l d0-d1,-(sp)
	fmove.d (sp)+,fp0
	ftst.x fp0
fsign:	fbgt 1f
	fblt 2f
	moveq #0,d0
	rts
1:	moveq #1,d0
	rts
2:	moveq #-1,d0
	rts
_dp_neg:
	bchg #31,d0
	rts
_dp_abs:
	bclr #31,d0
	rts
_dp_fix:
	movem.l d0-d1,-(sp)
	fmove.d (sp)+,fp0
	fintrz.x fp0,fp0
	fmove.l fp0,d0
	rts
_dp_flt:
	fmove.l d0,fp0
	fmove.d fp0,-(sp)
	movem.l (sp)+,d0-d1
	rts

| mathieeesingbas: singles in d0 and d1, result in d0
	.globl _sp_add,_sp_sub,_sp_mul,_sp_div,_sp_cmp,_sp_tst,_sp_neg,_sp_abs,_sp_fix,_sp_flt
_sp_add:
	fmove.s d0,fp0
	fadd.s d1,fp0
	fmove.s fp0,d0
	rts
_sp_sub:
	fmove.s d0,fp0
	fsub.s d1,fp0
	fmove.s fp0,d0
	rts
_sp_mul:
	fmove.s d0,fp0
	fmul.s d1,fp0
	fmove.s fp0,d0
	rts
_sp_div:
	fmove.s d0,fp0
	fdiv.s d1,fp0
	fmove.s fp0,d0
	rts
_sp_cmp:
	fmove.s d0,fp0
	fcmp.s d1,fp0
	bra fsign
_sp_tst:
	fmove.s d0,fp0
	ftst.x fp0
	bra fsign
_sp_neg:
	bchg #31,d0
	rts
_sp_abs:
	bclr #31,d0
	rts
_sp_fix:
	fmove.s d0,fp0
	fintrz.x fp0,fp0
	fmove.l fp0,d0
	rts
_sp_flt:
	fmove.l d0,fp0
	fmove.s fp0,d0
	rts

| mathieeedoubtrans: IEEEDPTieee (double to single), IEEEDPFieee (single to double)
	.globl _dt_tieee,_dt_fieee
_dt_tieee:
	movem.l d0-d1,-(sp)
	fmove.d (sp)+,fp0
	fmove.s fp0,d0
	rts
_dt_fieee:
	fmove.s d0,fp0
	fmove.d fp0,-(sp)
	movem.l (sp)+,d0-d1
	rts

| the head and the end of libnix's list of libraries to open, as its start code
| (ncrt0.S) has them; libstubs' library bases go between
	.globl ___LIB_LIST__
	.section .dlist___LIB_LIST__,"aw"
___LIB_LIST__:
	.long 0
	.section .end_of_dlists,"aw"
	.long 0

	.data
	.globl _DOSBase
_DOSBase:
	.long 0
nomodel:
	.asciz "softfloat: WRONG (a library function that is not modelled was called)\n"
	.even
