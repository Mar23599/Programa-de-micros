/*
 * Lab 5.c
 *
 * Created: 8/04/2025 14:10:08
 * Author : aleja
 */ 

#include <avr/io.h>
#include "Libreria_ADC.h"
#include "PWM_init.h"

int main(void)
{
   
   
   ADC_init();
   TMR1_init_PWM(1024, 3000);
   
    while (1) 
    {
    }
}

