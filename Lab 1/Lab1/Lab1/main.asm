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



// Configurar salida en DDRD 
LDI R16, 0x00
OUT DDRD

//Configurar como entrada y salida, DDRC [0,0,X,X,X,X,PB,PB]

LDI R16, 0b00000011
OUT DDRC

// colocar pull-ups en PORTC

LDI R16, 0x0000011

// Programa principal

setup:

LDI R16, 0xFF
OUT PORD, R16

LDI R17, 0b00111100
OUR PORC, R17