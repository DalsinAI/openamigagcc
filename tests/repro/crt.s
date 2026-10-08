| Start code for raw 68k images under qemu-m68k. MIT licence, Copyright (c) 2026 Dalsin Limited.
	.text
	.globl _start
_start:
	move.l #0x00e00000,sp
	jsr _main
	move.l d0,d1
	moveq #1,d0
	trap #0
	.globl _sys_write
_sys_write:
	movem.l d2-d3,-(sp)
	moveq #4,d0
	moveq #1,d1
	move.l 12(sp),d2
	move.l 16(sp),d3
	trap #0
	movem.l (sp)+,d2-d3
	rts
