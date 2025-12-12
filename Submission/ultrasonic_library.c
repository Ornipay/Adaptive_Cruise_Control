#include <stdint.h>
#include <stdbool.h>
extern void init_ultrasonic(void);
extern int getDistance(void);
extern void Timer0A_Handler(void);
extern void Timer1A_Handler(void);
void init_gpioB(void);
void init_timer0A(void);
void init_timer1A(void);
void sendTrig(void);

// Initialize Memory Space for Timer Handler to pass values
bool rising = 1;
bool finishTimer = 0;
uint32_t risingTime = 0;
uint32_t fallingTime = 0;
uint32_t distance = 0;

// **************************************** Initialization Functionality *********************************************
//
//  Initializes necessary GPIO and Timers for ultrasonic sensor to work.
//  Uses GPIO PortB Pins 6+7 & Uses Timer 0A+1A
//
//  PortB Pin 6 - Input with Alternate Function of Timer (Echo Purposes)
//  PortB Pin 7 - Output (Trig Purposes)
//  Timer 0A - Edge Capture Mode with Timer Counting Up
//  Timer 1A - One-shot Mode with Timer Counting Down
//
// *******************************************************************************************************************
void init_ultrasonic(void) {
    init_gpioB();       // Create GPIOB Pin6 for Echo Inputs & Pin7 for Trig Outputs
    init_timer0A();     // Create Timer0A for reading between Rising Edge & Falling Edge of Echo Input
    init_timer1A();     // Create Timer1A for 10 microsecond HIGH for Trig Output
}
void init_gpioB(void) {
    // Enable Clock for Port B (RCGCGPIO)
    (*((volatile uint32_t *) (0x400FE608))) |= 2;               // Set bit [1] for Port B
    // Setup Pin6 for Inputs (GPIODIR)
    (*((volatile uint32_t *) (0x40005400))) &= ~(0x40);         // Clear bit [6]
    // Setup Pin7 for Outputs (GPIODIR)
    (*((volatile uint32_t *) (0x40005400))) |= (0x80);          // Set bit [7]
    // Digital Enable Pin6 & Pin7 (GPIODEN)
    (*((volatile uint32_t *) (0x4000551C))) |= (0xC0);          // Set bit [6:7]
    // Allow Alternate Function for Pin6 (GPIOAFSEL)
    (*((volatile uint32_t *) (0x40005420))) |= (0x40);          // Set bit [6]
    // Select Timer as Alternate Function for Pin6 (GPIOPCTL)
    (*((volatile uint32_t *) (0x4000552C))) |= (7 << 24);       // Set bits [24:27] to value of 7
}
void init_timer0A(void) {
    // Enable Clock for Timer0 (RCGCTIMER)
    (*((volatile uint32_t *) (0x400FE604))) |= 1;               // Set bit [0] for Timer0
    // Disable Timer0A for Configuration (GPTMCTL)
    (*((volatile uint32_t *) (0x4003000C))) &= ~1;              // Clear bit [0] for Disable
    // Set Timer to be 16-bit Configuration (GPTMCFG)
    (*((volatile uint32_t *) (0x40030000))) = 4;                // Set bits [0:2] to value of 0x04
    // Configure Timer to be Edge-Time Capture Mode that Counts Up (GPTMTAMR)
    (*((volatile uint32_t *) (0x40030004))) |= (1 << 2);        // Set bits [2] for Edge-Time Mode
    (*((volatile uint32_t *) (0x40030004))) |= (0x03);          // Set bits [0:1] for Capture Mode
    (*((volatile uint32_t *) (0x40030004))) |= (1 << 4);        // Set bits [4] for Timer Counting Up
    // Configure Event of Timer Capture (GPTMCTL)
    (*((volatile uint32_t *) (0x4003000C))) |= (0x03 << 2);     // Set bits [2:3] for Both Edges
    // Prescaler was not used so not configured
    // Interval Load Value not used so not configured
    // Configure Timer to allow for Interrupts (GPTMIMR)
    (*((volatile uint32_t *) (0x40030018))) |= 4;               // Set bit [2] for CAEIM or Enable Interrupt Mask
    // Configure Processor to allow Timer Interrupts (EN0)
    (*((volatile uint32_t *) (0xE000E100))) |= (1 << 19);       // Set bit [19] for Enable Interrupt 19
    // Enable Timer0A to Start (GPTMCTL)
    (*((volatile uint32_t *) (0x4003000C))) |= 1;               // Set bit [0] for Enable
}
void init_timer1A(void) {
    // Enable Clock for Timer1 (RCGCTIMER)
    (*((volatile uint32_t *) (0x400FE604))) |= 2;               // Set bit [1] for Timer1
    // Disable Timer1A for Configuration (GPTMCFG)
    (*((volatile uint32_t *) (0x4003100C))) &= ~1;              // Clear bit [0] for Disable
    // Set Timer to be a 32-bit Configuration (GPTMCFG)
    (*((volatile uint32_t *) (0x40031000))) &= ~(0x07);         // Clear bits [0:2]
    // Configure Timer to be One-Shot Mode that Counts Down (GPTMTAMR)
    (*((volatile uint32_t *) (0x40031004))) |= 1;               // Set bits [0:1] to value of 1 for One-Shot Mode
    (*((volatile uint32_t *) (0x40031004))) &= ~(0x10);         // Clear bit [4] for Count Down Mode
    // Prescaler was not used so not configured
    // Set Interval Load Value with Calculated Value (GPTMTBILR)
    (*((volatile uint32_t *) (0x40031028))) = 800;              // Set value to 800 for about 10 microseconds
    // Configure Timer to allow for Interrupts (GPTMIMR)
    (*((volatile uint32_t *) (0x40031018))) |= 1;               // Set bit [0] for TATOIM or Enable Interrupt Mask
    // Configure Processor to allow Timer Interrupts (EN0)
    (*((volatile uint32_t *) (0xE000E100))) |= (1 << 21);       // Set bit [21] for Enable Interrupt 21
}

// ***************************************** Main Functionality ******************************************************
//
//  getDistance - Calls the sendTrig function & when both rising and falling edge are
//                done, compute the pulse width to determine the travel time of the
//                sound waves. We can use that to compute the distance in centimeters
//
//  sendTrig - Sets the Trig on the ultrasonic sensor to HIGH (PortB Pin7) and enables
//             Timer1A to start counting down. The timer should wait until 10 microseconds
//             before setting GPIO back to LOW.
//
// *******************************************************************************************************************

int getDistance(void) {
    // Start sending Trig signal for ultrasonic sensor to start up
    sendTrig();
    // Wait until both edges are collected to do computations
    while (1) {
        if (finishTimer) {
            // Calculate the width of the pulse from Echo
            uint32_t pulseWidth = fallingTime - risingTime;
            // Convert pulse width to actual measurements
            // Data Collected and determined [pulseWidth = 895(cm) + 3801]
            // Therefore, solve to calculate the approximatation of centimeters
            // This estimation is +/- 2cm precision (so it is somewhat close)
            int centimeters = (pulseWidth - 3801) / 895;

            // Return the value so it can be used for PWM
            return centimeters;
        }
    }
}

void sendTrig(void) {
    // Set HIGH on Trig
    (*((volatile uint32_t *) (0x400053FC))) |= (0x80);          // Set bit [7]
    // Enable Timer1A to Start (GPTMCTL)
    (*((volatile uint32_t *) (0x4003100C))) |= 1;               // Set bit [0] for Enable
}

// **************************************** Timer Handler Functionality **********************************************
//
//  Timer0A_Handler - Captures the time between the Rising Edge of the Echo
//                    and the Falling Edge of the Echo. This is the time it
//                    takes for the sound wave to travel (we can do math to
//                    compute the distance.
//
//  Timer1A_Handler - Sets the Trig or PortB Pin7 back to LOW, this handler
//                    is paired with the sendTrig() function.
//
// *******************************************************************************************************************
void Timer0A_Handler(void) {
    // Clear the Interrupt (GPTMICR)
    (*((volatile uint32_t *) (0x40030024))) |= 4;              // Set bit [0] to Clear Interrupt Flag
    // Read current Time Value (GPTMTAR)
    int32_t time = (*((volatile uint32_t *) (0x40030048)));
    // Handle Rising Edge vs Falling Edge and write values to memory
    if (rising) { risingTime = time; }
    else { fallingTime = time; finishTimer = !finishTimer; }
    // Boolean helps determine if this edge was rising or falling
    rising = !rising;
}
void Timer1A_Handler(void) {
    // Clear the Interrupt (GPTMICR)
    (*((volatile uint32_t *) (0x40031024))) |= 1;              // Set bit [0] to Clear Interrupt Flag
    // Set LOW on Trig because 10 microseconds was up
    (*((volatile uint32_t *) (0x400053FC))) &= ~(0x80);        // Clear bit [7]
}