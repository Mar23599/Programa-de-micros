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

; INICIO DEL PROGRAMA // INTENTO 2418392832 de que el lab chambee


.def LED = R17
.def LED2 = R24

// Configurar pines de entrada, PINC
setup:

LDI R16, 0xFF
OUT DDRD, R16
LDI R16, 0x00
OUT DDRC, R16
LDI R16, 0xFF
OUT PORTC, R16 // Declarar PINC como salida y activar pull ups desde P0 hasta P4

// Configurar PUERTOB del 0 al 3 como salida

LDI R16, 0b00001111
OUT DDRB, R16 // configurar puerto B como salida

LDI LED, 0x00
OUT PORTD, LED




//Configurar pines de salida





loop:

// leer pines de entrada

RCALL check_suma1
RCALL check_resta1
RCALL check_suma2
RCALL check_resta2
RCALL check_SumaTotal


RJMP loop


check_suma1:

SBIC PINC, PC0 // Revisar el pb
RET // regresar sino esta precionado
RCALL delay // Si esta precionado perder tiempo
INC LED // Luego de perder tiempo, incrementar LED
ANDI LED, 0x0F // Mascara para mantener los 4 bits mas significativos en 0
RCALL PRINT 

wait1:
SBIS PINC, PC0 // Seguira contando solamente si se suelta el PB
RJMP wait1
RET

check_resta1:

SBIC PINC, PC1 // Revisar el pb
RET // regresar sino esta precionado
RCALL delay // Si esta precionado perder tiempo
DEC LED // Luego de perder tiempo, decrementar LED
ANDI LED, 0x0F // Mascara para mantener los 4 bits mas significativos en 0
// La mascara tambien mantiene el overflow reseteado cada vez que se alcanza
RCALL PRINT 

wait2:
SBIS PINC, PC1 // Seguira contando solamente si se suelta el PB
RJMP wait2
RET

//-------------------------------------------------------------------------------------------------------------------------

check_suma2:

SBIC PINC, PC2 // Revisar el pb
RET // regresar sino esta precionado
RCALL delay // Si esta precionado perder tiempo
INC LED2 // Luego de perder tiempo, incrementar LED
ANDI LED2, 0x0F // Mascara para mantener los 4 bits mas significativos en 0
// La mascara tambien mantiene el overflow reseteado cada vez que se alcanza
RCALL PRINT 


wait3:
SBIS PINC, PC2 // Seguira contando solamente si se suelta el PB
RJMP wait3
RET

check_resta2:

SBIC PINC, PC3 // Revisar el pb
RET // regresar sino esta precionado
RCALL delay // Si esta precionado perder tiempo
DEC LED2 // Luego de perder tiempo, incrementar LED
ANDI LED2, 0x0F // Mascara para mantener los 4 bits mas significativos en 0
// La mascara tambien mantiene el overflow reseteado cada vez que se alcanza
RCALL PRINT 

wait4:
SBIS PINC, PC3 // Seguira contando solamente si se suelta el PB
RJMP wait4
RET
//--------------------------------------------------------------------------------------------------

PRINT:

MOV R25, LED2 // copiar R25, para no perder LED2
SWAP R25 // intercambiar nibbles
OR R25, LED // si ambos registros pasaron por mascaras, un or los coloca en un solo registro
OUT PORTD, R25
RET
//---------------------------------------------------------------------------------------------------------------
//Luego de 183983 intentos salio. aprendi que: Los botones se leen con SBIS. 


// POSTLAB 


check_SumaTotal:

SBIC PINC, PC4 // Revisar el pb
RET // regresar sino esta precionado
RCALL delay
MOV R26, LED // copiar registro de LED para no alterar la cantidad
ADD R26, LED2  // sumar los registros LED y LED2, guardarlos en R26
ANDI R26, 0x0F // mascara para casos donde la suma sea mayor a 15

RCALL PRINT_SUMA

wait5:
SBIS PINC, PC4 // Seguira contando solamente si se suelta el PB
RJMP wait5
RET


PRINT_SUMA: 

OUT PORTB, R26 // mostrar la suma
RET



//---------------------------------------------------------------------------------------------------------------

//Perdida de tiempo

delay:
LDI R20, 0xFF
LDI R21, 0xFF
LDI R22, 0xFF
LDI R23, 0x0F


subdelay:
DEC R20
CPI R20, 0
BRNE subdelay
DEC R21
CPI R20, 0
BRNE subdelay
DEC R22
CPI R22, 0
BRNE subdelay
DEC R23
CPI R23, 0
BRNE subdelay

RET
