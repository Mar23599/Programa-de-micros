/*
 * Libreria_ADC.h
 *
 * Created: 6/04/2025 16:32:53
 *  Author: Alejandro Mart�nez
 *	Esta librer�a contiene la inicializaci�n r�pdia del ADC.
 *	ADC_init:
 *		-Justificaci�n a la izquierda
 *		-Prescaler de 8 
 *		-Referencia 5v
 
 * ADC_canal:
	- Se utiliza para usar escojer un canal del ADC para realizar lecturas
	- Asi mismo, se usa para leer el valor del adc en el canal selecionado
	- Acepta un numero entre el 0 y el 8. 
 
 
 */ 


#include "Libreria_ADC.h"

void ADC_init(){
	
	//Funci�n para inicializar el ADC.
	ADMUX = 0;
	ADMUX |= (1 << REFS0 ); // Referencia de lectura: 5v.
	ADMUX |= (1 << ADLAR); // Colocar la justificaci�n a la izquierda
	
	ADCSRA = 0;
	ADCSRA |= ((1 << ADPS1) | (1 << ADPS0)); // colocar prescaler de 8
	ADCSRA |= (1 << ADEN); // Habiliar ADC
	//ADCSRA | =(1 << ADIE); // habilitar interrupciones del ADC
	
}

uint8_t ADC_canal (uint8_t canal){
	
	//Funci�n para lectura de ADC en un canal especifico
	
	if (canal >= 9){
		
		canal = 7; // En caso de ingresar un numero fuera del rango, se habilitara el ADC7 por default. 
	} 
	
	ADMUX = (ADMUX & 0b11110000) | (canal & 0x0F); // Seleccionar un canal
	ADCSRA |= (1 << ADSC); // Inicializar conversion
	
	
	while (ADCSRA & (1 << ADSC)); // Salir cuando la lectura termine
	
	
	return ADCH; // La funci�n regresa el valor de ADCH
	
}

