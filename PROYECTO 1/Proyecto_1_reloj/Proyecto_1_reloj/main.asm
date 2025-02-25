; 
;Universidad del valle de Guatemala
;Facultad de ingenieria
;Departamento de ingeniria electronica, mecatronica y biomedica
;Programación de microcontroladores
;Seccion: 30

; AUTOR: Alejandro Martinez
;CARNET: 23599

;PROYECTO #1:
;El proyecto consiste en la implementación de reloj que funcione como:
; - Reloj (Horas:Minutos) // formato 24 horas
; - Calendario  (Mes:Días) // los recordar que los meses tienen diferente cantidad de dias
; - Alarma (programable) // Debe contar con alguna clase de señal auditiva 

// Sin mas que agregar, lets gooouuu


.include "M328pdef.inc" 


;**************************************************************************************************
// VARIABLES GLOBALES
;**************************************************************************************************

; R16: Se utilizara para variables temporales

.def tiempo = R17
.def contador = R18



;**************************************************************************************************
// Vectores de RESET
;**************************************************************************************************

.org 0x0000
	RJMP SETUP // Configurar vector de reset

;**************************************************************************************************
// Vectores de interrupcion
;**************************************************************************************************
//.org 0x0018 // Vector de interrupcion por comparacion
	//RJMP ISR_CPMA // Rutina de interrupcion cada 10ms


;**************************************************************************************************
// Configuracion de la pila
;**************************************************************************************************

LDI R16, HIGH(RAMEND)
OUT SPH, R16
LDI R16, LOW(RAMEND)
OUT SPL, R16

;**************************************************************************************************
//Configuración de sistema
;**************************************************************************************************

SETUP:

// Desabilitar interrupciones globales
CLI


// Configuración de la Frecuencia del reloj del sistema:

LDI R16, (1 << CLKPCE)
STS CLKPR, R16			// Habilitar el cambio del prescaler
LDI R16, 0b00000010     // Configuracion: 4MHz 
STS CLKPR, R16

// desabilitar leds de comunicacion

LDI R16, 0x00
STS UCSR0B, R16
STS UCSR0C, R16 

// TIMER0: Configuracion del timer0

LDI R16, (1 << WGM01) 
STS TCCR0A, R16 // Configurar el timer0 con modo CTC
LDI R16, (1 << CS02)
STS TCCR0B, R16 // Configurar prescaler de 256

LDI R16, 156
STS OCR0A, R16 // Configurar el valor de comparación: Calculado para que se compare a los 0.01s (10ms)

LDI R16, (1 << OCIE0A)
STS TIMSK0, R16 // Habilitar interrupciones por comparación


//Puerto D: configuracion como salida. Se utilizara para imprimir en display

LDI R16, 0xFF
OUT DDRD, R16

//Puerto B: Configuración como salida: Se utilizara para control de los display, por medio de transistores

LDI R16, 0xFF
OUT DDRB, R16

// Puerto C: Configuración como entrada: Se utilizara para utilizar pushbotoms

LDI R16, 0x00
OUT DDRC, R16

LDI R16, 0xFF
OUT PORTC, R16 // Activar pull-ups

// Inicialización de variables
CLR contador
CLR tiempo
LDI R16, 0xFF
OUT PORTB, R16
LDI contador, 0xFF

// Habilitar interrupciones globales

SEI

;**************************************************************************************************
//LOOP
;**************************************************************************************************

LOOP:

OUT PORTD, contador

RJMP LOOP

;**************************************************************************************************
//FUNCIONES
;**************************************************************************************************



;**************************************************************************************************
// RUTINAS DE INTERRUPCIONES
;**************************************************************************************************

// Rutina de interrupcion por comparación (sucede cada 10ms)
;ISR_CPMA:

;IN R16, SREG 
;PUSH R16 // Guardar banderas 

;INC tiempo
;CPI tiempo, 10 // Cuando este sea 10, habra pasado 1s
;BRNE ISR_CPMA_OUT
;CLR tiempo
;INC contador
;ANDI contador, 0x0F


;ISR_CPMA_OUT:
;POP R16
;OUT SREG, R16 // recuperar banderas de SREG
;RETI 

