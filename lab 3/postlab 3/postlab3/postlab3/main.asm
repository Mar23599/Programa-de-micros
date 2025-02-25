;***********************************************************  
; Universidad del Valle de Guatemala  
; IE2023: Programación de Microcontroladores  
;lab: 3: Contador binario con botones y LEDs 
;Alejandro Martínez 23599

; 
;***********************************************************  

.include "M328pdef.inc"    ; Incluye definiciones específicas del ATmega328PB

; Vector de interrupción

.org 0x0000                  // Colocar origen en la dirección 0x0000
    rjmp setup              // cuando haya un reset, ir a setup
.org  OVF0addr // vector de interrupcion del timer0 por overflow
 RJMP ISR_TMR0

// Variables -- registros

.def OVF2counter = R17
.def D2counter = R18
.def OVFcounter = R19 // Contador de overflows del timer 0
// A partar R16 para implementar laboratorio
.def Dcounter = R21
.def Dswitch = R22 // Registro que activa y desactiva Displays
.def Dout = R23



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

// PORTC como salidas del contador manejado por pubs

LDI R16, 0xFF
OUT DDRC, R16 


//Configuración del timer0
LDI R20, 0x00
OUT TCCR0A, R20 // colocar el timer en modo normal
LDI R20, 0x05 
OUT TCCR0B, R20 // colocar prescaler de 1024
LDI R20, 0x01 
STS TIMSk0, R20 // habilitar interrupción por ovweflow

//Inicializar registros

CLR OVFcounter // limpiar contador de overflows
CLR Dcounter // Limpiar contador que dirrecciona z para el display
CLR D2counter


LDI R16, 0b00100001  // 0010-0001
MOV Dswitch, R16 // Registro que guarda el estado del display activado


SEI // Habilitar interrupciones globales

// Loop principal

loop:

	
	
	// Mostrar en el display, cargando desde la tabla por medio de dirrecionamiento indirecto
	
	SBRS Dswitch, 1 // Si el D2 esta activado, saltar a ver Dcounter
	RJMP D2counter_out
// Sino esta activado, mostrar Dcounter

	LDI ZH, HIGH(table7seg << 1)
	LDI ZL, LOW(table7seg << 1)
	ADD ZL, Dcounter
	LPM R16, Z
	OUT PORTD, R16
	OUT PORTC, Dswitch

	RJMP loop

D2counter_out:
	LDI ZH, HIGH(table7seg << 1)
	LDI ZL, LOW(table7seg << 1)
	ADD ZL, D2counter
	LPM R16, Z
	OUT PORTD, R16
	OUT PORTC, Dswitch

	RJMP loop





//Rutina de interrupciones


// RUTINA DE INTERRUPCIONES POR TIMER0
ISR_TMR0:

	PUSH R16
	IN R16, SREG
	PUSH R16 // Guardar temporalmente el valor del PC

	INC OVFcounter // Contar hasta 50, es aproximadamente 1s
	INC OVF2counter // Contar hasa 5, aproximadamente 10ms

	CPI OVFcounter, 100 // Sino llega al segundo, revisar otra posible interrupción
	BRNE toggle_display // 

	CLR OVFcounter // Cunado la cuenta llegue a 100, limpiar contador de overflows
	INC Dcounter //Incrementar Dcounter

	CPI Dcounter, 10 // limpiar el contador cuando este llegue a 10
	BRNE TMR0_OUT

	CLR Dcounter // Limpiar el contador 1, cada vez que llegue a 10 segundos
	INC D2counter // Incrementar el contador 2, cada vez que llegue a 10 segundos (Cuanta las decenas)
	CPI D2counter, 6
	BRNE TMR0_OUT // Sino se alcanzaron los 60segundos, salir

	CLR D2counter // Si se alcanzan, salir de la interrupcion y limpiar el D2counter


TMR0_OUT:

POP R16 // Regresar el R16 y SREG a su estado antes de la INTERRUPCION
OUT SREG, R16
POP R16
RETI 

toggle_display:
	SWAP Dswitch // Alternar cada 10ms la activación de los displays
	INC OVF2counter
	CPI OVF2counter, 100 
	BRNE TMR0_OUT // Sino han pasado 10ms salir de la interrupción
	CLR OVF2counter
	
	JMP TMR0_OUT // Salir de la interrupción
	


