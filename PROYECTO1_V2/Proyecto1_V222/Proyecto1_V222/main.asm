; VERSION #2


.include "M328pdef.inc" 

;**************************************************************************************************
// VARIABLES GLOBALES
;**************************************************************************************************

.equ comparacion_1seg = 100 // 100: Numero que cuenta cada  10ms para alcanzar 1 segundos
.equ CTC_TMR0_cuenta = 156 // 156: Numero hasta el que cuenta el timer0, en modo CTC
.equ CTC_TMR2_cuenta = 78 // 78: Numero hasta el que cuenta el timer2, en modo CTC

.def dias_del_mes = R20 // Registro que guarda dias del mes en función del mes


.dseg
.org SRAM_START

contador_modo: .byte 1 // Contador de modo en el que se esta trabajando
; Modo = 0, mostrar hora
; Modo = 1, Mostrar fecha
; Modo = 2, configurar minutos
; Modo = 3, configurar horas
; Modo = 4, configurar Dia
; Modo = 5, configurar Mes
; modo = 6, configurar alarma
; modo = 7, NO SE AUN. :)

control_display: .byte 1 // Control de los transistores del display


// Contadores de tiempo

contador_minutos: .byte 1 // contador de minutos
contador_horas: .byte 1 // Contador de horas
contador_dias: .byte 1 // contador de minutos
contador_mes: .byte 1 // Contador de mes

contador_minutos_ALARMA: .byte 1  // Contadores para ALARMA 
contador_horas_ALARMA: .byte 1 

minutos_u: .byte 1  // Registros que guardan unidades y decenas
minutos_d: .byte 1 
horas_u: .byte 1 
horas_d: .byte 1 
dias_u: .byte 1 
dias_d: .byte 1 
mes_u: .byte 1 
mes_d: .byte 1 

copia_0: .byte 1 // Registros que se van a imprimir
copia_1: .byte 1
copia_2: .byte 1
copia_3: .byte 1 


;**************************************************************************************************
// Vectores de RESET
;**************************************************************************************************

.cseg
.org 0x0000
	JMP SETUP // Configurar vector de reset

;**************************************************************************************************
// Vectores de interrupcion
;**************************************************************************************************
.org PCI1addr
	JMP ISR_PCI1 

.org OC2Aaddr // Vector de interrupcion por comparación del timer2
	JMP ISP_CPMA2 // Rutina de interrupcion cada 5ms

.org OC0Aaddr // Vector de interrupcion por comparacion del timer0
	JMP ISR_CPMA // Rutina de interrupcion cada 10ms



// tablas; Se coloco aqui para evitar el problemas con los vectores de reset e interrupcion
TABLA7SEG:
    .db 0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F, 0x6F // tabla para display de 7 segmentos
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
	OUT TCCR0A, R16 // Configurar el timer0 con modo CTC
	LDI R16, (1 << CS02)
	OUT TCCR0B, R16 // Configurar prescaler de 256 al timer0
	
	LDI R16, CTC_TMR0_cuenta // 156
	OUT OCR0A, R16 // Configurar el valor de comparación: Calculado para que se compare a los 0.01s (10ms)
	
	LDI R16, (1 << OCIE0A)
	STS TIMSK0, R16 // Habilitar interrupciones por comparación

	//TIMER2: 

	LDI R16, (1 << WGM21)
	STS TCCR2A, R16 // Configurar el timer2 en modo CTC
	LDI R16, (1 << CS21) | (1 <<CS22)
	STS TCCR2B, R16 // COnfigurar prescaler de 256 al timer2

	LDI R16, CTC_TMR2_cuenta
	STS OCR2A, R16 // Configurar el valor de comparación: Calculado para que compare a los 0.005s (5ms)

	LDI R16, (1 << OCIE2A)
	STS TIMSK2, R16 // Habilitar interrupciones por comparación 

	
	
	//Puerto D: configuracion como salida. Se utilizara para imprimir en display
	
	LDI R16, 0xFF
	OUT DDRD, R16
	
	//Puerto B: Configuración como salida: Se utilizara para control de los display, por medio de transistores
	
	LDI R16, 0b00001111
	OUT DDRB, R16
	
	// Puerto C: Configuración como entrada y salidas: Se utilizara para utilizar pushbotoms y contador de modo (0,0,S2,S1,S0,PB2,PB1,PB0)
	
	LDI R16, 0b00111000
	OUT DDRC, R16
	
	LDI R16, 0b00000111
	OUT PORTC, R16 // Activar pull-ups en pines de entrada
	
	// Configuracion de interrupciones en PUERTOC , bit 0, 
	
	
	LDI R16, (1 << PC0)  | (1 << PC1) | (1 << PC2) 
	STS PCMSK1, R16 // Habilitar las interrupciones en PC0, PC1 y PC2
	
	LDI R16, (1 << PCIE1)
	STS PCICR, R16 // habilitar interrupciones en Puerto C
	
	// Inicializar variables



	// Inicializar variables en RAM con valor inicial cero.

	CLR R16
	STS control_display, R16
	STS contador_modo, R16
	
	STS contador_minutos, R16
	STS contador_horas, R16

	STS contador_minutos_ALARMA, R16
	STS contador_horas_ALARMA, R16
	
	// Inicializar variables en 1
	LDI R16, 1
	STS contador_dias, R16
	STS contador_mes, R16

	//Inicializaciones especiales
	LDI dias_del_mes, 31


	//Pruebas



	SEI // habilitar interrupciones globales
	
;**************************************************************************************************
//LOOP
;**************************************************************************************************

LOOP:
	CALL CONVERSION_UD_MINUTOS // Transformacion de contador_minutos a minutos_u y minutos_d
	CALL CONVERSION_UD_HORAS  // Transformacion de contador_horas a horas_u y horas_d
	CALL CONVERSION_UD_DIAS		// Transformacion de contador_dias a dias_u y dias_d
	CALL CONVERSION_UD_MES // Transformacion de contador_mes a mes_u y mes_d

// CALL PRINT_copia
	CALL PRINT_contador_modo // Funcion que imprime contador_modo
	CALL PRINT_display // Función que maneja el display
	
	RJMP LOOP

// RUTINAS SIN INTERUPCION
;-----------------------------------------------------------------------------------------------
PRINT_display: 

	LDS R16, control_display

		CPI R16, 0
	BREQ JMP_DISPLAY_0 // 3 - X - X - x 
		
		CPI R16, 1
	BREQ JMP_DISPLAY_1 //  X - 2 - X - x 
		
		CPI R16, 2
	BREQ JMP_DISPLAY_2 // X - X - 1 - x
		
		CPI R16, 3
	BREQ JMP_DISPLAY_3 // X - X - X - 0 
	
	RET

JMP_DISPLAY_0:
	JMP DISPLAY_0
JMP_DISPLAY_1:
	JMP DISPLAY_1
JMP_DISPLAY_2:
	JMP DISPLAY_2
JMP_DISPLAY_3:
	JMP DISPLAY_3
	 

DISPLAY_0:
	LDS R16, minutos_u // Imprimir copia3
	LDI ZL, LOW(TABLA7SEG << 1)
	LDI ZH, HIGH(TABLA7SEG << 1)
	ADD Zl, R16
	LPM R16, Z
	OUT PORTD, R16

	SBI PORTB, 3	//Encender DISPLAY 3
	JMP PRINT_display_EXIT

DISPLAY_1: 

	LDS R16, minutos_d // Imprimir copia2
	LDI ZL, LOW(TABLA7SEG << 1)
	LDI ZH, HIGH(TABLA7SEG << 1)
	ADD Zl, R16
	LPM R16, Z
	OUT PORTD, R16

	SBI PORTB, 2	//Encender DISPLAY 2
	JMP PRINT_display_EXIT

DISPLAY_2: 

	LDS R16, horas_u // Imprimir copia1
	LDI ZL, LOW(TABLA7SEG << 1)
	LDI ZH, HIGH(TABLA7SEG << 1)
	ADD Zl, R16
	LPM R16, Z
	OUT PORTD, R16

	SBI PORTB, 1	//Encender DISPLAY 1
	JMP PRINT_display_EXIT

DISPLAY_3: 


	LDS R16, horas_d // Imprimir copia0
	LDI ZL, LOW(TABLA7SEG << 1)
	LDI ZH, HIGH(TABLA7SEG << 1)
	ADD Zl, R16
	LPM R16, Z
	OUT PORTD, R16

	SBI PORTB, 0	//Encender DISPLAY 0
	JMP PRINT_display_EXIT

PRINT_display_EXIT:
	
	CBI PORTB, 0 // Apagar DISPLAY
	CBI PORTB, 1
	CBI PORTB, 2
	CBI PORTB, 3
	RET
;-----------------------------------------------------------------------------------------------





PRINT_copia_EXIT:
	RET
;-----------------------------------------------------------------------------------------------
// Rutina que imprime el contador_modo

PRINT_contador_modo: 

	LDS R16, contador_modo // R16 = contador_modo
	CBI PORTC, PC3
	CBI PORTC, PC4
	CBI PORTC, PC5 // Limpiar registros de salida para evitar señales basura

	// Practicamente, copiar los primeros 3 bits de contador_modo
	SBRC R16, 0 // Si CONTADOR_MODO[0] = 1, colocar 1, sino sigue en0
	SBI PORTC, PC3

	SBRC R16, 1 // Si CONTADOR_MODO[1] = 1, colocar 1, sino sigue en 0
	SBI PORTC, PC4

	SBRC R16, 2 // Si CONTADOR_MODO[2] = 1, colocar 1, sino sigue en 0
	SBI PORTC, PC5

	RET
;-----------------------------------------------------------------------------------------------
// FUNCIONES DE CONVERSIONES DE UNIDADES :) 
CONVERSION_UD_MINUTOS:

	   LDS R16, contador_minutos   ; Cargar el valor del contador de minutos en R16
    
    LDI R17, 10                 ; Cargar 10 en R17 para división
    MOV R18, R16                ; Copia R16 en R18 para no modificarlo
    
    ; Calcular decenas (R16 = contador_minutos / 10)
    CLR R19                     ; Limpiar R19 para la división
    MOV R20, R17                ; Copiar divisor (10) a R20
DIV_LOOP:
    CP R18, R20                 ; Comparar R18 con 10
    BRLO DIV_DONE               ; Si R18 < 10, salir del bucle
    SUB R18, R20                ; Restar 10 de R18
    INC R19                     ; Incrementar contador de decenas
    RJMP DIV_LOOP               ; Repetir hasta que R18 < 10
DIV_DONE:

    STS minutos_d, R19          ; Guardar decenas en memoria

    ; Calcular unidades (R16 = contador_minutos % 10)
    STS minutos_u, R18          ; Guardar unidades en memoria



	RJMP CONVERSION_UD_MINUTOS_EXIT
CONVERSION_UD_MINUTOS_EXIT:
	RET
;-----------------------------------------------------------
//Funcion de conversion para horas
CONVERSION_UD_HORAS:

	  LDS R16, contador_horas  ; Cargar el valor del contador de minutos en R16
    
    LDI R17, 10                 ; Cargar 10 en R17 para división
    MOV R18, R16                ; Copia R16 en R18 para no modificarlo
    
    ; Calcular decenas (R16 = contador_minutos / 10)
    CLR R19                     ; Limpiar R19 para la división
    MOV R20, R17                ; Copiar divisor (10) a R20
DIV_LOOP_horas:
    CP R18, R20                 ; Comparar R18 con 10
    BRLO DIV_DONE_horas               ; Si R18 < 10, salir del bucle
    SUB R18, R20                ; Restar 10 de R18
    INC R19                     ; Incrementar contador de decenas
    RJMP DIV_LOOP_horas               ; Repetir hasta que R18 < 10
DIV_DONE_horas:

    STS horas_d, R19          ; Guardar decenas en memoria
    ; Calcular unidades (R16 = contador_horas % 10)
    STS horas_u, R18          ; Guardar unidades en memoria
	RJMP CONVERSION_UD_MINUTOS_EXIT

CONVERSION_UD_HORAS_EXIT:
	RET
;-----------------------------------------------------------------------------------------------
CONVERSION_UD_DIAS:
	  LDS R16, contador_dias  ; Cargar el valor del contador de dias en R16
    
    LDI R17, 10                 ; Cargar 10 en R17 para división
    MOV R18, R16                ; Copia R16 en R18 para no modificarlo
    
    ; Calcular decenas (R16 = contador_minutos / 10)
    CLR R19                     ; Limpiar R19 para la división
    MOV R20, R17                ; Copiar divisor (10) a R20
DIV_LOOP_dias:
    CP R18, R20                 ; Comparar R18 con 10
    BRLO DIV_DONE_dias               ; Si R18 < 10, salir del bucle
    SUB R18, R20                ; Restar 10 de R18
    INC R19                     ; Incrementar contador de decenas
    RJMP DIV_LOOP_dias                ; Repetir hasta que R18 < 10
DIV_DONE_dias:

    STS horas_d, R19          ; Guardar decenas en memoria
    ; Calcular unidades (R16 = contador_dias % 10)
    STS horas_u, R18          ; Guardar unidades en memoria
	RJMP CONVERSION_UD_MINUTOS_EXIT


CONVERSION_UD_DIAS_EXIT: 
	RET
;-----------------------------------------------------------------------------------------------

CONVERSION_UD_MES:
	  LDS R16, contador_mes  ; Cargar el valor del contador de mes  en R16
    
    LDI R17, 10                 ; Cargar 10 en R17 para división
    MOV R18, R16                ; Copia R16 en R18 para no modificarlo
    
    ; Calcular decenas (R16 = contador_minutos / 10)
    CLR R19                     ; Limpiar R19 para la división
    MOV R20, R17                ; Copiar divisor (10) a R20
DIV_LOOP_mes :
    CP R18, R20                 ; Comparar R18 con 10
    BRLO DIV_DONE_mes               ; Si R18 < 10, salir del bucle
    SUB R18, R20                ; Restar 10 de R18
    INC R19                     ; Incrementar contador de decenas
    RJMP DIV_LOOP_mes                 ; Repetir hasta que R18 < 10
DIV_DONE_mes :
    STS horas_d, R19          ; Guardar decenas en memoria
    ; Calcular unidades (R16 = contador_dias % 10)
    STS horas_u, R18          ; Guardar unidades en memoria
	RJMP CONVERSION_UD_MES_EXIT

CONVERSION_UD_MES_EXIT:
RET
;-----------------------------------------------------------------------------------------------


// RUTINAS DE INTERRUPCION

ISR_PCI1:

	LDS R16, contador_modo // Contador_modo = R16
	SBIS PINC, 0 // Si se preciono el boton, incrementar si se preciona (pb=0)
	INC R16
	CPI R16, 8 // Revisar cuando llegue a 8, para resetearlo a 0
	BRNE CHECK_PBS

	CLR R16
	STS contador_modo, R16 // Actualizar contador_modo, reseteado

	CHECK_PBS:
	STS contador_modo, R16 // actualizar contador_modo

	// Revisar modo y pbs apretados

	LDS R16, contador_modo // contador_modo = R16
	
	CPI R16, 0 // Cuando este en modo 0
	BREQ JMP_modo_0_PC	// Saltar a modo 0
	
	CPI R16, 1 // Cuando este en modo 1
	BREQ JMP_modo_0_PC// Saltar a modo 1

	CPI R16, 2
	BREQ JMP_modo_2_PC

	CPI R16, 3
	BREQ JMP_modo_3_PC

	CPI R16, 4
	BREQ JMP_modo_4_PC

	CPI R16, 5
	BREQ JMP_modo_5_PC

	CPI R16, 6
	BREQ JMP_modo_6_PC

	CPI R16, 7
	BREQ JMP_modo_7_PC

	RJMP ISP_PCI1_OUT

JMP_modo_0_PC:
	RJMP modo_0_PC
JMP_modo_1_PC:
	RJMP modo_1_PC
JMP_modo_2_PC:
	RJMP modo_2_PC
JMP_modo_3_PC:
	RJMP modo_3_PC
JMP_modo_4_PC:
	RJMP modo_4_PC
JMP_modo_5_PC:
	RJMP modo_5_PC
JMP_modo_6_PC:
	RJMP modo_6_PC
JMP_modo_7_PC:
	RJMP modo_7_PC

	RJMP ISP_PCI1_OUT

modo_0_PC:
	RJMP ISP_PCI1_OUT // En modo 0, los botones NO hacen nada. 
modo_1_PC:
	RJMP ISP_PCI1_OUT // En modo 0, los botones NO hacen nada. 

modo_2_PC:

	LDS R16, contador_minutos

	SBIS PINC, PC1	 // Revisa cuando se presione el boton de INC
	INC R16		// Si se preciona, INC R16 
	SBIS PINC, PC2	// Revisa cuando se presione el boton de DEC
	DEC R16		// Si se preciona, DEC R16

	
	CPI R16, 60// Revisar si se alcanzo 60
	BREQ _0_minutos // Si se alcanzo 60, regresar a 0
	CPI R16, 255 // Revisar si hay undeflow
	BREQ _59_minutos // Si hay underflow, resetear a 59

	STS contador_minutos, R16 // Sino hay under/over-flow actualizar contador_minutos
	RJMP ISP_PCI1_OUT

_0_minutos:
		LDI R16, 0
		STS contador_minutos, R16 // Actualizar contador_minutos con 0 por overflow
		RJMP ISP_PCI1_OUT

_59_minutos:
		LDI R16, 59
		STS contador_minutos, R16 // Actualizar contador_minutos con 59 por underflow
		RJMP ISP_PCI1_OUT
	
	JMP ISP_PCI1_OUT

modo_3_PC:

	LDS R16, contador_horas
	
	SBIS PINC, PC1	 // Revisa cuando se presione el boton de INC
	INC R16		// Si se preciona, INC R16 
	SBIS PINC, PC2	// Revisa cuando se presione el boton de DEC
	DEC R16		// Si se preciona, DEC R16

	CPI R16, 24// Revisar si se alcanzo 24
	BREQ _0_horas // Si se alcanzo 60, regresar a 0
	CPI R16, 255 // Revisar si hay undeflow
	BREQ _23_horas // Si hay underflow, resetear a 59

	STS contador_horas, R16 // Sino hay under/over-flow actualizar contador_horas
	RJMP ISP_PCI1_OUT

_0_horas:
		LDI R16, 0
		STS contador_horas, R16 // Actualizar contador_horas con 0 por overflow
		RJMP ISP_PCI1_OUT

_23_horas:
		LDI R16, 23
		STS contador_horas, R16 // Actualizar contador_horas con 23 por underflow
		RJMP ISP_PCI1_OUT

	JMP ISP_PCI1_OUT	

modo_4_PC:

	LDS R16, contador_dias // R16 = contador_dias
	
	SBIS PINC, PC1	 // Revisa cuando se presione el boton de INC
	INC R16	// Si se preciona, INC R16 
	SBIS PINC, PC2	// Revisa cuando se presione el boton de DEC
	DEC R16		// Si se preciona, DEC R16

	CPI R16, 0
	BREQ set_dias_del_mes // si hay undeflow, colocar la cuenta en los dias del mes
	CP R16, dias_del_mes
	BREQ set_dia_1 // Si hay overflow, colocar la cuenta de los dias en 1

	STS contador_dias, R16
	RJMP ISP_PCI1_OUT	//Sin overflow y underflow, solamente actualizar el valor de contador_dias

	set_dias_del_mes:
	MOV R16, dias_del_mes		// Seterar dias del mes, cuando haya underflow
	STS contador_dias, R16
	JMP ISP_PCI1_OUT

	set_dia_1:
	LDI R16, 1					// Setear dias del mes, cuando haya overflow
	STS contador_dias, R16
	RJMP ISP_PCI1_OUT

	RJMP ISP_PCI1_OUT	// Por configurar

modo_5_PC:

	LDS R16, contador_mes // R16 = contador_mes
	
	SBIS PINC, PC1	 // Revisa cuando se presione el boton de INC
	INC R16		// Si se preciona, INC R16 
	SBIS PINC, PC2	// Revisa cuando se presione el boton de DEC
	DEC R16		// Si se preciona, DEC R16
	
	CPI R16, 0
	BREQ set_mes_diciembre	// Revisar underflow
	CPI R16, 13
	BREQ set_mes_enero		//Revisar overflow

	STS contador_mes, R16
	RJMP ISP_PCI1_OUT

	set_mes_diciembre:
	LDI R16, 12
	STS contador_mes, R16
	RJMP ISP_PCI1_OUT

	set_mes_enero:
	LDI R16, 1
	STS contador_mes, R16
	RJMP ISP_PCI1_OUT
		
	RJMP ISP_PCI1_OUT	// Por configurar


modo_6_PC:

	LDS R16, contador_minutos_ALARMA

	SBIS PINC, PC1	 // Revisa cuando se presione el boton de INC
	INC R16		// Si se preciona, INC R16 
	SBIS PINC, PC2	// Revisa cuando se presione el boton de DEC
	DEC R16		// Si se preciona, DEC R16

	
	CPI R16, 60// Revisar si se alcanzo 60
	BREQ _0_minutos_ALARMA // Si se alcanzo 60, regresar a 0
	CPI R16, 255 // Revisar si hay undeflow
	BREQ _59_minutos_ALARMA // Si hay underflow, resetear a 59

	STS contador_minutos_ALARMA, R16 // Sino hay under/over-flow actualizar contador_minutos
	RJMP ISP_PCI1_OUT

_0_minutos_ALARMA:
		LDI R16, 0
		STS contador_minutos_ALARMA, R16 // Actualizar contador_minutos con 0 por overflow
		RJMP ISP_PCI1_OUT

_59_minutos_ALARMA:
		LDI R16, 59
		STS contador_minutos_ALARMA, R16 // Actualizar contador_minutos con 59 por underflow
		RJMP ISP_PCI1_OUT
	
	RJMP ISP_PCI1_OUT


modo_7_PC:
	LDS R16, contador_horas_ALARMA
	
	SBIS PINC, PC1	 // Revisa cuando se presione el boton de INC
	INC R16		// Si se preciona, INC R16 
	SBIS PINC, PC2	// Revisa cuando se presione el boton de DEC
	DEC R16		// Si se preciona, DEC R16

	CPI R16, 24// Revisar si se alcanzo 24
	BREQ _0_horas_ALARMA // Si se alcanzo 60, regresar a 0
	CPI R16, 255 // Revisar si hay undeflow
	BREQ _23_horas_ALARMA // Si hay underflow, resetear a 59

	STS contador_horas_ALARMA, R16 // Sino hay under/over-flow actualizar contador_horas
	RJMP ISP_PCI1_OUT

_0_horas_ALARMA:
		LDI R16, 0
		STS contador_horas, R16 // Actualizar contador_horas con 0 por overflow
		RJMP ISP_PCI1_OUT

_23_horas_ALARMA:
		LDI R16, 23
		STS contador_horas, R16 // Actualizar contador_horas con 23 por underflow
		RJMP ISP_PCI1_OUT



ISP_PCI1_OUT:
	RETI


// Rutina de interrupcion por comparación del timer0(sucede cada 10ms)
ISR_CPMA:


ISP_CPMA_EXIT:
	RETI


// Rutina de interrupcion por comparacion del timer2 ( sucede cada 5ms) 
// Control de display

ISP_CPMA2:
	
	LDS R16, control_display // Cargar control_display en R16
	INC R16					// Incrementar control_display cada 5ms
	CPI R16, 4				// Si la cuenta llego a 4, resetarla a 0
	BRNE LOAD_R16
	CLR R16					// Resetear cuenta si llego a 4, sino salir 
	STS control_display, R16	// Actualizar la cuenta, borrada


LOAD_R16:

STS control_display, R16	// Actualizar la cuenta

ISP_CPMA2_EXIT:
	
	RETI