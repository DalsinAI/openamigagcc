	.text
	.globl _start
_start:
	move.l #0x00e00000,sp
	jsr _go
	move.l d0,d3
	moveq #4,d0
	moveq #1,d1
	move.l #0x00200000,d2
	trap #0
	moveq #1,d0
	moveq #0,d1
	trap #0
