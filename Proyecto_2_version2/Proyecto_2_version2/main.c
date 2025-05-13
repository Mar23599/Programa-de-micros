
	
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
#include <string.h>





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


// Variables de manejo de comunicacion python - Atmega

volatile uint8_t servo_data[4] = {0}; //Lista de datos con valores de servos
volatile uint8_t eprom_data_ready = 0; // Badera para datos de EPROM

/****************************************/
// Function prototypes

void setup();
void modo(); // Funcion que contiene los modos de funcionamiento del proyecto

void control_manual(); // Funcion que maneja servos por medio de potenciometros
void control_EPROM(); // Funcion que maneja servos por medio de posiciones guardadas en EPROM
void control_cloud(); // Funcion que maneja servos por medio de ADAfruit


void guardar_posiciones(); //Funcion que guarda posiciones físicas de los servos en EPROM
void ver_posiciones(); // Funcion que ve posiciones guardadas en EPROM


 




/****************************************/
// Main Function

int main(void) {
	setup();
	
	while(1) {
		
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
	
	// Inicializacion del UART
	
	 UART_init_with_interrupts();
	
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
		
		
		break;
		
		case 1:
		PORTC |= (1 << 1);
		PORTC &= ~((1 << 0)|(1 << 2));
		
		
		control_EPROM();
		
		break;
		
		case 2:
		PORTC |= (1 << 2);
		PORTC &= ~((1 << 0)|(1 << 1));
		
		
		control_cloud();
		
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
	
	
	
	
	switch (opcion)
		{
		
		case '1':
		
		
		guardar_posiciones(); // Funcion que guarda posiciones
		
		
		break;
		
		case '2':
		
		ver_posiciones(); // Funcion que muestra posiciones guardadas
		
		break;
		
		
		//default:
		 
		
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


void control_cloud(){
	
	OCR1B = PWM_calculate_servo_16bit(	servo_data[0]	);// Ejecutar datos desde la nube
	OCR1A = PWM_calculate_servo_16bit(	servo_data[1]	);
	
	OCR0A = PWM_calculate_servo_8bit(	servo_data[2]	);
	OCR0B = PWM_calculate_servo_8bit(	servo_data[3]	);
	
	
}


/****************************************/
// Interrupt routines

ISR(PCINT1_vect){
	
	
	
	
	if (	!(PINC & (1 << 3))	)
	{
		contador_modo++; //Cuando se presione el boton, cambiar de modo
	}
	
	
}

ISR(USART_RX_vect){
	
	
	
	static char rx_msg[8]; // Buffer para mensaje
	static uint8_t msg_pos = 0;
	static uint8_t expecting_value = 0;
	static uint8_t target_servo = 0;
	
	char c = UDR0; // Leer dato recibido

	// Protección contra desbordamiento
	if(msg_pos >= sizeof(rx_msg)-1) {
		msg_pos = 0;
		expecting_value = 0;
		return;
	}
	
	if (contador_modo == 1) { // Modo EPROM
		if (msg_pos < 3) {
			rx_msg[msg_pos++] = c;
			rx_msg[msg_pos] = '\0';
			
			// Verificar si es "EP:"
			if (msg_pos == 3 && strncmp(rx_msg, "EP:", 3) == 0) {
				expecting_value = 1;
				} else if (msg_pos == 3) {
				msg_pos = 0; // Reset si no coincide
			}
		}
		else if (expecting_value) {
			opcion = c; // Guarda el caracter directamente
			eprom_data_ready = 1;
			msg_pos = 0;
			expecting_value = 0;
		}
	}
	else if (contador_modo == 2) { // Modo Servos
		if (msg_pos < 3) {
			rx_msg[msg_pos++] = c;
			rx_msg[msg_pos] = '\0';
			
			// Verificar si es "S1:", "S2:", etc.
			if (msg_pos == 3 && rx_msg[0] == 'S' &&
			(rx_msg[1] >= '1' && rx_msg[1] <= '4') &&
			rx_msg[2] == ':') {
				target_servo = rx_msg[1] - '1'; // Convertir a índice 0-3
				expecting_value = 1;
				} else if (msg_pos == 3) {
				msg_pos = 0; // Reset si no coincide
			}
		}
		else if (expecting_value) {
			servo_data[target_servo] = (uint8_t)c;
			msg_pos = 0;
			expecting_value = 0;
		}
	}
	
	
}

