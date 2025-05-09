



#include "PWM_init.h"



void TMR0_init_PWM (uint16_t prescaler){
	
	//Esta función coloca el PWM en modo FAST y NO invertido automaticamente.
	//Las salidas del PWM del timer0 se encuentran en:
	
	// PD5 -- OC0A y PD6 -- OC0B 
	
	DDRD |= (1 << PD5) | (1 << PD6); //Declarar salidas del PWM del timer1 en PD5 y PD6
	
		//ADVERTENCIA: Recordar que el timer1 y timer0 comparten prescaler
	
	/* 
	
	REFERENCIA PARA USO: El prescaler de 1024 y TCNT0 = 255  genera :
			Frecuencia = 61Hz
			Periodo: 0.0164s = 16.4ms
	*/
	
	TCCR0A = 0;	// Limpiar cualquier configuracion previa
	TCCR0B = 0; // Limpiar cualquier configuración previa
	
	TCCR0A |= (1 << COM0A1); // Colocar el modo FAST NO invertido
	TCCR0A |= (1 << COM0B1);
	TCCR0A |= (1 << WGM01) | (1 << WGM00); // Colocar Fast PWM
	TCCR0B &= ~(1 << WGM02) ;
	
	switch (prescaler){
		
		case 1:
		TCCR0B |= (1 << CS00); //No prescaler
		break;
		
		case 8:
		TCCR0B |= (1 << CS01); // Prescaler de 8
		break;
		
		case 64:
		TCCR0B |= (1 << CS01)|(1 << CS00); // Prescaler de 64
		break;
		
		case 256:
		TCCR0B |= (1 << CS02); // Prescaler de 256
		break;
		
		case 1024:
		TCCR0B |= (1 << CS02)|(1 << CS00); // Prescaler de 1024
		break;
		
		default:
		TCCR0B |= (1 << CS02)|(1 << CS00); // El prescaler en caso defaul sera 1024
		
		
	}
	
	//El ciclo de trabajo se configura con los registros OCR0A y OCR0B;
	
	
	/* Valores de referencia:
	
	TCNT0 = 255
	prescaler = 1024
	Periodo: 16.4ms 
	
	*/

	
}




void TMR1_init_PWM(uint16_t prescaler, uint16_t ICR1_value){
	
	//ADVERTENCIA: Recordar que el timer1 y timer0 comparten prescaler
	
	
		//Esta función coloca el PWM en modo FAST y NO invertido automaticamente.
		//Las salidas del PWM del timer1 se encuentran en:
		// PB1 -- OC1A y PB2 -- OC1B
		
	 DDRB |= (1 << PB1) | (1 << PB2);  // Pines 9 y 10 como salidas PWM del timer1
	 
	 TCCR1A = 0;
	 TCCR1B = 0; // Borrar cualquier configuración previa de ambos registros
	 
	 TCCR1A |= (1 << COM1A1) | (1 << COM1B1); // Setear modo NO invertido
	 TCCR1A |= (1 << WGM11);	//Setear modo FAST
	 TCCR1B |= (1 << WGM13) | (1 << WGM12); // Setear top en ICR1
	 
	 switch (prescaler){
		 
		 case 1:
		 TCCR1B |= (1 << CS10); // Prescaler  = 1
		 break;
		 
		 case 8:
		 TCCR1B |= ( 1 << CS11); //Prescaler = 8
		 break;
		 
		 case 64:
		 TCCR1B |= (1 << CS11) | (1 << CS10); //Prescaler de 64
		 break;
		 
		 case 256:
		 TCCR1B |= (1 << CS12);
		 break;
		 
		 case 1024:
		 TCCR1B |= ( 1 << CS12) | (1 << CS10); // Prescaler de 1024
		 break;
		 
		 default:
		 TCCR1B |= ( 1 << CS12) | (1 << CS10); // Prescaler de 1024 por default
		 
	 }
	   
	 ICR1 = ICR1_value; // Configura el TOP de la función  
	   
	//El ciclo de trabajo se configura con  OCR1A y OCR1B
	
		/* Valores de referencia:
	
	prescaler = 1024
	ICR1 = 312 
	Periodo: 20ms 
	
	*/
	
}
