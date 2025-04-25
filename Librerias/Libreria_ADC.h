/*
 * Libreria_ADC.h
 *
 * Created: 6/04/2025 16:32:53
 *  Author: Alejandro Martínez
 *	Esta librería contiene la inicialización del ADC.
 *	Configura:
 *		-Justificación a la izquierda
 *		-Prescaler de 8 
 *		-Referencia 5v
 
 * ADC_canal:
	- Se utiliza para usar escojer un canal del ADC para realizar lecturas
	- Asi mismo, se usa para leer el valor del adc en el canal selecionado
	- Acepta un numero entre el 0 y el 8. 
 
 
 */ 


#ifndef LIBRERIA_ADC_H_
#define LIBRERIA_ADC_H_
#include <avr/io.h>

void ADC_init(); 
uint8_t ADC_canal (uint8_t canal);





#endif /* LIBRERIA_ADC_H_ */