;
; Universidad del Valle de Guatemala
;IE2023: Programación de MIcrocontroladores
; Sumador.asm

; Created: 3/02/2025 19:18:08
; Author : Alejandro Martínez
; Proyecto: pre lab #1 Sumador
; Despreción: Diseñe e implemente un contador binario de 4 bits. Utilice 2 pushbuttons para aumentar
; y decrementar el contador 
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

; INICIO DEL PROGRAMA



.def LED1 = R31 // Variable para GUARDAR el valor actual de la SALIDA 
.def EST1 = R30// Variable para GUARDAR valores de ENTRADA en pb1 y pb2
.def EST11 = R29 // Variable para LEER valores de ENTRADA

setup:

// configurar Puerto C como salida y configurar puerto B como entrada

	LDI	R16, 0XFF
	OUT DDRC, R16 // Configurar puerto C como SALIDAS

	LDI R16, 0b00000101
	OUT PORTC, R16
