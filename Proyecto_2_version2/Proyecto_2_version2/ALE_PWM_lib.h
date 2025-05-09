/*
 * ALE_PWM_lib.h
 *
 * Created: 8/05/2025 23:53:07
 *  Author: aleja
 */ 


#ifndef ALE_PWM_LIB_H_
#define ALE_PWM_LIB_H_


#include <avr/io.h>

#include <avr/io.h>
#include <stdint.h>

// Prototipos de funciones
void PWM_init_Timer0();
void PWM_init_Timer1(uint16_t ICR1_v);
uint8_t PWM_calculate_servo_8bit(uint8_t value);
uint16_t PWM_calculate_servo_16bit(uint8_t value);


#endif /* ALE_PWM_LIB_H_ */