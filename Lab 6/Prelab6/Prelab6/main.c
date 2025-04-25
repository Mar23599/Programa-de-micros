

/*
 * NombreProgra.c
 *
 * Created: 
 * Author: 
 * Description: 
 */
/****************************************/
// Encabezado (Libraries)

#include <avr/io.h>
#include <avr/interrupt.h>


/****************************************/
// Function prototypes

void setup();
void UART_init();
void WRITE_char(char caracter);

/****************************************/
// Main Function

int main(void)
{
	
	setup();
	UART_init();
	
	
	while (1)
	{
		
	
		
	}
}

/****************************************/
// NON-Interrupt subroutines

void setup(){
	
	cli();
	
	//Configuracion de Puerto B
	
	DDRB = 0xFF; // Todo el puerto B funciona como salida
	
	
	//Configuración del Puerto C
	DDRC &= ~(1 << 7); // El PC 7 funciona como salida. 
	
	
	sei();
	
	
}

void UART_init(){
	
	DDRD |= (1 << 1); // PD1 es TX que funciona como salida
	DDRD &= ~(1 << 0);// PD0 es RX que funciona como entrada
	
	UCSR0B = (1 << RXEN0) | (1 << TXEN0) | (1 << RXCIE0); // Habilitar TX, RX. habilitar la interrupción RX
	UCSR0C = (1 << UCSZ01) | (1 << UCSZ00); //configuracion:  enviar y recibir 8 bits, 1 stop bit, 
	UBRR0 = 103; // 9600 baundrys
	
}

void WRITE_char(char caracter){
	
	while ( !(UCSR0A & (1 << UDRE0)) ); // Esperar a que TX quede vacio
	UDR0 = caracter; // Enviar caracter
	
}




// RUTINA DE INTERUPCION

ISR(USART_RX_vect){
	
char carac = UDR0;

PORTB = carac & 0b00111111; // Mascara para mostrar en puerto B los bits correspondientes al caracter
WRITE_char(carac);
	
}

