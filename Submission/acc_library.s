
; >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> ;
    .text

	.global timer_interrupt_init
	.global pwm_motor_init
	.global motor_forward
	.global motor_backward
	.global motor_stop
	.global motor_set_speed

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
pwm_motor_init:
	PUSH {r4-r12, lr}

	; set up the system clock divider for PWM
	MOV r4, #0xE000
	MOVT r4, #0x400F
	LDR r5, [r4, #0x010]
	MOV r6, #0x9
	BFI r5, r6, #12, #4
	STR r5, [r4, #0x010]
	NOP
	NOP
	NOP
	NOP
	NOP

	; turn on PWM module 1 clock
	MOV r4, #0xE000
	MOVT r4, #0x400F
	LDRB r5, [r4, #0x640]
	MOV r6, #0x02
	ORR r5, r5, r6
	STRB r5, [r4, #0x640]
	NOP
	NOP
	NOP
	NOP
	NOP

	; enable Port F clock for PWM pins
	MOV r4, #0xE000
	MOVT r4, #0x400F
	LDRB r5, [r4, #0x608]
	MOV r6, #0x20
	ORR r5, r5, r6
	STRB r5, [r4, #0x608]
	NOP
	NOP
	NOP
	NOP
	NOP

	; unlock PF0 which is locked by default for NMI functionality
	MOV r4, #0x5000
	MOVT r4, #0x4002			; load Port F base address
	MOV r5, #0x434B				; load lower half of unlock key
	MOVT r5, #0x4C4F			; load upper half of unlock key (complete: 0x4C4F434B)
	STR r5, [r4, #0x520]		; write unlock key to GPIOLOCK register
	NOP
	NOP
	NOP
	MOV r5, #0x01				; load commit bit for PF0
	STRB r5, [r4, #0x524]		; write to GPIOCR to allow changes to PF0
	NOP
	NOP
	NOP
	NOP
	NOP

	; set Port F pins 0 and 2 as digital outputs
	MOV r4, #0x5000
	MOVT r4, #0x4002
	LDRB r5, [r4, #0x420]
	MOV r6, #0x05
	ORR r5, r5, r6
	STRB r5, [r4, #0x420]
	NOP
	NOP
	NOP
	NOP
	NOP

	; configure pins for PWM alternate function
	MOV r4, #0x5000
	MOVT r4, #0x4002
	LDR r5, [r4, #0x52C]
	MOV r6, #0x55
	BFI r5, r6, #0, #8
	STR r5, [r4, #0x52C]
	NOP
	NOP
	NOP
	NOP
	NOP

	; assign PWM signals to the right pins (M1PWM4 on PF0, M1PWM6 on PF2)
	MOV r4, #0xE000
	MOVT r4, #0x400F
	LDR r5, [r4, #0x060]
	MOV r6, #0x00				; (PF0 for M1PWM4)
	BFI r5, r6, #0, #4
	MOV r6, #0x00				; (PF2 for M1PWM6)
	BFI r5, r6, #8, #4
	STR r5, [r4, #0x060]
	NOP
	NOP
	NOP
	NOP
	NOP

	; disable both PWM generators before config
	MOV r4, #0x9000
	MOVT r4, #0x4002
	MOV r5, #0
	STR r5, [r4, #0x0C0]
	NOP
	NOP
	NOP
	NOP
	NOP
	STR r5, [r4, #0x100]
	NOP
	NOP
	NOP
	NOP
	NOP

	; set PWM generator 2 control mode (for M1PWM4)
	MOV r4, #0x9000
	MOVT r4, #0x4002
	LDR r5, [r4, #0x0E0]
	MOV r6, #0x0C2
	BFI r5, r6, #0, #12
	STR r5, [r4, #0x0E0]
	NOP
	NOP
	NOP
	NOP
	NOP

	; set PWM generator 3 control mode (for M1PWM6)
	MOV r4, #0x9000
	MOVT r4, #0x4002
	LDR r5, [r4, #0x120]
	MOV r6, #0x0C2
	BFI r5, r6, #0, #12
	STR r5, [r4, #0x120]
	NOP
	NOP
	NOP
	NOP
	NOP

	; configure PWM gen 2 output A control (M1PWM4)
	MOV r4, #0x9000
	MOVT r4, #0x4002
	LDR r5, [r4, #0x0E4]
	MOV r6, #0xC02
	BFI r5, r6, #0, #12
	STR r5, [r4, #0x0E4]
	NOP
	NOP
	NOP
	NOP
	NOP

	; configure PWM gen 3 output A control (M1PWM6)
	MOV r4, #0x9000
	MOVT r4, #0x4002
	LDR r5, [r4, #0x124]
	MOV r6, #0xC02
	BFI r5, r6, #0, #12
	STR r5, [r4, #0x124]
	NOP
	NOP
	NOP
	NOP
	NOP

	; set PWM period/frequency for motor (20ms = 10,000 counts)
	MOV r4, #0x9000
	MOVT r4, #0x4002
	MOV r5, #10000
	STRH r5, [r4, #0x0D0]	; PWM2 load (left servo motor)
	NOP
	NOP
	NOP
	NOP
	NOP
	STRH r5, [r4, #0x110]	; PWM3 load (right servo motor)
	NOP
	NOP
	NOP
	NOP
	NOP

	; set initial duty cycle for STOP (1.5ms = 750 counts)
	MOV r4, #0x9000
	MOVT r4, #0x4002
	MOV r5, #750
	STRH r5, [r4, #0x0D8]		; left servo stop
	NOP
	NOP
	NOP
	NOP
	NOP
	STRH r5, [r4, #0x118]		; right servo stop
	NOP
	NOP
	NOP
	NOP
	NOP

	; fire up both PWM generators
	MOV r4, #0x9000
	MOVT r4, #0x4002
	MOV r5, #1
	STRB r5, [r4, #0x0C0]
	NOP
	NOP
	NOP
	NOP
	NOP
	STRB r5, [r4, #0x100]
	NOP
	NOP
	NOP
	NOP
	NOP

	; enable PWM output pins to actually drive the servo motors
	MOV r4, #0x9000
	MOVT r4, #0x4002
	MOV r5, #0x50
	STRB r5, [r4, #0x008]
	NOP
	NOP
	NOP
	NOP
	NOP

	POP {r4-r12, lr}
	MOV pc, lr
; <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< ;



; >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> ;
motor_forward:
	PUSH {r4-r12, lr}

	; moves both servo motors forward at the speed in r0 ;

	; converts speed percentage to PWM counts for forward motion
	; r0 contains speed percentage (0 to 100)
	; PWM registers set to move motors forward at specified speed

	; calculate PWM count (speed * 250 / 100) + 750
	MOV r4, #250
	MUL r5, r0, r4				; r5 = speed * 250
	MOV r4, #100				;
	UDIV r5, r5, r4				; r5 = (speed * 250) / 100
	ADD r5, r5, #750			; r5 = result + 750 base offset

	; write caluclated PWM count to hardware registers
	MOV r4, #0x9000
	MOVT r4, #0x4002			; load PWM module base address
	STRH r5, [r4, #0x0D8]		; write PWM count to left motor register
	NOP
	NOP
	NOP
	NOP
	NOP
	STRH r5, [r4, #0x118]		; write PWM count to right motor register

	; set both servo motors to same forward speed

	POP {r4-r12, lr}
	MOV pc, lr
; <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< ;



; >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> ;
motor_backward:
	PUSH {r4-r12, lr}

	; moves both servo motors backward at the speed in r0 ;

	; convert speed percentage to PWM counts for backward motion
	; r0 contains speed percentage (0 to 100)
	; PWM registers set to move motors backward at specified speed

	; calculate PWM count 750 - (speed * 250 / 100)
	MOV r4, #250
	MUL r5, r0, r4				; r5 = speed * 250
	MOV r4, #100
	UDIV r5, r5, r4				; r5 = (speed * 250) / 100
	MOV r6, #750				; load base offset for reverse
	SUB r5, r6, r5				; r5 = 750 - result for backward direction

	; write caluclated PWM count to hardware registers
	MOV r4, #0x9000
	MOVT r4, #0x4002			; load PWM module base address
	STRH r5, [r4, #0x0D8]		; write PWM count to left motor register
	NOP
	NOP
	NOP
	NOP
	NOP
	STRH r5, [r4, #0x118]		; write PWM count to right motor register

	; set both servo motors to same backward speed

	POP {r4-r12, lr}
	MOV pc, lr
; <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< ;


; >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> ;
motor_stop:
	PUSH {r4-r12, lr}

	; stop both servo motors ;

	; sets PWM to neutral position to stop both motors
	; PWM registers set to 750 (stop value)

	MOV r4, #0x9000
	MOVT r4, #0x4002			; load PWM module base address
	MOV r5, #750				; load stop value (neutral pulse width)
	STRH r5, [r4, #0x0D8]		; write stop value to left motor register
	NOP
	NOP
	NOP
	NOP
	NOP
	STRH r5, [r4, #0x118]		; write stop value to right motor register

	POP {r4-r12, lr}
	MOV pc, lr
; <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< ;


; >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> ;
motor_set_speed:
	PUSH {r4-r12, lr}

	; set speed based on distance input in r0 ;

	; converts distance from sensor to appropriate speed percentage
	; r0 contains dsitance in centimeters from ultra sonic sensor
	; motors running at speed determined by distance thresholds

	; check distance and determine appropriate speed
	CMP r0, #30					; compare distance to 30cm threshold
	BLT speed_stop				; if less than 30cm, stop motors

	CMP r0, #60					; compare distance to 60cm threshold
	BLT speed_slow				; if less than 60cm, run at 30 percent speed

	CMP r0, #100				; compare distance to 100cm threshold
	BLT speed_medium			; if less than 100cm, run at 60 percent speed

	; distance is 100cm or greater, run at full speed
	MOV r0, #100				; load 100 percent speed value
	BL motor_forward			; convert percentage to PWM and write to registers
	B speed_done

speed_slow:
	MOV r0, #30					; load 30 percent speed value
	BL motor_forward			; convert percentage to PWM and write to registers
	B speed_done

speed_medium:
	MOV r0, #60					; load 60 percent speed value
	BL motor_forward			; convert percentage to PWM and write to registers
	B speed_done

speed_stop:
	BL motor_stop				; set PWM to stop value and write to registers

speed_done:

	POP {r4-r12, lr}
	MOV pc, lr
; <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< ;



; >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> ;
timer_interrupt_init:
	PUSH {r4-r12, lr}

	; turn on Timer2 clock (changed from Timer0)
	MOV r4, #0xE000
	MOVT r4, #0x400F
	LDRB r5, [r4, #0x604]
	ORR r5, r5, #0x04				; bit 2 for Timer2 (changed from bit 0)
	STRB r5, [r4, #0x604]

	; disable Timer2A while we configure it
	MOV r4, #0x2000					; Timer2 base (changed from 0x0000)
	MOVT r4, #0x4003
	LDRB r5, [r4, #0x00C]
	AND r5, r5, #0xFE
	STRB r5, [r4, #0x00C]

	; set timer to 32-bit mode
	LDRB r5, [r4]
	AND r5, r5, #0xF8
	STRB r5, [r4]

	; configure for periodic countdown mode
	LDRB r5, [r4, #0x004]
	AND r5, r5, #0xFC
	ORR r5, r5, #0x02
	STRB r5, [r4, #0x004]

	; set the interval - 16,000 clock ticks
	MOV r5, #16000
	STR r5, [r4, #0x028]

	; enable timeout interrupt for Timer2A
	LDRB r5, [r4, #0x018]
	ORR r5, r5, #0x01
	STRB r5, [r4, #0x018]

	; enable Timer2A interrupt in NVIC
	MOV r4, #0xE000
	MOVT r4, #0xE000
	LDR r5, [r4, #0x100]
	MOV r6, #0x0000
	MOVT r6, #0x0080				; bit 23 for Timer2A (changed from bit 19)
	ORR r5, r5, r6
	STR r5, [r4, #0x100]

	; enable Timer2A
	MOV r4, #0x2000					; Timer2 base
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
