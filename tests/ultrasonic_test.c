extern void init_ultrasonic(void);
extern void getDistance(void);

// ********************************************* Main Test Functionality *********************************************
//
//  This test function works best if you use the debugger & set a breakpoint after getDistance()
//  so you can look at the value of the ultrasonic sensor.
//
// *******************************************************************************************************************
int main(void)
{
    // Initialize Ultrasonic Sensor using Library
    init_ultrasonic();
    // Keep Program Looping
    while (1) {
        // Call function to keep getting distance values
        getDistance();
        // Create a delay between each function call
        int i = 0;
        for (i = 0; i < 4784127; i++) {
            ;;;
        }
    }
}