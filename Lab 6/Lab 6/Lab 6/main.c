

/*
 * NombreProgra.c
 *
 * Created: 24/04/2025
 * Author: AM
 * Description: Jugar con el monitor serial.... como en los viejos tiempos :) 
 */
/****************************************/
// Encabezado (Libraries)

#include <avr/io.h>
#include <avr/interrupt.h>
#include <stdio.h>
#include <stdint.h>
#include "Libreria_ADC.h"

volatile char received_char = 0;
volatile uint8_t new_data_flag = 0;
uint8_t value_ADC = 0;
uint8_t menu_flag = 0;
char ascii_char; 
char buffer[16];

/****************************************/
// Function prototypes

void setup();
void init_ADC();
uint8_t read_ADC();

void UART_init(void);

void UART_send_char(char caracter);
char UART_receive_char(void);
void UART_send_chain (char* chain);

void uint8_to_string(uint8_t value, char* buffer);



/****************************************/
// Main Function

int main(void)
{
	
	setup();
	

	
	
	
	while (1)
	{
		
		
		if (menu_flag == 0)
		{
				UART_send_chain("\n");
				UART_send_chain("\n");
				UART_send_chain("MENÚ: Envie el caracter de su respectiva opción\n");
				UART_send_chain("Leer potenciometro: 1\n");
				UART_send_chain("Enviar Ascii: 2\n");
				UART_send_chain("\n");
				
				menu_flag = 1; // cambiar el valor de la bandera para no repetir la pregunta. 
		}
		
		
		
		if (new_data_flag == 1)
		{
			value_ADC = read_ADC();
			UART_send_chain("Lectura del POT: \n");
			UART_send_chain("POT: ");
			
			uint8_to_string( value_ADC, buffer);
			UART_send_chain(buffer); 
			
			UART_send_chain("\n");
			new_data_flag = 0;	//Limpiar bandera de dato recibido
			menu_flag = 0; // Reenviar el menu
			
		} else if (new_data_flag == 2)
		{
			
			UART_send_chain("\nModo ASCII - Envie un caracter: ");
			ascii_char = UART_receive_char();
			
			// Mostrar en Puerto B (LEDs)
			PORTB = (uint8_t)ascii_char;
			
			// Hacer eco con información completa
			UART_send_chain("\nCaracter recibido: '");
			UART_send_char(ascii_char);
			UART_send_chain("' (ASCII: ");
			uint8_to_string((uint8_t)ascii_char, buffer);
			UART_send_chain(buffer);
			UART_send_chain(")\n\n");
			
			new_data_flag = 0;
			menu_flag = 0;
			
			
			
		} else if ( new_data_flag == 3)
		{
			UART_send_chain("ERROR: Enviar un caracter correcto \n");
			new_data_flag = 0; //Limpiar bandera de dato recibido
			menu_flag = 0; // Reenviar el menu
		}
	
	
	
	
	
	}
	
	
	
	
	}

/****************************************/
// NON-Interrupt subroutines


void setup(){
	
	cli();
	
	//Configuración de pines de salida
	
	DDRB = 0xFF; // El puerto B funcionará como salida
	
	//inicialización de UART: Asincrono, 1 bit de stop
	
	UART_init(); 
	init_ADC();
	
	
	sei();
}

void init_ADC(){
	
	ADMUX = (1 << REFS0) | (1 << ADLAR);
	ADCSRA = (1 << ADEN) | (1 << ADPS2) | (1 << ADPS1) | (1 << ADPS0);
	
	
	//Habilitar ADC y configurar prescaler a 128. Justificación a la izquierda
	
}

uint8_t read_ADC(){
	
	ADMUX = (ADMUX & 0xF0) | 0x07;
	ADCSRA |= (1 << ADSC);
	while (ADCSRA & (1 << ADSC));
	
	return ADCH; 
}


void UART_init(void){
	
	//Paso 1: configurar PD0 como entrada y PD1 como salida
	
	DDRD |= (1 << DDD1); // Tx SALIDA
	DDRD &= ~(1 << DDD0); // RX ENTRADA
	
	
	//Paso 2: configurar UCSR0A
	
	UCSR0A = 0;
	
	//Paso 3: Configurar UCSR0B: Interrupciones de RX
	
	UCSR0B = (1 << RXEN0) | (1 << TXEN0) | (1 << RXCIE0);
	
	// paso 4 configurar UCSR0C:  Configurar modo asincrono; desahbilitar polaridad
	
	UCSR0C = (1 << UCSZ01) | (1 << UCSZ00);
	
	// Paso 5 Habilitar interrupciones
	
	
	
	
	UBRR0  = 103; // 103 --> implica 9600 baundrys si el reloj funciona a 16Mhz.

}

void UART_send_char(char caracter){
	
	//Función que envia un caracter a la computadora
	
	while (!(UCSR0A & (1 << UDRE0))); //Esperar hasta que la transmición termine
	
	UDR0 = caracter ; // Cargar el caracter a enviar. 
	
}

void uint8_to_string(uint8_t value, char* buffer){
	
	sprintf(buffer, "%u", value);
	
}


void UART_send_chain (char* chain){
	
	//Recorrer toda la cadena. Se detiene hasta encontrar el caracter nulo
	
	  for (; *chain; chain++) {
		  UART_send_char(*chain);
		  
	  }
			  
		  
	
}


char UART_receive_char (void){
	
	cli();  // Desabilitar interrupciones
	while (!(UCSR0A & (1 << RXC0))); // Esperar a que termine la transmición/recepción
	
	
	sei(); // habilitar interrupciones
	return UDR0; // Devolver el dato recibido :)
}




/****************************************/

// Interrupt subroutines


// Rutina de interrupción para la recepción de UART


ISR(USART_RX_vect){
	
	
	received_char = UDR0;
	
		
		if (received_char == '1')
		{
			new_data_flag = 1;
			//UART_send_chain("R 1\n");
			
		} else if (received_char == '2')
		{
			
			new_data_flag = 2;
			//UART_send_chain("R2\n");
		} else {
			
			new_data_flag = 3;
			//UART_send_chain("ERROR\n");
			
			
		}
		
		
		

	
	
	
	
}
