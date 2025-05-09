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
#include <util/delay.h>
#include <avr/interrupt.h>
#include <avr/eeprom.h>



#include "ALE_ADC_lib.h"
#include "ALE_PWM_lib.h"
#include "UART_ALE_lib.h"



uint8_t contador_modo = 0;


//Variables de control_EPROM();

char opcion; // Variable que guarda la opcion del usuario
uint8_t flag_control_EPROM = 0;
uint16_t data_1, data_2;
uint8_t data_3, data_4; // Variables que moveran informacion a EPROM

uint16_t ADDR_data1 = 0x00; //tambien tomará 0x01
uint16_t ADDR_data2 = 0x02;	//Tambien tomará 0x03
uint16_t ADDR_data3 = 0x04;
uint16_t ADDR_data4 = 0x05;

uint16_t w_data_1, w_data_2;
uint8_t w_data_3, w_data_4; // Variables que veran informacion a EPROM


/****************************************/
// Function prototypes

void setup();
void modo(); // Funcion que contiene los modos de funcionamiento del proyecto

void control_manual(); // Funcion que maneja servos por medio de potenciometros
void control_EPROM(); // Funcion que maneja servos por medio de posiciones guardadas en EPROM


void guardar_posiciones(); //Funcion que guarda posiciones físicas de los servos en EPROM
void ver_posiciones(); // Funcion que ve posiciones guardadas en EPROM







/****************************************/
// Main Function

int main(void)
{
	
	setup();
	
	while (1)
	{
		
		
		modo();
		
		
	}
}

/****************************************/
// NON-Interrupt subroutines


void setup(){
	
	cli();
	
	DDRC = 0b00000111; // Declarar Pines de entrada y salida.
	PORTC |= (1 << PORTC3); // Activar pull-up interno en el PB3
	
	// Configuración de interrupciones por cambios en PC3
	
	PCICR |= (1 << PCIE1); // Habilitar Interrupciones en Puerto C
	PCMSK1 |= (1 << PCINT11); // habilitar interrupciones para PC3
	
	
	adc_init(); //inicializar ADC
	PWM_init_Timer0(); // Inicializar PWM con el timer0: 61hz-16ms
	PWM_init_Timer1(312); // Inicializar PWM con el timer1 50hz - 20ms
	UART_init(); // Inicializar UART: Sin paridad, 1 Bit de stop, 8 Bits de mensaje. 
	
	sei();
	
	
}

void modo()
{
	

	
	switch (contador_modo)
		{
		
		case 0:
		PORTC |= (1 << 0);
		PORTC &= ~((1 << 1)|(1 << 2));
		
		control_manual();
		flag_control_EPROM = 0; //Encender menu de control_EPROM
		
		break;
		
		case 1:
		PORTC |= (1 << 1);
		PORTC &= ~((1 << 0)|(1 << 2));
		
		
		control_EPROM();
		
		break;
		
		case 2:
		PORTC |= (1 << 2);
		PORTC &= ~((1 << 0)|(1 << 1));
		
		
		break;
		
		default:
		
		contador_modo = 0;
		}
	
	
}



void control_manual(){
	
	//Funcion que controla los servos desde potenciometros
	
	OCR1B =	PWM_calculate_servo_16bit(	adc_read(7)	); // Funciona por medio del canal 7
	OCR1A =	PWM_calculate_servo_16bit(	adc_read(6)	); // Funciona por medio del canal 6
	
	OCR0A = PWM_calculate_servo_8bit(	adc_read(5)	); // Funciona por medio del canal 5
	OCR0B = PWM_calculate_servo_8bit(	adc_read(4)	); // Funciona por medio del canal 4
	
	
}

void control_EPROM()
{
	
	
	while (flag_control_EPROM == 0)
	
	{
		
	UART_send_chain("\n MODO CONTROL POR EPROM \n");
	UART_send_chain("Selecione opción: \n");
	UART_send_chain(" GUARDAR POSICIONES: 1 \n");
	UART_send_chain(" VER POSICIONES GUARDADAS: 2 \n");
	
	opcion = UART_receive_char();
	
	switch (opcion)
		{
		
		case '1':
		
		
		guardar_posiciones(); // Funcion que guarda posiciones
		UART_send_chain("1: GUARDAR POSICIONES \n");
		
		
		break;
		
		case '2':
		
		ver_posiciones(); // Funcion que muestra posiciones guardadas
		UART_send_chain("2: VER POSICIONES GUARDADAS \n");
		break;
		
		
		default:
		UART_send_chain(" Por default verá la opcion 2 y puede seguir al siguiente modo \n");
		 
		
		}
		
		UART_send_chain("Para volver a ver las opciones, presione tres veces el boton. \n ");
		flag_control_EPROM = 1;	 //Apagar menu
		
	}
	
}

void guardar_posiciones(){
	
	data_1 = OCR1B;
	data_2 = OCR1A;
	data_3 = OCR0A;
	data_4 = OCR0B;
	
	
	 eeprom_write_word((uint16_t*)ADDR_data1, data_1);
	 eeprom_write_word((uint16_t*)ADDR_data2, data_2);
	 eeprom_write_byte((uint8_t*)ADDR_data3, data_3);
	 eeprom_write_byte((uint8_t*)ADDR_data4, data_4);
	
}	

void ver_posiciones(){
	
	w_data_1 = eeprom_read_word(	(const uint16_t*)ADDR_data1	); //Leer datos
	w_data_2 = eeprom_read_word(	(const uint16_t*)ADDR_data2	);
	w_data_3 = eeprom_read_word(	(const uint16_t*)ADDR_data3	);
	w_data_4 = eeprom_read_word(	(const uint16_t*)ADDR_data4	);
	
	OCR1B = w_data_1; // Ejecutar esos datos en los servos
	OCR1A = w_data_2;
	
	OCR0A = w_data_3;
	OCR0B = w_data_4;
	
}

/****************************************/
// Interrupt routines

ISR(PCINT1_vect){
	
	
	
	
	if (	!(PINC & (1 << 3))	)
	{
		contador_modo++; //Cuando se presione el boton, cambiar de modo
	}
	
	
}