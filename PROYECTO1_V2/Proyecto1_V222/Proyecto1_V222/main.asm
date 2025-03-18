; VERSION #2
;Universidad del Valle de Guatemala
;Departamento de ingeniería electrónica, mecatrónica y biomédica
;Programación de microcontroladores
;PROYECTO 1: Reloj
;Implementar un reloj que muestre la hora y la fecha, además que ambas puedan configurarse. Debe contar con una alarma configurable y audible
;
;CREADO POR: Alejandro Jose Martinez Contreras, 23599


.include "M328pdef.inc" 

;**************************************************************************************************
// VARIABLES GLOBALES
;**************************************************************************************************

.equ comparacion_1seg = 100 // 100: Numero que cuenta cada  10ms para alcanzar 1 segundos
.equ CTC_TMR0_cuenta = 156 // 156: Numero hasta el que cuenta el timer0, en modo CTC, para alcanzar 10ms
.equ CTC_TMR2_cuenta = 78 // 78: Numero hasta el que cuenta el timer2, en modo CTC para alcanzar 5ms

.def dias_del_mes = R18 // Registro que guarda dias del mes en función del mes

.def contador_1s = R19
.def contador_60s = R20

//Apartar R21, R22 , R23para calculos :)
//R27 se usa para comparaciones en rutina de alarma


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

minutos_u:.byte 1 
minutos_d: .byte 1 
horas_u: .byte 1 
horas_d: .byte 1 
dias_u: .byte 1 
dias_d: .byte 1 
mes_u: .byte 1 
mes_d: .byte 1 

contador_minutos_ALARMA: .byte 1 
contador_horas_ALARMA: .byte 1 

A_minutos_u: .byte 1 
A_minutos_d: .byte 1 
A_horas_d: .byte 1 
A_horas_u: .byte 1 

copia_0: .byte 1 
copia_1: .byte 1 
copia_2: .byte 1 
copia_3: .byte 1 

contador_50s: .byte 1
contador_05s: .byte 1


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
	LDI R16, 0b00000010     // Configuracion de cambio de prescaler: 4MHz 
	STS CLKPR, R16
	
	// desabilitar leds de comunicacion
	
	LDI R16, 0x00
	STS UCSR0B, R16
	//STS UCSR0C, R16 
	
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
	
	//Puerto B: Configuración como salida: Se utilizara para control de los display, por medio de transistores y aqui se instala la alarma
	
	LDI R16, 0b00111111
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

	CLR contador_60s 
	CLR contador_1s

	// Inicializar variables en RAM con valor inicial cero.

	CLR R16
	STS control_display, R16
	STS contador_modo, R16
	
	STS contador_minutos, R16
	STS contador_horas, R16

	STS minutos_u, R16
	STS minutos_d, R16

	STS horas_u, R16
	STS horas_d, R16

	STS dias_u, R16
	STS dias_d, R16

	STS mes_u, R16
	STS mes_d, R16

	STS contador_minutos_ALARMA, R16
	STS contador_horas_ALARMA, R16

	STS A_minutos_u, R16
	STS A_minutos_d, R16
	STS A_horas_u, R16
	STS A_horas_d, R16

	STS copia_0, R16
	STS copia_1, R16
	STS copia_2, R16
	STS copia_3, R16

	STS contador_50s, R16
	STS contador_05s, R16
	
	// Inicializar variables en 1
	LDI R16, 1
	STS contador_dias, R16
	STS contador_mes, R16

	//Inicializaciones especiales
	LDI dias_del_mes, 31

	//Inicialización de alarma
	LDI R16, 12
	STS contador_minutos_ALARMA, R16
	STS contador_horas_ALARMA, R16

	//Pruebas


	SEI // habilitar interrupciones globales
	
;**************************************************************************************************
//LOOP
;**************************************************************************************************

LOOP:
	
	CALL SET_REGISTRO_dias_del_mes
	CALL ISP_CONTROL // Funcion que habilita y desabilita interrupciones por Timer0  
	CALL TIEMPO_cuenta //Funcion que cuenta el tiempo. 
	CALL CONVERTIR_UD // Función que se asegura de llenar unidades y decenas de cada unidad de tiempo 

	CALL PRINT_COPIA // Funcion que maneja que se vera en los displays, en función del modo

	CALL PRINT_contador_modo // Funcion que imprime contador_modo
	CALL PRINT_display // Función que maneja el display

	CALL ALARMA_control
	
	
	RJMP LOOP

// RUTINAS SIN INTERUPCION
;-----------------------------------------------------------------------------------------------



ISP_CONTROL:

	LDS R16, contador_modo
	CPI R16, 0
	BREQ ISR_PCI1_OFF
	CPI R16, 1
	BREQ ISR_PCI1_OFF // En modo 1 y 0 habilitar interrupciones por timer0
	CPI R16, 2
	BREQ ISR_TM0_CPA_OFF // a partir del modo 2, dehabilitar las interrupciones del timer0
	CPI R16, 3
	BREQ ISR_TM0_CPA_OFF
	CPI R16, 4
	BREQ ISR_TM0_CPA_OFF
	CPI R16, 5
	BREQ ISR_TM0_CPA_OFF
	CPI R16, 6
	BREQ ISR_TM0_CPA_OFF
	CPI R16, 7
	BREQ ISR_TM0_CPA_OFF
	JMP ISP_CONTROL_EXIT

ISR_PCI1_OFF:

	LDI R16, (1 << OCIE0A)
	STS TIMSK0, R16 // Habilitar interrupciones por comparación del timer0

	RJMP ISP_CONTROL_EXIT

ISR_TM0_CPA_OFF:
	LDI R16, 0x00
	STS TIMSK0, R16 // Desabilitar interrupciones por comparación del timer0
	;CLR contador_1s
	;CLR contador_60s


	RJMP ISP_CONTROL_EXIT


ISP_CONTROL_EXIT:
	RET

;-----------------------------------------------------------------------------------------------
TIEMPO_cuenta:

	CPI contador_60s, 60
	BRNE TIEMPO_cuenta_EXIT // Revisar hasta que se alcanzen 60 segundos

	//Si se alcanzan 60 segundos
	CLR contador_60s // Limpiar cuenta de segundos
	LDS R16, contador_minutos
	INC R16 // Cada 60 segundos incrementar contador de minutos
	STS contador_minutos, R16 // Resetear cuenta de minutos a 0
	CPI R16, 60 // Revisar cuando se alcanzen los 60 minutos
	BRNE TIEMPO_cuenta_EXIT_MIN

	//Si se alcanzaron 60 minutos
	CLR R16
	STS contador_minutos, R16 // Resetear cuenta de minutos a 0

	LDS R16, contador_horas
	INC R16				// Cada 60 minutos, incrementar 1 hora

	CPI R16, 24
	BRNE TIEMPO_cuenta_EXIT_hora // Revisar cuando se alcanzen las 24 horas

	//Si se alcanzan las 24 horas
	CLR R16
	STS contador_horas, R16 // Resetear las horas a 0

	LDS R16, contador_dias
	INC R16					// Cada 24 horas, incrementar dias
	CP R16, dias_del_mes // Comparar los dias con la cantidad de dias_del_mes
	BRNE TIEMPO_cuenta_EXIT_dia

	// Si se alcanzo la cantidad de dias del mes
	LDI R16, 1
	STS contador_dias, R16 // Resetear la cantidad de dias a 1

	LDS R16, contador_mes
	INC R16					// Cada que pasen dias_del_mes, cambiar de mes

	CPI R16, 13
	BRNE TIEMPO_cuenta_EXIT_meses

	LDI R16, 1
	STS contador_mes, R16 // Si hay overflow de meses, resetear a 1 mes
	RJMP TIEMPO_cuenta_EXIT


TIEMPO_cuenta_EXIT_MIN:
	STS contador_minutos, R16 // Actualizar minutos sino hubo overflow de minutos
	RJMP TIEMPO_cuenta_EXIT

TIEMPO_cuenta_EXIT_hora:
	STS contador_horas, R16 // Actualizar horas sino hubo overflow de horas
	RJMP TIEMPO_cuenta_EXIT

TIEMPO_cuenta_EXIT_dia:
	STS  contador_dias, R16// Actualizar las horas sino hubo overflow de dias
	RJMP TIEMPO_cuenta_EXIT

	TIEMPO_cuenta_EXIT_meses:
	STS contador_mes, R16// Actualizar los meses sino hubo overflow de meses
	RJMP TIEMPO_CUENTA_EXIT

TIEMPO_cuenta_EXIT:
	RET

;-----------------------------------------------------------------------------------------------
// Funcion de conversion de numero a sus: unidades y decenas
CONVERTIR_UD:
    ; -------------------- CONVERTIR contador_minutos --------------------
    LDS R16, contador_minutos    ; Cargar valor del contador de minutos
    CALL DIVIDIR_10
    STS minutos_d, R21           ; Guardar decenas en minutos_d
    STS minutos_u, R22           ; Guardar unidades en minutos_u

    ; -------------------- CONVERTIR contador_horas --------------------
    LDS R16, contador_horas       ; Cargar valor del contador de horas
    CALL DIVIDIR_10
    STS horas_d, R21              ; Guardar decenas en horas_d
    STS horas_u, R22              ; Guardar unidades en horas_u

    ; -------------------- CONVERTIR contador_dias --------------------
    LDS R16, contador_dias        ; Cargar valor del contador de días
    CALL DIVIDIR_10
    STS dias_d, R21               ; Guardar decenas en dias_d
    STS dias_u, R22              ; Guardar unidades en dias_u

    ; -------------------- CONVERTIR contador_mes --------------------
    LDS R16, contador_mes         ; Cargar valor del contador de mes
    CALL DIVIDIR_10
    STS mes_d, R21               ; Guardar decenas en mes_d
    STS mes_u, R22                ; Guardar unidades en mes_u

    ; -------------------- CONVERTIR contador_minutos_ALARMA --------------------
    LDS R16, contador_minutos_ALARMA
    CALL DIVIDIR_10
    STS A_minutos_d, R21         ; Guardar decenas en A_minutos_d
    STS A_minutos_u, R22          ; Guardar unidades en A_minutos_u

    ; -------------------- CONVERTIR contador_horas_ALARMA --------------------
    LDS R16, contador_horas_ALARMA
    CALL DIVIDIR_10
    STS A_horas_d,R21            ; Guardar decenas en A_horas_d
    STS A_horas_u, R22           ; Guardar unidades en A_horas_u

    RJMP CONVERTIR_UD_EXIT

;--------------------------------------------------------------------------------
; **SUBRUTINA: DIVIDIR_10**
; Entrada: R16 (valor a dividir por 10)
; Salida:  R21 (decenas), R22 (unidades)
;--------------------------------------------------------------------------------
DIVIDIR_10:
    CLR R21                         ; R18 almacenará las decenas
    MOV R22, R16                   ; Copiar valor original a R19 para calcular unidades
    LDI R23, 10                    ; Cargar divisor (10) en R23

DIV_LOOP:
    CP R22, R23                    ; Comparar R19 con 10
    BRLO DIV_DONE                   ; Si R19 < 10, salir del bucle
    SUB R22, R23                   ; Restar 10 a R19
    INC R21                         ; Incrementar el contador de decenas
    RJMP DIV_LOOP                  ; Repetir hasta que R19 < 10

DIV_DONE:
    RET

CONVERTIR_UD_EXIT:
    RET


;-----------------------------------------------------------------------------------------------
PRINT_display: 

	LDS R16, control_display

		CPI R16, 0
	BREQ DISPLAY_0 // 3 - X - X - x 
		
		CPI R16, 1
	BREQ DISPLAY_1 //  X - 2 - X - x 
		
		CPI R16, 2
	BREQ DISPLAY_2 // X - X - 1 - x
		
		CPI R16, 3
	BREQ DISPLAY_3 // X - X - X - 0 
	
	RET

DISPLAY_0: 
	

	LDS R16, copia_0

	LDI ZL, LOW(TABLA7SEG << 1)
	LDI ZH, HIGH(TABlA7SEG << 1)
	ADD ZL, R16 
	LPM R16, Z
	OUT PORTD, R16
	SBI PORTB, 3	//Encender DISPLAY 3
	JMP PRINT_display_EXIT

DISPLAY_1: 

	LDS R16, copia_1

	LDI ZL, LOW(TABLA7SEG << 1)
	LDI ZH, HIGH(TABlA7SEG << 1)
	ADD ZL, R16 
	LPM R16, Z
	OUT PORTD, R16
	SBI PORTB, 2	//Encender DISPLAY 2
	JMP PRINT_display_EXIT

DISPLAY_2: 

	
	LDS R16, copia_2

	LDI ZL, LOW(TABLA7SEG << 1)
	LDI ZH, HIGH(TABlA7SEG << 1)
	ADD ZL, R16 
	LPM R16, Z
	OUT PORTD, R16
	SBI PORTB, 1	//Encender DISPLAY 1
	JMP PRINT_display_EXIT

DISPLAY_3: 

	LDS R16, copia_3

	LDI ZL, LOW(TABLA7SEG << 1)
	LDI ZH, HIGH(TABlA7SEG << 1)
	ADD ZL, R16 
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
// Funcion de copiar en registros de copia, en funcion del modo, para mostrar en el display algo que queremos
PRINT_COPIA:

	LDS R16, contador_modo

	CPI R16, 0
	BREQ JMP_ver_hora		//Ver hora
	CPI R16, 1
	BREQ JMP_ver_fecha		// Ver la fecha
	CPI R16, 2
	BREQ JMP_conf_min		//coNFIGURACION de minutos
	CPI R16, 3
	BREQ JMP_conf_horas		//CONFIGURACION	 de horas
	CPI R16, 4
	BREQ JMP_conf_dia		//CONFIGURACION de dia
	CPI R16, 5
	BREQ JMP_conf_mes		// CONFIGURACION de dia
	CPI R16, 6
	BREQ JMP_conf_min_A		//CONFIGURACION  de minutos de alarma
	CPI R16, 7
	BREQ JMP_conf_hora_A	//Configuracion de horas de alarma
	RJMP PRINT_COPIA_EXIT

JMP_ver_hora:
	RJMP ver_hora

JMP_ver_fecha:
	RJMP ver_fecha

JMP_conf_min:
	RJMP conf_min

JMP_conf_horas:
	RJMP conf_horas

JMP_conf_dia:
	RJMP conf_dia

JMP_conf_mes:
	RJMP conf_mes

JMP_conf_min_A:
	RJMP conf_min_A

JMP_conf_hora_A:
	RJMP conf_hora_A

ver_hora:
	LDS R16, minutos_u
	STS copia_0, R16 // Cargar a copia 0 minutos_u
	LDS R16, minutos_d
	STS copia_1, R16// Cargar a copia 1 minutos_d
	LDS R16, horas_u
	STS copia_2, R16 // Cargar a copia 2 horas_u
	LDS R16, horas_d
	STS copia_3, R16 // Cargar a copia 3 horas_D 
	RJMP PRINT_COPIA_EXIT

ver_fecha: // FORMATO: MM/DD
	LDS R16, mes_u
	STS copia_0, R16 // Cargar a copia 0 mes_u
	LDS R16, mes_d
	STS copia_1, R16 // Cargar a copia 1 mes_d
	LDS R16, dias_u
	STS copia_2, R16 // Cargar a copia 2 dia_u
	LDS R16, dias_d
	STS copia_3, R16 // Cargar a copia 3 dia_D 
	RJMP PRINT_COPIA_EXIT
conf_min:
	LDS R16, minutos_u
	STS copia_0, R16 // Cargar a copia 0 minutos_u
	LDS R16, minutos_d
	STS copia_1, R16 // Cargar a copia 1 minutos_d
	LDS R16, horas_u
	STS copia_2, R16 // Cargar a copia 2 horas_u
	LDS R16, horas_d
	STS copia_3, R16 // Cargar a copia 3 horas_D 
	RJMP PRINT_COPIA_EXIT
conf_horas:
	LDS R16, minutos_u
	STS copia_0, R16 // Cargar a copia 0 minutos_u
	LDS R16, minutos_d
	STS copia_1, R16 // Cargar a copia 1 minutos_d
	LDS R16, horas_u
	STS copia_2, R16 // Cargar a copia 2 horas_u
	LDS R16, horas_d
	STS copia_3, R16 // Cargar a copia 3 horas_D 
	RJMP PRINT_COPIA_EXIT
conf_dia:
	LDS R16, mes_u
	STS copia_0, R16 // Cargar a copia 0 mes_u
	LDS R16, mes_d
	STS copia_1, R16 // Cargar a copia 1 mes_d
	LDS R16, dias_u
	STS copia_2, R16 // Cargar a copia 2 dia_u
	LDS R16, dias_d
	STS copia_3, R16 // Cargar a copia 3 dia_D 
	RJMP PRINT_COPIA_EXIT
conf_mes:
	LDS R16, mes_u
	STS copia_0, R16 // Cargar a copia 0 mes_u
	LDS R16, mes_d
	STS copia_1, R16 // Cargar a copia 1 mes_d
	LDS R16, dias_u
	STS copia_2, R16 // Cargar a copia 2 dia_u
	LDS R16, dias_d
	STS copia_3, R16 // Cargar a copia 3 dia_D 
	RJMP PRINT_COPIA_EXIT

conf_min_A:
	LDS R16, A_minutos_u
	STS copia_0, R16 // Cargar a copia 0 minutos_u_ALARMA
	LDS R16, A_minutos_d
	STS copia_1, R16 // Cargar a copia 1 minutos_d_ALARMA
	LDS R16, A_horas_u
	STS copia_2, R16 // Cargar a copia 2 horas_u_ALARMA
	LDS R16, A_horas_d
	STS copia_3, R16 // Cargar a copia 3 horas_D _ALARMA
	RJMP PRINT_COPIA_EXIT

conf_hora_A:
	LDS R16, A_minutos_u
	STS copia_0, R16 // Cargar a copia 0 minutos_u_ALARMA
	LDS R16, A_minutos_d
	STS copia_1, R16 // Cargar a copia 1 minutos_d_ALARMA
	LDS R16, A_horas_u
	STS copia_2, R16 // Cargar a copia 2 horas_u_ALARMA
	LDS R16, A_horas_d
	STS copia_3, R16 // Cargar a copia 3 horas_D _ALARMA
	RJMP PRINT_COPIA_EXIT



PRINT_COPIA_EXIT:
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

//Funcion que controla la alarma
ALARMA_control:
	LDS R16, contador_horas_ALARMA // Cargar el contador de alarma a R16
	LDS R25, contador_horas			//Cargar el contador de horas a R24

	CP R16, R25			//Revisar si las horas son iguales, si son iguales continuar, sino salir y mantener apagada la alarma
	BRNE ALARMA_control_EXIT

//Si son iguales, revisar minutos

	LDS R16, contador_minutos_ALARMA // Cargar contador de minutos de alarma a R16
	LDS R25, contador_minutos  // Cargar contador de minutos de alarma a R24

	CP R16, R25 // Revisar si los minutos son iguales. Si las horas y minutos son iguales, activar la alarma. SINO salir
	BRNE ALARMA_control_EXIT

//Si son iguales

	SBI PORTB, 5 // Encender la alarma cuando se alcanze el minutos
	JMP ALARMA_control_EXIT 


ALARMA_control_EXIT_OFF:
	CBI PORTB, 5 // MANTENER APAGADA LA ALARMA
	RJMP ALARMA_control_EXIT

ALARMA_control_EXIT:
	RET
;-----------------------------------------------------------------------------------------------

SET_REGISTRO_dias_del_mes:

LDS R16, contador_mes // Cargar a R16 dias del mes
CPI R16, 1 
BREQ set_31_dias // Enero

CPI R16, 2
BREQ set_28_dias// febrero

CPI R16, 3 
BREQ set_31_dias // Marzo

CPI R16, 4		//Abril
BREQ set_30_dias

CPI R16, 5
BREQ set_31_dias // Mayo

CPI R16, 6 
BREQ set_30_dias // Junio

CPI R16, 7 
BREQ set_31_dias //Julio

CPI R16, 8 
BREQ set_31_dias // Agosto

CPI R16, 9 
BREQ set_30_dias // Septiembre

CPI R16, 10 
BREQ set_31_dias // Octubre

CPI R16, 11 
BREQ set_30_dias // Noviembre

CPI R16, 12 
BREQ set_31_dias // Diciembre

set_31_dias:

	LDI dias_del_mes, 32 // Colocar 31 como los dias del mes
	RJMP SET_REGISTRO_dias_del_mes_EXIT

set_30_dias:
	LDI dias_del_mes,31 // colocar 30 como los dias del mes
	RJMP SET_REGISTRO_dias_del_mes_EXIT

set_28_dias:
	LDI dias_del_mes, 29 // Colocar 28 como dias del mes
	RJMP SET_REGISTRO_dias_del_mes_EXIT

SET_REGISTRO_dias_del_mes_EXIT:
	RET




;-----------------------------------------------------------------------------------------------

// RUTINAS DE INTERRUPCION

ISR_PCI1:
	IN R1, SREG
	PUSH R1
	PUSH R16

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

_23_horas:
		LDI R16, 23
		STS contador_horas, R16 // Actualizar contador_horas con 23 por underflow
		RJMP ISP_PCI1_OUT

_0_horas:
		LDI R16, 0
		STS contador_horas, R16 // Actualizar contador_horas con 0 por overflow
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
		STS contador_horas_ALARMA, R16 // Actualizar contador_horas con 0 por overflow
		RJMP ISP_PCI1_OUT

_23_horas_ALARMA:
		LDI R16, 23
		STS contador_horas_ALARMA, R16 // Actualizar contador_horas con 23 por underflow
		RJMP ISP_PCI1_OUT



ISP_PCI1_OUT:
	POP R16
	POP R1
	OUT SREG, R0
	RETI


// Rutina de interrupcion por comparación del timer0(sucede cada 10ms)
ISR_CPMA:
	
	IN R1, SREG
	PUSH R1
	PUSH R16

	INC contador_1s

	CPI contador_1s, comparacion_1seg// Si el contador_1s alcanzo 100, se llego a 1 segundo
	BRNE ISP_CPMA_EXIT // Si no se ha alcanzado, salir
	
	CLR contador_1s // Cada segundo, limpiar el contador para empezar la cuenta de nuevo
	INC contador_60s // Incrementar contador cada segundo

ISP_CPMA_EXIT:
	
	POP R16
	POP R1
	OUT SREG, R0
	RETI


// Rutina de interrupcion por comparacion del timer2 ( sucede cada 5ms) 
// Control de display

ISP_CPMA2:
	
	IN R1, SREG
	PUSH R1
	PUSH R16


	LDS R16, contador_50s // Cargar contador de medio segundo a R1
	INC R16				// Incrementarlo
	CPI R16, 100			// Revisar si llega a 100, esto indica 50ms
	BRNE no_encender_led
	SBI PORTB, 4			//Si pasaron 50ms encender
	
no_encender_led:
	STS contador_50s, R16
	CPI R16, 200
	BRNE control_display_R // Revisar hasta que hayan pasado otros 50ms
	CBI PORTB, 4 // Si pasaron otros 50ms apagar
	CLR R16
	STS contador_50s, R16

control_display_R:
	
	LDS R16, control_display // Cargar control_display en R16
	INC R16					// Incrementar control_display cada 5ms
	CPI R16, 4				// Si la cuenta llego a 4, resetarla a 0
	BRNE LOAD_R16
	CLR R16					// Resetear cuenta si llego a 4, sino salir 
	STS control_display, R16	// Actualizar la cuenta, borrada


LOAD_R16:

STS control_display, R16	// Actualizar la cuenta

ISP_CPMA2_EXIT:

	POP R16
	POP R1
	OUT SREG, R0
	RETI