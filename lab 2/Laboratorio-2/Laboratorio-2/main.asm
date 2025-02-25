;
; Universidad del Valle de Guatemala
; IE2023: Programación de Microcontroladores
; Contador en display + Contador automático en PC0-PC3

.include "M328PDEF.inc"
.CSEG 
.ORG 0x0000

;
;STACK POINTER
;

		LDI R16, LOW(RAMEND)
		OUT SPL, R16
		LDI R17, HIGH(RAMEND)
		OUT SPH, R17

; INICIO DEL PROGRAMA 

// Variables

.def Dcounter = R17    // Contador manejado por PB para el display
.def Dout = R18        // Guarda el número de display que se va a imprimir
.def pb_state = R19    // Guarda el estado de los PB para implementación de antirebote
.def counterOUT = R20  // Contador automático de 4 bits (PC0-PC3)
.def Tcounter = R21    // Contador para medir 1 segundo con Timer0

// Tabla de contenido de dígitos hexadecimales para display de cátodo común.

table7seg:  
    .db 0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07  
    .db 0x7F, 0x6F, 0x77, 0x7C, 0x39, 0x5E, 0x79, 0x71  

// Apagar comunicación serial

LDI R16, 0x0
STS UCSR0B, R16
STS UCSR0C, R16

// SETUP

SETUP:
	
	// Configurar Puerto D como salida (para el display)
	LDI R16, 0xFF
	OUT DDRD, R16

	// Configurar Puerto C como salida (contador automático en PC0-PC3 y LED en PC4)
	LDI R16, 0x1F  // PC0-PC4 como salida
	OUT DDRC, R16

	// Configurar Puerto B como entrada con pull-ups activados (pushbuttons)
	LDI R16, 0x00
	OUT DDRB, R16
	LDI R16, 0xFF
	OUT PORTB, R16

	// Inicializar variables
	LDI R16, 0x00
	MOV Dcounter, R16   // Empezar en la primera posición de la tabla
	MOV counterOUT, R16 // Empezar contador en 0

	OUT PORTC, counterOUT // Inicializar salida en PC0-PC3

	// Configuración del TIMER0 (prescaler de 1024)
	LDI R16, (1<<CS02) | (1<<CS00)
	OUT TCCR0B, R16
	CLR Tcounter // Contador de overflows en 0

// LOOP PRINCIPAL

LOOP:
	
	RCALL DISPLAY_COUNTER // Mostrar número en el display
	RCALL check_pb        // Manejar pulsadores para cambiar el display
	RCALL contador_OUT    // Contador automático en PC0-PC3

	RJMP LOOP // Repetir 

//*****************************************************************
// FUNCIONES

DISPLAY_COUNTER:
	// Direccionar el registro Z hacia la tabla del display
	LDI ZL, LOW(table7seg << 1)
	LDI ZH, HIGH(table7seg << 1)
	ADD ZL, Dcounter			// Apuntar el registro Z en dirección de la tabla, en la posición del contador
	LPM Dout, Z					// Cargar a Dout los dígitos del display
	OUT PORTD, Dout				// Imprimir dígitos hexadecimales en display
	RET

check_pb:

	SBIS PINB, 0
	RJMP incrementar // Si se presiona el PB0 ir a incrementar
	SBIS PINB, 1
	RJMP decrementar // Si se presiona el PB1 ir a decrementar
	
	CLR pb_state // Actualizar el estado actual de los PB al no ser presionados

	RET // Regresar al loop

incrementar:
	
	SBRC pb_state, 0  // Revisar si el PB0 ya fue presionado (antirebote)
	RET // Si ya fue detectado antes, ignorar
	ORI pb_state, 0b00000001 // Marcar PB0 como presionado
	INC Dcounter
	ANDI Dcounter, 0x0F // Mantener la cuenta entre 0 y 15
	RET // Regresar al loop principal

decrementar: 

	SBRC pb_state, 1 // Revisar si el PB1 ya fue presionado (antirebote)
	RET // Ignorar si ya fue detectado antes
	ORI pb_state, 0b00000010 // Marcar PB1 como presionado
	DEC Dcounter
	
	CPI Dcounter, 0xFF
	BRNE set_15
	LDI Dcounter, 0x0F
	ANDI Dcounter, 0x0F
	RET

set_15:
	RET // Regresar al loop

//*****************************************************************
// CONTADOR AUTOMÁTICO (Cada 1 segundo incrementa PC0-PC3)

contador_OUT:

	SBIS TIFR0, TOV0 // Revisar si hubo overflow del Timer0
	RET // Si no hay overflow, regresar al loop

	// Cuando hay overflow:
	LDI R16, (1 << TOV0) // Limpiar bandera de overflow
	OUT TIFR0, R16 

	INC Tcounter // Incrementar contador de overflows
	CPI Tcounter, 61 // Comparar con la cantidad de overflows para 1 segundo
	BRNE RETORNO // Si no han pasado los overflows necesarios, regresar

	// Cuando haya pasado 1s:
	CLR Tcounter // Reiniciar contador de overflows
	INC counterOUT // Incrementar contador de 4 bits
	ANDI counterOUT, 0x0F // Mantener dentro de 4 bits (0-15)
	
	//
	MOV R23, Dcounter // Copiar contador del display
	LDI R16, 1
	ADD R23, R16 // Apuntar correctamente al número hasta el que se necesita contar


	// Comparar el contador automático con el valor del display
	CP counterOUT, R23
	BRNE PRINT // Si no son iguales, imprimir y regresar
	// Si son iguales, encender el LED en PC4

	//Sino son iguales, encender led de igualdad, y resetar el conteo


	// Cuando el contador alcance al  display, reiniciarlo desde 0
	LDI R16, 0x00
	MOV counterOUT, R16
	CPI counterOUT, 0x00 // Forzamos a que la comparación sea igual
	BREQ PRINT

	
PRINT:
	
	OUT PORTC, counterOUT
	RET


RETORNO:
	
	RET