#include <stdint.h>
extern void init_motors(void);
void init_pwm(void);
void init_gpioF(void);

void init_motors(void) {
    init_gpioF();
    init_pwm();
}

void init_gpioF(void) {
    // Enable Clock for Port F (RCGCGPIO)
    (*((volatile uint32_t *) (0x400FE608))) |= (1 << 5);         // Set bit [5] for Port F
    // Setup Pin1 and Pin2 for Outputs (GPIODIR)
    (*((volatile uint32_t *) (0x40025400))) |= (3 << 1);         // Set bits [1:2] for Pins 1,2,3
    // Digital Enable Pin1 & Pin2 (GPIODEN)
    (*((volatile uint32_t *) (0x4002551C))) |= (3 << 1);         // Set bits [1:2] for Pins 1,2,3
    // Allow Alternate Function for Pin1 & Pin 7 (GPIOAFSEL)
    (*((volatile uint32_t *) (0x40025420))) |= (3 << 1);         // Set bits [1:2] for Pins 1,2,3
    // Select Timer as Alternate Function for Pin6 (GPIOPCTL)
    (*((volatile uint32_t *) (0x4002552C))) |= (5 << 4);        // Set bits [4:7] to value of 5
    (*((volatile uint32_t *) (0x4002552C))) |= (5 << 8);        // Set bits [8:11] to value of 5
}

void init_pwm(void) {
    // Enable Clock for PWM Module 1
    (*((volatile uint32_t *) (0x400FE640))) |= 2;               // Set bit [1] for Module 1
    // Configure PWM Clock Divisor to /64
    (*((volatile uint32_t *) (0x400FE060))) |= (1 << 20);       // Set bits [20] to use PWM Clock Divisor
    (*((volatile uint32_t *) (0x400FE060))) |= (7 << 17);       // Set bits [17:19] to value of 7 or (/64)
    // Configure PWM Generator Actions for PWM2GENB
    (*((volatile uint32_t *) (0x400290E4))) |= 3;               // Set bits [8:11] to value of 5
    (*((volatile uint32_t *) (0x400290E4))) |= (2 << 6);        // Set bits [8:11] to value of 5
    // Configure PWM Generator Actions for PWM3GENA
    (*((volatile uint32_t *) (0x40029120))) |= 3;               // Set bits [8:11] to value of 5
    (*((volatile uint32_t *) (0x40029120))) |= (2 << 6);        // Set bits [8:11] to value of 5
    // Set the Load Value for PWM Generators
    int loadValue = 5000;                                       // Modify this Load Value
    int compareValue = 4620;                                    // This generates a PWM Duty Cycle of about 1.52ms 
    (*((volatile uint32_t *) (0x400290D0))) = loadValue;        // Set bits [8:11] to value of 5
    (*((volatile uint32_t *) (0x40029110))) = loadValue;        // Set bits [8:11] to value of 5
    // Set the Compare Values for PWM Generators
    (*((volatile uint32_t *) (0x400290DC))) = compareValue;     // Set bits [8:11] to value of 5
    (*((volatile uint32_t *) (0x40029118))) = compareValue;     // Set bits [8:11] to value of 5
    // Connect PWM to Output Pins
    (*((volatile uint32_t *) (0x40029008))) |= (0x60);          // Set bits [8:11] to value of 5
    // Enable PWM
    (*((volatile uint32_t *) (0x400290C0))) |= 1;               // Set bits [8:11] to value of 5
    (*((volatile uint32_t *) (0x40029100))) |= 1;               // Set bits [8:11] to value of 5
}