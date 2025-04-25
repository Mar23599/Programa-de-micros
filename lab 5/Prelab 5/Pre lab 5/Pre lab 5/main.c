/*
 * NombreProgra.c
 *
 * Created: 
 * Author: 
 * Description: 
 */
/****************************************/
// Encabezado (Libraries)


#define F_CPU 16000000
#include <avr/io.h>
#include <avr/interrupt.h>
//#include <avr/delay.h>
#include "Libreria_ADC.h"
#include "PWM_init.h"

uint8_t ADC_lecture = 0;
uint8_t servo_OCR0A = 0;
uint8_t ADC_lecture2 = 0;
uint8_t servo_OCR0B = 0;

uint8_t ADC_H = 0; 




/****************************************/
// Function prototypes

void setup();

void ADC_inicializar();
uint8_t ADC_lecture_canal (uint8_t canal);

//void TMR0_init_PWM (uint16_t prescaler);
//void TMR1_init_PWM(uint16_t prescaler, uint16_t ICR1_value);


/****************************************/
// Main Function

int main(void)
{
	
	setup();

	while (1)
	{
		 
	ADC_lecture = ADC_lecture_canal(7);
	OCR0A = 11 + (ADC_lecture * 25)/255; // Debe variar entre 16 - 24 - 32
	 
	ADC_lecture2 = ADC_lecture_canal(6);
	OCR1A = 14+ (ADC_lecture2 * 25)/255; //Debe variar entre 11 y 36
	
	OCR0B = ADC_lecture_canal(5);
	 
	 
	  
	 
}

}

/****************************************/
// NON-Interrupt subroutines


void setup(){
	
	cli();
		
	//Registros DDRn
	
	DDRC = 0x00; // Declarar puerto C como entrada.
	
	//ADC_inicializar();
	
	ADC_inicializar();
	
	TMR0_init_PWM(1024); // Periodo de 16ms
	TMR1_init_PWM(1024, 312); //Periodo de 20ms
	
	//ADC_init(); // Inicializar el ADC. Sin seleccionar el canal
	sei();
}


void ADC_inicializar(){
	
	    ADMUX = (1 << REFS0) | (1 << ADLAR);
	    ADCSRA = (1 << ADEN) | (1 << ADPS2) | (1 << ADPS1);
	
	
}

uint8_t ADC_lecture_canal (uint8_t canal){
	
	ADMUX = (ADMUX & 0xF0) | (canal & 0x07);
	
	ADCSRA |= (1 << ADSC);
	while(ADCSRA & (1 << ADSC));
	
	uint8_t ADC_H = ADCH;
	
	return ADC_H;
}


/****************************************/
// Interrupt routines