

/*
 * Prelab4
 *
 * Created: 31/03/25
 * Author: Alejandro Mart�nez
 * Description: Realizar un contador binario de 8 bits. Este debe incrementar y decrementar con dos pusbottoms diferentes
 */
/****************************************/
// Encabezado (Libraries)

#include <avr/io.h>
#include <avr/interrupt.h>


/****************************************/
// Function prototypes

 uint8_t PINC_register;
 uint8_t contador8 = 0;
 uint8_t contador8_LOW = 0;
 uint8_t contador8_HIGH = 0;

void setup (); 
void print_contador8();
void print_PUERTO_C ();

/****************************************/
// Main Function

int main(void)
{
	
	
	setup(); 
	while (1)
	{
		PORTD = contador8;
		//PORTB = contador8;
		print_contador8();
	}
}

/****************************************/
// NON-Interrupt subroutines

void setup (){
	
	cli(); // Desahibilitar las insterrupciones globales
	UCSR0B = 0 ; // Apagar RX y TX
	
	//configuraci�n de entradas y salidas
	
	//Registros DDRx
	
	DDRD = 0xFF ;// Puerto D - > Salidas
	DDRB = 0b00001111 ;// Puerto B - > nible 1: salidas
	DDRC = 0b00001111; // Puerto C -> nible 1: salidas ; PC4 y PC5 entradas con PBS
	
	//Registros PORTX
	
	PORTD = 0x00;// Inicializar apagado
	PORTB = 0x00; // Inicializar apagado
	PORTC = 0b00110000; // Inicializar puerto apagado y activar pull up en PC4 y PC5
	
	//Configuraci�n de interrupciones 
	
	//Intrrupciones por cambios en puerto C: PC4 y PC5
	
	PCICR |= (1 << PCIE1); // Habilitar interrupciones en puerto C
	PCMSK1 |= (1<< PCINT12); // habilitar interrupciones en PC4
	PCMSK1 |= (1 << PCINT13); // habilitar interrupciones en PC5
	
	sei(); // habilitar interrupciones globales
	
	
}


void print_contador8(){
	
	// Dividir contador8 en sus dos nibbles
	contador8_LOW = contador8 & 0x0F ; // mascara para conservar nibble 1 
	contador8_HIGH = contador8 & 0xF0 ; // mascara para concervar nibble 2
	contador8_HIGH = (contador8_HIGH) |(contador8_HIGH >> 4); // Mascara para pasar el nibble 2 al primer nible del contador8_HIGH
	
	PORTC = (PORTC & 0b11110000) | (contador8_LOW); // Imprimir nibble 1 en PORTC //AQUI HAY ERROR
	PORTB = (PORTB & 0xF0) | (contador8_HIGH); // Imprimir nibble 2 en PORTB
	
}



// Interrupt routines

ISR(PCINT1_vect){
	
	// Rutina de interrupcion por cambios en puerto C: PC4 y PC5 
	
	PINC_register = PINC;
	
	if ( !(PINC & (1 << PC4) ))  // PINC_register == 0b00010000
	{
		contador8++; // Si se presiono PC4 incrementar
	} else if (!(PINC & (1 << PC5) )) // PINC_register == 0b00100000
	{
		contador8--; // Si re presiono PC5 decrementar
	}
	
	
}


