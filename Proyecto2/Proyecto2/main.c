/*
 * proyecto2.c
 *
 * Created: 29/04/25
 * Author: Alejandro Martinez
 * Description: Construcción y programación de un rostro animatrónico
 
 
 MODOs:
 0: Modo  Control manual
 1: Modo EPROM: Guardar posiciones o Ejecutar posiciones guardadas
 2: Modo Control UART
 
 
 */
/****************************************/
// Encabezado (Libraries)

#include <avr/io.h>
#include <avr/interrupt.h>
#include <avr/eeprom.h>
#include <stdio.h>
#include <util/delay.h>

// Librerias locales
#include "UART_ALE_lib.h" //Libreria de funcion de UART
#include "PWM_init.h" //Libreria de funciones de PWM
#include "Libreria_ADC.h" // Liberia de funcion de ADC

volatile uint8_t contador_modo = 0; // Contador de modo

// Variables de modo 2

uint8_t menu2_FLAG = 0;
char menu_opcion; 

#define EPROM_ADDR1  0x00
#define EPROM_ADDR2  0x02
#define EPROM_ADDR3  0x03
#define EPROM_ADDR4  0x04 // Dirrecciones a utilizar en EPROM 

uint8_t flag_menu_EPROM = 0; //Bandera para encender menu
char option_menu_EPROM; //Guarda la opcion seleccionada





/****************************************/
// Function prototypes

void setup();
void display_menu(); // Funcion de mostrar modo
void modo_munual(); // Funcion que ejecuta el modo manual
void EPROM_mode(); //Funcion que debe guardar o mostrar datos guardados en EPROM


/****************************************/
// Main Function

int main(void)
{
	
	setup();
	/* Replace with your application code */
	while (1)
	{
		
		display_menu(); 
		
		
		
	}
}

/****************************************/
// NON-Interrupt subroutines


void setup(){
	
	cli();
	
	/*
	PINES DE ENTRADA:
	PC7, PC6, PC5, PC4: Potenciometros ; PC3: PushBottom
	PINES DE SALIDA:
	PC2, PC1 y PC0: LEDS de estado
	*/ 
	
	DDRC = 0b00000111; // Declarar Pines de entrada y salida. 
	PORTC |= (1 << PORTC3); // Activar pull-up interno en el PB3
	
	// Configuración de interrupciones por cambios en PC3
	
	PCICR |= (1 << PCIE1); // Habilitar Interrupciones en Puerto C
	PCMSK1 |= (1 << PCINT11); // habilitar interrupciones para PC3
	
	//Inicialización de UART
	
	UART_init(); //Inicializar UART
	
	//Inicialización de ADC
	
	ADC_init(); // Inicializar ADC
	
	//Inicialización de PWM0
	
	
	TMR0_init_PWM(1024); // Inicializar PWM0 con prescalador de 1024. Frecuencia = 61Hz; Periodo: 0.0164s = 16.4ms
	
	// registros para manejo: OCR0A y OCR0B
	
	//Inicialización de PWM1
	
	TMR1_init_PWM(1024, 312 ); // Inicializar PWM1 con prescalador de 1024. Frecuencia = 50HZ; Periodo = 20ms
	
	//Registros para manejo: OCR1A y OCR1B
	
	
	sei();
	
}


void display_menu(){
	
	switch (contador_modo){
		
		case 0:
		
		PORTC |= (1 << PORTC0); // Encender PC0
		PORTC &= ~( (1 << PORTC1)|( 1 << PORTC2) );	//Apagar PC1 y PC2
		
		modo_munual(); // Mover servomotores con potenciometros	

		break;
		
		case 1:
		
		PORTC |= (1 << PORTC1); // Encender PC1
		PORTC &= ~( (1 << PORTC0)|( 1 << PORTC2) );	//Apagar PC0 y PC2
		
		EPROM_mode(); //Guardar posiciones en EPROM o ejecutarla
		
		break;
		
		case 2:
		
		PORTC |= (1 << PORTC2); // Encender PC2
		PORTC &= ~( (1 << PORTC0)|( 1 << PORTC1) );	//Apagar PC0 y PC1
		
		//Control desde adafruit
		
		break;
		
		default:
		
		 contador_modo = 0;  // Resetear el contador
		
		
	}
	
}


void modo_munual(){
	
	
	// Control de los servomotores por de forma manual
	OCR1B = 14+ (ADC_canal(7) * 25)/255; //Debe variar entre 11 y 36;
	OCR1A = 14+ (ADC_canal(6) * 25)/255; //Debe variar entre 11 y 36;
	
	OCR0A = 11 + (ADC_canal(5) * 25)/255; // Debe variar entre 16 - 24 - 32
	OCR0B = 11 + (ADC_canal(4) * 25)/255; // Debe variar entre 16 - 24 - 32
	
	
}

void EPROM_mode(){
	
	
		while(flag_menu_EPROM == 0){
			
			//Desplegar menu
			UART_send_chain(" \n -----MODO EPROM----- \n");
			UART_send_chain("Seleccione una opción: \n");
			UART_send_chain("GUARDAR POSICIONES: 1\n");
			UART_send_chain("VER POSICIONES GUARDADAS: 2\n");
			
			flag_menu_EPROM = 1; //Apagar menu
		}
		
		menu_opcion = UART_receive_char();
		
		switch (menu_opcion){
			
			case '1':
			UART_send_chain("OPCION 1 \n");
			break;
			
			case '2':
			UART_send_chain("OPCION 2 \n");
			break;
			
			default:
			UART_send_chain("Envie opcion valida\n");
			
		}
	
	
}





/****************************************/
// Interrupt routines


//Rutina de interrupcion del PB3

ISR(PCINT1_vect){
	
	if ( !(PINC & (1 << PINC3)))
	{
		contador_modo++; // Cada que se precione el boton, incrementar el contador de modo.
	
	//while (! (PIND & (1 << PINC3))); // Esperar a que se suelte el boton
	
	}
	
}







