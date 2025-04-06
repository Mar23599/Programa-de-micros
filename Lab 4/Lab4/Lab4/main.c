

/*
 * Prelab4
 *
 * Created: 31/03/25
 * Author: Alejandro Martínez
 * Description: Realizar un contador binario de 8 bits. Este debe incrementar y decrementar con dos pusbottoms diferentes
 */
/****************************************/
// Encabezado (Libraries)

#include <avr/io.h>
#include <avr/interrupt.h>


/****************************************/
// Function prototypes

 uint8_t PINC_register;
 uint8_t contador8 = 0; // Contador de 8 bits
 uint8_t contador_timer0 = 0;  // Contador de tiempo del timer0
 uint8_t contadorADC = 0; //Contador que guarda lectura del ADC
 uint8_t contador_display = 0; // Variable de control de multiplexacion
uint8_t ADCnibbleLOW= 0;
uint8_t ADCnibbleHIGH = 0; 


 
 uint8_t hex_display[16] = {
	 0x3F, // 0
	 0x06, // 1
	 0x5B, // 2
	 0x4F, // 3
	 0x66, // 4
	 0x6D, // 5
	 0x7D, // 6
	 0x07, // 7
	 0x7F, // 8
	 0x6F, // 9
	 0x77, // A
	 0x7C, // B
	 0x39, // C
	 0x5E, // D
	 0x79, // E
	 0x71  // F
 };

void setup (); // Configuraciones
void ADC_init(); // Configuración del ADC 6. Justificado a la izquierda
void multiplexacion(); // Función que multiplexea el puerto D e imprime en las diferentes salidas
void conversion_ADC (uint8_t lectura, uint8_t *nibbleH, uint8_t *nibbleL); // Conversión de ADCH a valor manipulables
void alarma (); 


/****************************************/
// Main Function

int main(void)
{
	
	
	setup(); 
	
	while (1)
	{
		
		conversion_ADC(contadorADC, &ADCnibbleLOW, &ADCnibbleHIGH ); // Conversión a hexadecimal de cada nibble del contadorADC
		multiplexacion(); // Multiplexación y registros que se muestran en las salidas
		alarma (); // Manejo de la alarma
	
	}
}

/****************************************/
// NON-Interrupt subroutines

void setup (){
	
	cli(); // Desahibilitar las insterrupciones globales
	UCSR0B = 0 ; // Apagar RX y TX
	
	//configuración de entradas y salidas
	
	//Registros DDRx
	
	DDRD = 0xFF ;// Puerto D - > Salidas
	DDRB = 0b00001111 ;// Puerto B - > Primer nibble: salidas. PB0, PB1, PB2: Control de multiplexación. PB3: Alarma :)
	DDRC = 0b00000000; // Puerto C ->  PC4 y PC5 entradas con PBS
	
	//Registros PORTX
	
	PORTD = 0x00;// Inicializar apagado
	PORTB = 0x00; // Inicializar apagado
	PORTC = 0b00110000; // Inicializar puerto apagado y activar pull up en PC4 y PC5
	
	//Configuración de interrupciones 
	
	//Intrrupciones por cambios en puerto C: PC4 y PC5
	
	PCICR |= (1 << PCIE1); // Habilitar interrupciones en puerto C
	PCMSK1 |= (1<< PCINT12); // habilitar interrupciones en PC4
	PCMSK1 |= (1 << PCINT13); // habilitar interrupciones en PC5
	
	
	//Configuración de interrupciones del timer0: Implementación de antirebote. 
	
	//F_CPU = 16MHz
	
	TCCR0A |= (1 << WGM01) ; // Colocar el timper en modo CTCGOat
	TCCR0B |= (1 << CS02) | (1 << CS00); // Colocar prescaler de 1024
	OCR0A = 78; // La cuenta debe llegar a 78 para interrumpir cada 5ms 78
	TIMSK0 |= (1 << OCIE0A); //  habilitar interrupcion por CMA
	 
	 //Configuración de ADC
	 
	 ADC_init(); // Inicialización del ADC
	 
	
	
	
	sei(); // habilitar interrupciones globales
	
	
}



void ADC_init(){
	
	ADMUX = 0; // Limpiar configuraciones previas
	ADMUX |= (1 << REFS0); // Colocar voltaje de referencia como 5V
	ADMUX |= (1 << ADLAR); // Justificar a la izquierda el registro ADC
	ADMUX |= (1 << MUX2) | (1 << MUX1); // Seleccionar el ADC 6
	
	ADCSRA = 0; // Limpiar configuraciones previas
	ADCSRA |= (1 << ADPS1)| (1 << ADPS0); // Colocar prescaler de 8
	ADCSRA |= (1 << ADEN) | (1 << ADIE);// Habilitar ADC, habilitar interrupcioines
	
	ADCSRA |= (1 << ADSC); // Inicializar lectura
	
	
}


void multiplexacion(){
	
	switch (contador_display){
		
		case 0:
		
		PORTB &= ~((1 << PB0) | (1 << PB1) | (1 << PB2)); //Apagar displays
		PORTD = contador8; // Imprimir contador controlado por pushbottoms
		PORTB |= (1 << PB2); // Encender el contador
		
		break;
		
		case 1:
		
		PORTB &= ~((1 << PB0) | (1 << PB1) | (1 << PB2)); //Apagar displays
		PORTD = ADCnibbleHIGH; // Imprimir nibble alto
		PORTB |= (1 << PB1); // Encender el display derecho
		
		break;
		
		case 2:
		
		PORTB &= ~((1 << PB0) | (1 << PB1) | (1 << PB2)); //Apagar displays
		PORTD = ADCnibbleLOW; // Imprimir nibble bajo
		PORTB |= (1 << PB0); // Encender el display izquierdo
		
		break;
		
		default:
		contador_display = 0; // Reiniciar el control en caso de desborde no esperado.
		
	}
	
	
}

void conversion_ADC (uint8_t lectura, uint8_t *nibbleH, uint8_t *nibbleL){
	
	
	*nibbleL = hex_display[(lectura & 0x0F)]; // Convervar nibble bajo
	*nibbleH = hex_display[((lectura >> 4) & 0x0F)]; // Convervar el nibble alto
	

}

void alarma (){
	
	if (contadorADC > contador8){
		
		PORTB |= (1 << PB3); // Si contadorADC es mayor a contador8, encender alarma
	} else {
		
		PORTB &= ~(1 << PB3); // Si contadorADC NO es mayor a contador8, mantener alarma apagada
	}
	
	
}

// Interrupt routines

ISR(PCINT1_vect){
	
	// Rutina de interrupcion por cambios en puerto C: PC4 y PC5 
	

	if ( !(PINC & (1 << PC4) ))  // PINC_register == 0b00010000
	{
		contador8++; // Si se presiono PC4 incrementar
	} else if (!(PINC & (1 << PC5) )) // PINC_register == 0b00100000
	{
		contador8--; // Si re presiono PC5 decrementar
	}
	
}

// Rutina de interrupción por timer0. Ocurre cada 10ms
ISR (TIMER0_COMPA_vect){
	
		ADCSRA |= (1 << ADSC);

	
	contador_display++; // Intercambiar valor de contador_display entre 0 1 y 2
	
	if ( contador_display >= 3)
	{
		contador_display = 0; // Luego de 30ms resetear la cuenta
	}
	
	
}

// Rutina de interrupción por ADC
ISR(ADC_vect){
	
	
	contadorADC = ADCH;
	ADCSRA |= (1 << ADSC); // Volver a leer
	
}