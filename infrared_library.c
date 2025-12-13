#include <stdint.h>
#include <stdbool.h>

// ============================================================================
// Infrared IR obstacle detector
//
// operating Voltage: 3 to 5V DC
// output type: digital (LOW when obstacle detected, HIGH when clear)
// detection distance: 2~30cm (adjustable via potentiometer)
//
// pin configuration:
// vcc: connect to 3.3V
// gnd: connect to ground
// out: digital output (active LOW on obstacle detection)
//
// gpio configuration: port A pin 2 (PA2)
// chapter 10 of data sheet
// ============================================================================

extern void infrared_init(void);
extern bool isObstacleDetected(void);
void gpio_init(void);

// ============================================================================
// gpio port A pin 2 (PA2) for digital input from IR sensor OUT pin
// port A pin 2 is digital input with pull up resistor (IR sensor OUT pin)
//
// 1. enable clock to gpio PORT A (RCGCGPIO) - 0x608 (0x400FE608)
// 2. set pin direction to input (GPIODIR) - 0x400 (0x40004400)
// 3. enable digital function (GPIODEN) - 0x51C (0x4000451C)
// 4. enable pull up resistor (GPIOPUR) - 0x510 (0x40004510)
//
//
// GPIODATA Port A = (APB) 0x40004000
// GPIODIR Port A = 0x40004400
// GPIODEN Port A = 0x4000451C
// GPIOPUR Port A = 0x40004510
// ============================================================================
void infrared_init(void){
    gpio_init();        // create gpio port A pin 2 for IR sensor digital input
}

void gpio_init(void){
    // enable clock to gpio PORT A (RCGCGPIO)
    (*((volatile uint32_t *) (0x400FE608))) |= (1 << 0);    // set bit 0 for port A
    volatile uint32_t delay = (*((volatile uint32_t *) (0x400FE608)));

    // set up pin 2 for input (GPIODIR)
    (*((volatile uint32_t *) (0x40004400))) &= ~(0x04);         // clear bit 2 for input mode

    // digital enable pin 2 (GPIODEN)
    (*((volatile uint32_t *) (0x4000451C))) |= (0x04);          // set bit 2 to enable digital function

    // enable pull up resistor for pin 2 (GPIOPUR)
    // IR sensor ouput is active LOW, so pull up keeps it HIGH when no obstacle
    (*((volatile uint32_t *) (0x40004510))) |= (0x04);          // set bit 2 to enable pull up
}

// ============================================================================
// isObstacleDetected reads the digital state of the IR sensor output pin.
// Returns true if obstacle is detected (sensor OUT is LOW)
// Returns false if path clear (sensor OUT is HIGH)
//
// When obstacle is within range (2-30cm): OUT = LOW (0V)
// When path is clear: OUT = HIGH
//
// Range can be adjusted using potentiometer on module:
// Turn clockwise CW to increase detection distance
// Turn counter clockwise CCW to decrease detection distance
// ============================================================================
bool isObstacleDetected(void){
    // read current state of port A pin 2
    // 0x40004000 + (0x04 << 2) = 0x40004010 for port A pin 2 (bit 2)
    // pinState will be 0x00000004 (bit 2 set) when clear path
    // pinState will be 0x00000000 (bit 2 clear) when obstacle detected
    uint32_t pinState = *((volatile uint32_t*)0x40004010);

    // check if port A pin 2 is LOW (bit 2 = 0  means obstacle detected)
    if ((pinState & 0x04) == 0) {
        return true;    // obstacle detected (sensor OUT is LOW)
    }
    else {
        return false;   // path is clear (sensor OUT is high)
    }
}

// Return raw digital state: 0 = obstacle detected and 1 = clear path
uint8_t readInfraredState(void){
    uint32_t pinState = (*((volatile uint32_t *) (0x40004010)));
    return ((pinState & 0x04) >> 2);
}

// Return distance status as integer for easier comparison
// Return: 0 = obstacle present and 1 = path clear
int getObstacleStatus(void) {
    if (isObstacleDetected()){
        return 0;       // obstacle present
    }
    else {
        return 1;       // path clear
    }
}
