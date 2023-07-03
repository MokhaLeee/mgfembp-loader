.section ".crt0","ax"
.arm

.include "gba.inc"
#include "macro.inc"

.global _start
_start:
	b	reset

rom_header:
	.fill	156,1,0		@ Nintendo Logo Character Data (8000004h)
	.fill	16,1,0		@ Game Title
	.byte	0x30,0x31	@ Maker Code (80000B0h)
	.byte	0x96		@ Fixed Value (80000B2h)
	.byte	0x00		@ Main Unit Code (80000B3h)
	.byte	0x00		@ Device Type (80000B4h)
	.fill	7,1,0		@ unused
	.byte	0x00		@ Software Version No (80000BCh)
	.byte	0xf0		@ Complement Check (80000BDh)
	.byte	0x00,0x00	@ Checksum (80000BEh)

reset:
	b	start_vector	@ This branch must be here for proper
				@ positioning of the following header.

	.global	__boot_method, __slave_number
__boot_method:
	.byte	0		@ boot method (0=ROM boot, 3=Multiplay boot)
__slave_number:
	.byte	0		@ slave # (1=slave#1, 2=slave#2, 3=slave#3)
	.byte	0 		@ reserved
	.byte	0 		@ reserved
	.word	0		@ reserved
	.word	0		@ reserved
	.word	0		@ reserved
	.word	0		@ reserved
	.word	0		@ reserved
	.word	0		@ reserved

	.global start_vector
	.align
start_vector:
	@ Disable all interrupts
	ldr	r1, =REG_IME
	mov	r0, #0
	str	r0, [r1]

	@ Switch to IRQ Mode
	mov	r0, #0x12
	msr	cpsr_fc, r0
	ldr	sp, =__sp_irq

	@ Switch to System Mode
	mov	r0, #0x1f
	msr	cpsr_fc, r0
	ldr	sp, =__sp_usr

	@ Switch to thumb mode
	add	r0, pc, #1
	bx	r0
	.thumb

.type start_thumb %function
start_thumb:
	@ Clear EWRAM
	mov	r1, #0x40
	lsl	r1, #12				@ r1 = 0x40000
	lsl	r0, r1, #7			@ r0 = 0x2000000
	bl	ClearMem

	@ Copy .text.ewram section to EWRAM
	ldr	r1, =__text_cpy_start
	ldr	r2, =__ewram_text_start
	ldr	r3, =__text_cpy_end
	sub	r3, r3, r1
	bl	CopyMem

	@ Clear IWRAM
	ldr	r0, =__bss_start__
	ldr	r1, =__bss_end__
	sub	r1, r0
	bl	ClearMem

	@ Jump to EWRAM
	ldr	r1, =__ewram_text_start
	mov	lr, pc
	bx	r1

	swi	#0x00				@ SoftReset

@ r0 = Start Address
@ r1 = Length
.align
.type ClearMem %function
ClearMem:
	mov	r2,#3				@ These	commands are used in cases where
	add	r1,r2				@ the length is	not a multiple of 4,
	bic	r1,r2				@ even though it should be.
	beq	ClearMX				@ Length is zero so exit
	mov	r2,#0
ClrLoop:
	stmia	r0!, {r2}
	sub	r1,#4
	bne	ClrLoop
ClearMX:
	bx	lr


@ r1 = Source Address
@ r2 = Dest Address
@ r3 = Length
.align
.type CopyMem %function
CopyMem:
	mov	r0, #3				@ These commands are used in cases where
	add	r3, r0				@ the length is not a multiple	of 4,
	bic	r3, r0				@ even	though it should be.
	beq	CIDExit				@ Length is zero so exit

CIDLoop:
	ldmia	r1!, {r0}
	stmia	r2!, {r0}
	sub	r3, #4
	bne	CIDLoop
CIDExit:
	bx	lr

	.align
	.pool
	.end
