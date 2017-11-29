
/*- Includes ---------------------------------------------------------------*/
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "soc-hw.h"

/*- Definitions ------------------------------------------------------------*/
#ifndef UART_COMMANDS_BUFFER_SIZE
#define UART_COMMANDS_BUFFER_SIZE  100
#endif

#define FINALCHARACTER1 '\r'
#define FINALCHARACTER2 '\n'

/*- Variables --------------------------------------------------------------*/
char UartBuffer[UART_COMMANDS_BUFFER_SIZE];
uint32_t UartBufferPtr = 0;



int main(void){
    
    // Init Commands
    irq_set_mask( 0x00000012 );
    isr_init();
   // keypad_init();
    camera_init();
    tic_init();
    irq_enable();
    uart_init();
    mSleep(100);
    //char b[50];
    while (1){
	camera_init();
    } 
    return 0;
}
