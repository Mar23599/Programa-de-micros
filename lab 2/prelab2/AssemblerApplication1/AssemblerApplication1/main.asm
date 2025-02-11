;
; Universidad del Valle de Guatemala
;IE2023: Programación de MIcrocontroladores
; Sumador.asm

; Created: 11/02/25
; Author : Alejandro Martínez
; Proyecto: pre lab #2 sumador con timer
; Despreción: Diseñe e implemente un contador binario de 4 bits.cada incremento se realiza cada 100ms, utilizando timer0.  
;

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

; INICIO DEL PROGRAMA // 

.def incrementos = R18
.def COUNTER = R17

setup: 
LDI R16, (1 << CLKPCE) // Cambio de prescaler habilitado
STS CLKPR, R16 
LDI R16, 0b00000100 
STS CLKPR, R16 

// 
CALL INIT_TMR0

// Configurar Puerto D como salida
LDI R16, 0x00
OUT DDRD, R16 // pines de Puerto C colocados como salida

LDI incrementos, 0x00 // iniciar incrementos en 0
OUT PORTD, incrementos
LDI COUNTER, 0x00

loop:
IN R16, TIFR0 // leer registro de interrupción de TMR0
SBRS R16, TOV0 // saltar cuando el bit de overflow no está encendido
RJMP loop // seguir leyendo el registro de TMR0
SBI TIFR0, TOV0 // limpiar bandera de overflow
LDI R16, 178   ; Ajuste para mejor precisión
OUT TCNT0, R16
INC COUNTER
CPI COUNTER, 16  ; Ahora compara con 16 para 10ms en lugar de 50

BRNE loop
CALL contar
RJMP loop

contar: 
INC incrementos
ANDI incrementos, 0x0F // máscara para limitar el valor
MOV R20, incrementos
Swap R20
OUT PORTD, R20// mostrar incrementos en PORTC
RET

INIT_TMR0:
LDI R16, (1<<CS01) | (1<<CS00) ; Prescaler del Timer0 a 64
OUT TCCR0B, R16 
LDI R16, 100  ; 
OUT TCNT0, R16
RET