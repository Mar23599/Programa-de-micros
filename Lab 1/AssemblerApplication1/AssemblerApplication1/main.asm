;
; Universidad del Valle de Guatemala
;IE2023: Programación de MIcrocontroladores
; Sumador.asm

; Created: 3/02/2025 19:18:08
; Author : Alejandro Martínez
; Proyecto: Lab #1 Sumador
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

setup: 

; Configurar Puertos C para PBs

	
	LDI R16, 0x

	



