/*
 * UART_ALE_lib.h
 *
 * Created: 4/05/2025 12:16:12
 *  Author: aleja
 */ 


#ifndef UART_ALE_LIB_H_
#define UART_ALE_LIB_H_


#define F_CPU 16000000UL  // 16 MHz
#define BAUD_RATE 9600
#define BAUD_PRESCALLER (((F_CPU / (BAUD_RATE * 16UL))) - 1)

#include <avr/io.h> 
#include <avr/interrupt.h>

void UART_init(void); //Funci�n de inicializaci�n

void UART_send_char(char caracter); // Funci�n para enviar un char

char UART_receive_char(void); // FUnci�n para recibir un char

void UART_send_chain (char* chain); // Funci�n para enviar una cadena

void UART_init_with_interrupts();

void UART_sendString(const char* str);



#endif /* UART_ALE_LIB_H_ */