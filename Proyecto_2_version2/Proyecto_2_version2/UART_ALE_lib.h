/*
 * UART_ALE_lib.h
 *
 * Created: 4/05/2025 12:16:12
 *  Author: aleja
 */ 


#ifndef UART_ALE_LIB_H_
#define UART_ALE_LIB_H_

#include <avr/io.h> 
#include <avr/interrupt.h>

void UART_init(void); //Función de inicialización

void UART_send_char(char caracter); // Función para enviar un char

char UART_receive_char(void); // FUnción para recibir un char

void UART_send_chain (char* chain); // Función para enviar una cadena


#endif /* UART_ALE_LIB_H_ */