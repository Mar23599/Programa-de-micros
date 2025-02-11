
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
    LDI R16, 0x00          ; Configurar PORTC como entrada (por defecto)
    OUT DDRC, R16          ; DDRC = 0x00, entradas en PORTC

    LDI R16, 0x03          ; Configurar PORTC0 y PORTC1 con Pull-ups activados
    OUT PORTC, R16         ; PORTC = 0x03 (activa pull-ups en PORTC0 y PORTC1)

    LDI R16, 0x0F          ; Configurar PORTD0 a PORTD3 como salida
    OUT DDRD, R16          ; DDRD = 0x0F, salidas en PORTD0 a PORTD3

    LDI R17, 0x00          ; Inicializar contador en 0 (4 bits)
    OUT PORTD, R17         ; Mostrar contador en PORTD

loop:
    IN R18, PINC           ; Leer PINC (estado de botones)
    SBIC R18, 0            ; Saltar si PORTC0 está en 1 (no presionado)
    RJMP incrementar       ; Si PORTC0 es 0, incrementar contador

    SBIC R18, 1           ; Saltar si PORTC1 está en 1 (no presionado)
    RJMP decrementar       ; Si PORTC1 es 0, decrementar contador

    RJMP loop              ; Si no se presionó ningún botón, seguir leyendo

incrementar:
    INC R17                ; Incrementar el contador
    CPI R17, 16            ; Comparar si el contador llegó a 16 (0x10 en decimal)
    BRNE show_increment    ; Si no llegó a 16, ir a mostrar el contador

    LDI R17, 0x00          ; Si el contador llegó a 16, reiniciar a 0
show_increment:
    OUT PORTD, R17         ; Mostrar el contador en PORTD
    RJMP loop              ; Volver al loop principal

decrementar:
    DEC R17                ; Decrementar el contador
    CPI R17, 255           ; Comparar si el contador llegó a -1 (0xFF en decimal)
    BRNE show_decrement    ; Si no llegó a -1, ir a mostrar el contador

    LDI R17, 0x0F          ; Si el contador llegó a -1, reiniciar a 15 (0x0F)
show_decrement:
    OUT PORTD, R17         ; Mostrar el contador en PORTD
    RJMP loop              ; Volver al loop principal

