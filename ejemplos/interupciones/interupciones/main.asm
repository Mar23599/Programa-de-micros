
// TIMER0  interrumpe cada 10 ms (Modo normal) -> 50 veces = 500ms


.include "M328PDEF.inc"
.CSEG 

.ORG 0x0000 // EN ESTA DIRRECCION VOY A ESCRIBIR ALGO

	JMP START

.org OVF0addr  // consigurar overflow del timer 0
	JMP TMR0_ISR
	

;
;STACK POINTER
;

START:

		LDI R16, LOW(RAMEND)
		OUT SPL, R16
		LDI R17, HIGH(RAMEND)
		OUT SPH, R17

; INICIO DEL PROGRAMA //interrupciones


SETUP:

CLI // Desabilitar las interrupciones globales	

// Configurar prescaler

LDI R16, (1<<ClKPCE)
STS CLKPR, R16 // Habilitar el cambio de prescaler
LDI R16, 0b00000100 
STS CLKPR, R16 // configurar prescaler a 16

//Inicializar timer0

LDI R16, (1<<CS01) | (1<<CS00)
OUT TCCR0B, R16
LDI R16, 100
OUT TCNT0, R16 

// HABILITAR INTERRUPCIONES DEL TIPO OVERFLOW

LDI R16, (1<<TOIE0)
STS TIMSK0, R16

// configurar pb como salida incialmente  apagada. 

SBI DDRD, PB5
SBI DDRB, PB0
CBI PORTB, PB5
CBI PORTB, PB0 

LDI R20, 0

MAIN_LOOP:

	CPI R20, 50
	BRNE MAIN_LOOP
	CLR R20
	SBI PINB, PB5 // TOOGLE PB5
	SBI PINB, PB0 // TOOGLW DE PB0
	RJMP MAIN_LOOP



TMR0_ISR:

LDI R16, 100
OUT TCNT0, R16
INC R20
RETI


