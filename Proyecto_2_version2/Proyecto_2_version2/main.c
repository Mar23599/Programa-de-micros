
	
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

uint8_t opcion; // Variable que guarda la opcion del usuario
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


 
 void UART_putstring(char* str);




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
	if(flag_control_EPROM) // Solo ejecutar si hay un comando nuevo
	{
		switch(opcion)
		{
			case 1: // Guardar posiciones
			guardar_posiciones();
			break;
			
			case 2: // Leer posiciones
			ver_posiciones();
			break;
			
			default:
			opcion = 0;
			break;
		}
		flag_control_EPROM = 0; // Resetear el flag después de procesar
	}
}

void guardar_posiciones(){
	// Primero leer los valores actuales
	data_1 = OCR1B;
	data_2 = OCR1A;
	data_3 = OCR0A;
	data_4 = OCR0B;
	
	// Escribir con verificación de cambios para evitar escrituras innecesarias
	uint16_t current1 = eeprom_read_word((const uint16_t*)ADDR_data1);
	if(current1 != data_1) {
		eeprom_write_word((uint16_t*)ADDR_data1, data_1);
	}
	
	uint16_t current2 = eeprom_read_word((const uint16_t*)ADDR_data2);
	if(current2 != data_2) {
		eeprom_write_word((uint16_t*)ADDR_data2, data_2);
	}
	
	uint8_t current3 = eeprom_read_byte((const uint8_t*)ADDR_data3);
	if(current3 != data_3) {
		eeprom_write_byte((uint8_t*)ADDR_data3, data_3);
	}
	
	uint8_t current4 = eeprom_read_byte((const uint8_t*)ADDR_data4);
	if(current4 != data_4) {
		eeprom_write_byte((uint8_t*)ADDR_data4, data_4);
	}
}

void ver_posiciones(){
	// Leer correctamente words y bytes
	w_data_1 = eeprom_read_word((const uint16_t*)ADDR_data1);
	w_data_2 = eeprom_read_word((const uint16_t*)ADDR_data2);
	w_data_3 = eeprom_read_byte((const uint8_t*)ADDR_data3); // Cambiado a read_byte
	w_data_4 = eeprom_read_byte((const uint8_t*)ADDR_data4); // Cambiado a read_byte
	
	// Aplicar los valores a los servos
	OCR1B = w_data_1;
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

void UART_putstring(char* str) {
	if (!str) return; // Verificación de puntero nulo
	
	while (*str != '\0') {
		/* Esperar a que el buffer de transmisión esté vacío */
		while (!(UCSR0A & (1 << UDRE0))) {
			// Puedes agregar un timeout aquí si es necesario
		};
		
		/* Poner el dato en el buffer y enviar */
		UDR0 = *str;
		str++;
	}
}


/****************************************/
// Interrupt routines

ISR(PCINT1_vect){
	
	
	
	
	if (	!(PINC & (1 << 3))	)
	{
		contador_modo++; //Cuando se presione el boton, cambiar de modo
	}
	
	
}



ISR(USART_RX_vect) {
	static uint8_t buffer[10]; // Buffer para almacenar los datos recibidos
	static uint8_t index = 0;  // Índice del buffer
	static uint8_t receiving = 0; // Flag para indicar que estamos recibiendo datos
	
	uint8_t received = UDR0; // Leer el byte recibido
	
	if (received == '\n' || received == '\r') {
		// Fin de comando, procesar el buffer
		buffer[index] = '\0'; // Terminar la cadena
		
		if (contador_modo == 1) {
			// Modo 1: Esperando EXACTAMENTE el formato "EP:d" donde d es 0, 1 o 2
			if (index == 4 && // Longitud exacta del comando
			buffer[0] == 'E' &&
			buffer[1] == 'P' &&
			buffer[2] == ':' &&
			buffer[3] >= '0' &&
			buffer[3] <= '2') {
				
				opcion = buffer[3] - '0'; // Convertir ASCII a número (0-2)
				flag_control_EPROM = 1; // Activar flag para procesar en main
				
				// Enviar confirmación
				UART_putstring("EPROM_OK\n");
			}
			// Cualquier otro comando en modo 1 será ignorado
		}
		else if (contador_modo == 2) {
			// Modo 2: Esperando formato "Sn:dato" (MANTENIDO SIN CAMBIOS)
			if (buffer[0] == 'S' && buffer[2] == ':') {
				uint8_t servo_num = buffer[1] - '0'; // Obtener número de servo
				
				if (servo_num >= 1 && servo_num <= 4) {
					uint8_t value = 0;
					uint8_t i = 3;
					
					// Convertir los dígitos ASCII a número
					while (buffer[i] >= '0' && buffer[i] <= '9') {
						value = value * 10 + (buffer[i] - '0');
						i++;
					}
					
					if (value <= 255) { // Asegurar que es un uint8_t válido
						servo_data[servo_num - 1] = value;
						
						// Opcional: enviar confirmación
						char confirm[20];
						sprintf(confirm, "S%d_OK\n", servo_num);
						UART_putstring(confirm);
					}
				}
			}
		}
		
		// Reiniciar para el próximo comando
		index = 0;
		receiving = 0;
	}
	else {
		// Almacenar el byte en el buffer si hay espacio
		if (index < sizeof(buffer) - 1) {
			buffer[index++] = received;
			} else {
			// Buffer lleno, descartar datos
			index = 0;
		}
	}
}