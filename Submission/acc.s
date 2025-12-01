;=================================================================================================================================;
	.data

; motor control state variables
current_speed:		.byte 0x0		; current speed
target_distance:	.word 0x0		; target distance in cm
;=================================================================================================================================;



;=================================================================================================================================;
	.text

	.global acc
	.global acc_init
	.global timer_interrupt_init
	.global Timer2A_Handler			; changed from Timer0A_Handler

	.global pwm_motor_init
	.global motor_set_speed
	.global motor_stop

	.global init_ultrasonic
	.global getDistance

; pointers to data section
ptr_to_current_speed:	.word current_speed
ptr_to_target_distance:	.word target_distance

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
;=================================================================================================================================;



;=================================================================================================================================;
acc_init:
	PUSH {r4-r12, lr}

	; initialize PWM for servo motors
	BL pwm_motor_init

	; initialize ultrasonic sensor (from C library)
	BL init_ultrasonic

	; start with servo motors stopped
	BL motor_stop

	POP {r4-r12, lr}
	MOV pc, lr
;=================================================================================================================================;



;=================================================================================================================================;
acc:
	PUSH {r4-r12, lr}

	BL acc_init									; initialize ACC
	BL timer_interrupt_init						; initialize timer

acc_loop:
	; main loop that timer interrupt handles distance reading and speed adjustment
	B acc_loop

acc_exit:
	BL motor_stop		; stop servo motors before exit
	POP {r4-r12, lr}
	MOV pc, lr
;=================================================================================================================================;


;=================================================================================================================================;
Timer2A_Handler:					; changed from Timer0A_Handler
	PUSH {r4-r12, lr}

	; clear interrupt flag
	MOV r4, #0x2000					; Timer2 base (changed from 0x0000)
	MOVT r4, #0x4003
	LDRB r5, [r4, #0x024]
	ORR r5, r5, #0x01
	STRB r5, [r4, #0x024]

	; PWM MOTOR CONTROl get distance and adjust speed
	BL getDistance			; call ultrasonic sensor (returns distance in r0)
	BL motor_set_speed		; adjust servo motor speed based on distance

	POP {r4-r12, lr}
	BX lr
;=================================================================================================================================;



;========================================================================================;
	.end
;========================================================================================;
