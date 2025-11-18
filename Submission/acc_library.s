
; >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> ;
    .text

	.global timer_interrupt_init

U0FR: 	.equ 0x18
DIR:	.equ 0x400
DEN:	.equ 0x51C
DATA:	.equ 0x3FC
EN0: 	.equ 0x100
CLK: 	.equ 0x608

RCGCTIMER:	.equ 0x604
RCGCGPIO:   .equ 0x608
RCGCSSI:    .equ 0x61C

GPTMCTL: 	.equ 0x00C
GPTMIMR:	.equ 0x018
GPTMICR:	.equ 0x024
GPTMTAMR:	.equ 0x004
GPTMTAILR:	.equ 0x028

GPIODIR:    .equ 0x400
GPIODEN:    .equ 0x51C
GPIOAFSEL:  .equ 0x420
GPIOPCTL:   .equ 0x52C
GPIODATA:   .equ 0x3FC
; <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< ;


; >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> ;
timer_interrupt_init:
	PUSH {r4-r12, lr}

	; turn on Timer0 clock
	MOV r4, #0xE000
	MOVT r4, #0x400F													; clock control base address
	LDRB r5, [r4, #0x604]												; read RCGCTIMER
	ORR r5, r5, #0x01													; set bit 0 (Timer0)
	STRB r5, [r4, #0x604]												; write back

	; disable Timer0A while we configure it
	MOV r4, #0x0000
	MOVT r4, #0x4003													; Timer0 base address
	LDRB r5, [r4, #0x00C]												; read GPTMCTL
	AND r5, r5, #0xFE													; clear bit 0 (TAEN)
	STRB r5, [r4, #0x00C]												; write back

	; set timer to 32-bit mode
	LDRB r5, [r4]														; read GPTMCFG
	AND r5, r5, #0xF8													; clear bits 0-2
	STRB r5, [r4]														; write back

	; configure for periodic countdown mode
	LDRB r5, [r4, #0x004]												; read GPTMTAMR
	AND r5, r5, #0xFC													; clear bits 0 and 1
	ORR r5, r5, #0x02													; set to periodic mode
	STRB r5, [r4, #0x004]												; write back

	; set the interval/reload value for strobing - 16,000 clock ticks
	MOV r5, #16000														; timer interval value - FIXED!
	STR r5, [r4, #0x028]												; write to GPTMTAILR

	; enable timeout interrupt for Timer0A
	LDRB r5, [r4, #0x018]												; read GPTMIMR
	ORR r5, r5, #0x01													; set TATOIM bit (bit 0)
	STRB r5, [r4, #0x018]												; write back

	; enable Timer0A interrupt in the processor
	MOV r4, #0xE000
	MOVT r4, #0xE000													; NVIC base address
	LDR r5, [r4, #0x100]												; read EN0
	MOV r6, #0x0000
	MOVT r6, #0x0008													; set bit 19 (Timer0A)
	ORR r5, r5, r6														; enable Timer0A interrupt
	STR r5, [r4, #0x100]												; write back

	; enable Timer0A
	MOV r4, #0x0000
	MOVT r4, #0x4003
	LDRB r5, [r4, #0x00C]
	ORR r5, r5, #0x01
	STRB r5, [r4, #0x00C]

	POP {r4-r12, lr}
	MOV pc, lr
; <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< ;



; >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> ;
	.end
; <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< ;
