#include <stdbool.h>

extern void infrared_init(void);
extern bool isObstacleDetected(void);

// To test, use the debugger & set a breakpoint after isObstacleDetected() so you can look at the value of the infrared sensor

int main(void){
    // initialize infrared sensor using library
    infrared_init();
    //keep program looping
    while(1){
        // call function to keep getting obstacle detection status
        isObstacleDetected();
        //create a delay between each function call
        int i = 0;
        for (i=0; i<4784127; i++){
            ;;;
        }
    }
}
