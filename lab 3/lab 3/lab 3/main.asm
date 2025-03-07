;***********************************************************  
; Universidad del Valle de Guatemala  
; IE2023: Programación de Microcontroladores  
;lab: 3: Contador binario con botones y LEDs 
;Alejandro Martínez 23599

; 
;***********************************************************  

.include "M328pdef.inc"    ; Incluye definiciones específicas del ATmega328PB

; Vector de interrupción

.org 0x0000   
               // Colocar origen en la dirección 0x0000
.org  OVF0addr // vector de interrupcion del timer0 por overflow
	RJMP ISR_TMR0

// Variables -- registros

.def counter = R17 // llevara la cuenta del contador con leds
.def pb_state = R18 // Mantendrá el estado de los botones
.def OVFcounter = R19 // Contador de overflows del timer 0
// A partar R20 para implementar laboratorio
.def Dcounter = R21
.def MScounter =R22


//cargar tabla con valores del display
table7seg:  
    .db 0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F, 0x6F



// setup

setup: 

//Stak pointer
LDI R16, HIGH(RAMEND)
OUT SPH, R16
LDI R16, LOW(RAMEND)
OUT SPL, R16

//dESABILITAR LAS INSTURRPCION GLOBALES
CLI


// Apagar comunicación serial

LDI R16, 0x00
STS UCSR0B, R16
STS UCSR0C, R16

// Configuración de pines


// PORTD como salidas en todo el puerto, se usara para el display

LDI R16, 0xFF
OUT DDRD, R16 

// PUERTO C controla los transistores para activar o desactivar un display

LDI R16, 0x02
OUT DDRC, R16


//Configuración del timer0
LDI R16, 0x00
OUT TCCR0A, R16// colocar el timer en modo normal
LDI R20, 0x05 
OUT TCCR0B, R16 // colocar prescaler de 1024
LDI R20, 0x01 
STS TIMSk0, R16 // habilitar interrupción por ovweflow

CLR OVFcounter // limpiar contador de overflows

//pruebas




SEI // Habilitar interrupciones globales

// Loop principal

loop:

	 
	
	// Mostrar en el display, cargando desde la tabla por medio de dirrecionamiento indirecto
	
	LDI ZH, HIGH(table7seg*2)
	LDI ZL, LOW(table7seg*2)
	ADD ZL, Dcounter
	LPM R16, Z
	OUT PORTD, R16
	LDI R16, 0x01
	OUT PORTC, R16

	RJMP loop






//Rutina de interrupciones

//RUTINA DE INTERUPCIONES POR PB0 Y PB1


// RUTINA DE INTERRUPCIONES POR TIMER0
ISR_TMR0:

	PUSH R20
	IN R20, SREG
	PUSH R20 // Guardar temporalmente el valor del PC

	INC OVFcounter // Contar hasta 50, es aproximadamente 1s
	CPI OVFcounter, 50
	BRNE TMR0_OUT

	CLR OVFcounter
	INC Dcounter

	CPI Dcounter, 10
	BRNE TMR0_OUT
	CLR Dcounter

TMR0_OUT:

POP R20 // Regresar el PC counter a su cuenta normal
OUT SREG, R20
POP R20
RETI 



