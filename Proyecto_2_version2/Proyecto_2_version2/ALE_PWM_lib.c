/*
 * ALE_PWM_lib.c
 *
 * Created: 8/05/2025 23:53:20
 *  Author: Alejandro Mártínez
 */ 

#ifndef PWM_H
#define PWM_H

#include "ALE_PWM_lib.h"



// Función para limitar valores dentro de un rango
static uint8_t constrain(uint8_t value, uint8_t min, uint8_t max) {
	if(value < min) return min;
	if(value > max) return max;
	return value;
}

void PWM_init_Timer0() {
	DDRD |= (1 << PD6) | (1 << PD5); // Pines OC0A y OC0B como salida
	TCCR0A = (1 << COM0A1) | (1 << COM0B1) | (1 << WGM01) | (1 << WGM00);
	TCCR0B = (1 << CS02) | (1 << CS00); // Prescaler 1024
}

void PWM_init_Timer1(uint16_t ICR1_v) {
	DDRB |= (1 << PB1) | (1 << PB2);
	
	// Configurar modo Fast PWM con ICR1 como TOP (Modo 14)
	TCCR1A = (1 << COM1A1) | (1 << COM1B1) | (1 << WGM11);
	TCCR1B = (1 << WGM13) | (1 << WGM12) | (1 << CS12) | (1 << CS10);
	
	// Establecer el valor de TOP (define el período PWM)
	ICR1 = ICR1_v;
}

uint8_t PWM_calculate_servo_8bit(uint8_t value) {
	// Asegurar que el valor está en rango 0-255
	value = constrain(value, 0, 255);
	
	// Mapear 0-255 a 8-39 (para pulso de 0.5ms a 2.5ms)
	// Fórmula: output = 8 + (value / 255.0) * (39 - 8)
	return (uint8_t)(8 + (value * 31) / 255);
}

uint16_t PWM_calculate_servo_16bit(uint8_t value) {
	// Asegurar que el valor está en rango 0-255
	value = constrain(value, 0, 255);
	
	// Mapear 0-255 a 2000-10000 (para pulso de 0.5ms a 2.5ms en modo 16-bit)
	// Fórmula: output = 2000 + (value / 255.0) * (10000 - 2000)
	return (uint16_t)(16 + ((value * 15 + 127) / 255)); 
}


#endif // PWM_H