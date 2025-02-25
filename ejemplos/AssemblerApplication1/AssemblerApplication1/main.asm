
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


		; Configuración inicial

; Configuración inicial

; Configuración inicial
setup:
    LDI R16, 0xFF          ; Configurar PORTC como entrada (por defecto)
    OUT DDRC, R16          ; DDRC = 0x00, entradas en PORTC
	   LDI R16, 0x0F
LOOP:

   OUT PORTC, R1

   RJMP LOOP

