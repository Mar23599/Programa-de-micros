/*
 * UART_ALE_lib.c
 *
 * Created: 4/05/2025 12:16:55
 *  Author: aleja
 */ 

#include "UART_ALE_lib.h"

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


char UART_receive_char (void){
	
	cli();  // Desabilitar interrupciones
	while (!(UCSR0A & (1 << RXC0))); // Esperar a que termine la transmición/recepción
	
	
	sei(); // habilitar interrupciones
	return UDR0; // Devolver el dato recibido :)
}


void UART_send_chain (char* chain){
	
	//Recorrer toda la cadena. Se detiene hasta encontrar el caracter nulo
	
	for (; *chain; chain++) {
		UART_send_char(*chain);
		
	}
}