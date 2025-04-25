

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
void WRITE_chain (char* cadena);

/****************************************/
// Main Function

int main(void)
{
	
	setup();
	UART_init();
	
	WRITE_chain("Hola mundo\r\n"); // Enviar Hola mundo
	
	WRITE_chain("Hola Héctor :) \r\n"); 
	
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


void WRITE_chain (char* cadena){
	
		while (*cadena){          // Mientras no sea el carácter nulo '\0'
			WRITE_char(*cadena);  // Enviar cada caracter
			cadena++;			//El puntero cambia de caracter de la cadena hasta recorrerla completamentet
		
}
}



// RUTINA DE INTERUPCION

	//ISR(USART_RX_vect){
	//	
	//char carac = UDR0;
	//
	//PORTB = carac & 0b00111111; // Mascara para mostrar en puerto B los bits correspondientes al caracter
	//WRITE_char(carac);
	//	
	//}


