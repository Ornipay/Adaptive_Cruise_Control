#include <stdint.h>
extern void init_motors(void);
extern void changeSpeed(int right, int left);
void init_pwm(void);
void init_gpioF(void);

void init_motors(void) {
    init_gpioF();
    init_pwm();
}

void init_gpioF(void) {
    // Enable Clock for Port F (RCGCGPIO)
    (*((volatile uint32_t *) (0x400FE608))) |= (1 << 5);            // Set bit [5] for Port F
    // Setup Pin1 and Pin2 for Outputs (GPIODIR)
    (*((volatile uint32_t *) (0x40025400))) |= (3 << 1);            // Set bits [1:2] for Pins 1 & 2
    // Digital Enable Pin1 & Pin2 (GPIODEN)
    (*((volatile uint32_t *) (0x4002551C))) |= (3 << 1);            // Set bits [1:2] for Pins 1 & 2
    // Allow Alternate Function for Pin1 & Pin2 (GPIOAFSEL)
    (*((volatile uint32_t *) (0x40025420))) |= (3 << 1);            // Set bits [1:2] for Pins 1 & 2
    // Select PWM as Alternate Function for Pin1 & Pin2 (GPIOPCTL)
    (*((volatile uint32_t *) (0x4002552C))) |= (5 << 4);            // Set bits [4:7] to value of 5
    (*((volatile uint32_t *) (0x4002552C))) |= (5 << 8);            // Set bits [8:11] to value of 5
}

void init_pwm(void) {
    // Enable Clock for PWM Module 1 (RCGCPWM)
    (*((volatile uint32_t *) (0x400FE640))) |= 2;                   // Set bit [1] for PWM Module 1
    // Configure PWM Clock Divisor to /64 (RCC)
    (*((volatile uint32_t *) (0x400FE060))) |= (1 << 20);           // Set bits [20] to use PWM Clock Divisor
    (*((volatile uint32_t *) (0x400FE060))) |= (7 << 17);           // Set bits [17:19] to value of 7 or (/64)
    // Configure PWM Generator Actions for PWM2GENB
    (*((volatile uint32_t *) (0x400290E4))) |= 3;                   // Set bits [0:1] to value of 3 (Drive PWM High when Counter == 0)
    (*((volatile uint32_t *) (0x400290E4))) |= (2 << 10);           // Set bits [10:11] to value of 2 (Drive PWM Low when Counter == Compare)
    // Configure PWM Generator Actions for PWM3GENA
    (*((volatile uint32_t *) (0x40029120))) |= 3;                   // Set bits [0:1] to value of 3
    (*((volatile uint32_t *) (0x40029120))) |= (2 << 6);            // Set bits [6:7] to value of 2 GenA uses different bits
    // Set the Load Value for PWM Generators (PWM*LOAD)
    int loadValue = 5000;                                           // Modify this Load Value for Different Frequencies
    (*((volatile uint32_t *) (0x400290D0))) = loadValue;            // Give the Load values to both
    (*((volatile uint32_t *) (0x40029110))) = loadValue;            // PWM2GEN and PWM3GEN
    // Set the Compare Values for PWM Generators (PWM*CMP*)
    // int compareValue = 4676;                                     // The compare (4620) generates a PWM Duty Cycle of about 1.52ms
    (*((volatile uint32_t *) (0x400290DC))) = 4680;                 // Give the Load values to both
    (*((volatile uint32_t *) (0x40029118))) = 4560;                 // PWM2GENB and PWM3GENA
    // Connect PWM to Output Pins (PWMENABLE)
    (*((volatile uint32_t *) (0x40029008))) |= (0x60);              // Set bits [5:6] to connect Pin1 & Pin2 to PWM2GENB and PWM3GENA
    // Enable PWM on Control Block (PWM*CTL)
    (*((volatile uint32_t *) (0x400290C0))) |= 1;                   // Set bit [0] to Enable PWM2GEN
    (*((volatile uint32_t *) (0x40029100))) |= 1;                   // Set bit [0] to Enable PWM3GEN
}

void changeSpeed(int right, int left) {
    // Disable PWM on Control Block (PWM*CTL)
    (*((volatile uint32_t *) (0x400290C0))) &= ~(1);                // Clear bit [0] to Disable PWM2GEN
    (*((volatile uint32_t *) (0x40029100))) &= ~(1);                // Clear bit [0] to Disable PWM3GEN

    // Handle Compare Values for PWM
    (*((volatile uint32_t *) (0x400290DC))) = right;
    (*((volatile uint32_t *) (0x40029118))) = left;

    // If the value is zero, then just set to Stop Mode
    if (left == 0 || right == 0) {
        (*((volatile uint32_t *) (0x400290DC))) = 4620;             // The compare (4620) generates a PWM Duty Cycle of about 1.52ms
        (*((volatile uint32_t *) (0x40029118))) = 4620;
    }

    // Enable PWM on Control Block (PWM*CTL)
    (*((volatile uint32_t *) (0x400290C0))) |= 1;                   // Set bit [0] to Enable PWM2GEN
    (*((volatile uint32_t *) (0x40029100))) |= 1;                   // Set bit [0] to Enable PWM3GEN
}