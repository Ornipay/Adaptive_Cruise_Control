extern void init_ultrasonic(void);
extern void init_motors(void);
extern int getDistance(void);
extern void changeSpeed(int right, int left);

// ********************************************* Main Functionality *********************************************
//
//
//
//
// *******************************************************************************************************************
int main(void)
{
    // Initialize Ultrasonic Sensor using Library
    init_ultrasonic();
    init_motors();

    // Keep Program Looping
    while (1) {
        // Call function to keep getting distance values
        int cm = getDistance();

        // Add a little bit of delay for Timers to finish
        int i;
        for (i = 0; i < 50000; i++) {
            ;;;
        }

        // Change the speed varying the distance in front of car
        if (cm < 300) {             // Any value above 300 might be bad ultrasonic sensor reading
            if (cm <= 10) {         // Stop around 10cm
               changeSpeed(0, 0);
            } else if (cm <= 20) {
                changeSpeed(4625, 4615);
            } else if (cm <= 30) {
                changeSpeed(4650, 4590);
            } else if (cm <= 40) {
                changeSpeed(4660, 4580);
            } else if (cm <= 50) {
                changeSpeed(4670, 4570);
            } else if (cm >= 50) {
                changeSpeed(4680, 4560);
            }
        }
    }
}
