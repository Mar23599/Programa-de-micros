/*
 * PWM_init.h
 *
 * Created: 8/04/2025 11:29:01
 *  Author: aleja
 */ 


#ifndef PWM_INIT_H_
#define PWM_INIT_H_

#include <avr/io.h>

void TMR1_init_PWM(uint16_t prescaler, uint16_t ICR1_value);
 void TMR0_init_PWM (uint16_t prescaler);




#endif /* PWM_INIT_H_ */