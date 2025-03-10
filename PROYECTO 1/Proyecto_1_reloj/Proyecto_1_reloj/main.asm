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

.equ comparacion_1seg = 5 // 100: Numero que cuenta cada  10ms para alcanzar 1 segundos
.equ CTC_TMR0_cuenta = 5 // 156: Numero hasta el que cuenta el timer0, en modo CTC


; R16: Se utilizara para variables temporales

// Contadores para llevar la cuenta de toda unidad y decena de tiempo

.def contador_modo =R17  // Contador de modo
; Modo = 0, mostrar hora
; Modo = 1, Mostrar fecha
; Modo = 2, configurar minutos
; Modo = 3, configurar horas
; Modo = 4, configurar Dia
; Modo = 5, configurar Mes
; modo = 6, configurar alarma
; modo = 7, NO SE AUN. :)
.equ cantidad_modos = 5 // Puede cambiar dependiendo de la cantidad de modos, mas uno que haya

.def bandera_modo =  R18  // bandera de control para modos. 
// bandera_modo = 1 -> incrementar---bandera_modo = 2 -> decrementar---bandera_modo = 0 -> Hacer nada

.def contador_1_seg = R19// Contador que cuando se llena con 100, ha pasado 1 segundo. 
.def contador_60_seg = R20 // contador que incrementa cada segundo. 

.def minutos_u = R21 // Cuenta de minutos. Unidades y Decenas
.def minutos_d = R22

.def horas_u = R23 // Cuenta de horas. Unidades y decenas
.def horas_d = R24

.def control_display = R25 // Control de display por medio de transitores




// Dirrecciones de memoria para almancenar data

.dseg
.org SRAM_START // 0x0100

dias_u: .byte 1 
dias_d: .byte 1 
mes_u: .byte 1
mes_d: .byte 1


contador_dias: .byte 1 // Contador de días
contador_mes: .byte 1 // Contador de mes.
dias_del_mes: .byte 1 // Guarda el valor al que debe de llegar el mes
contador_horas: .byte 1 // Cuenta horas


//Banderas de aumento y decremento. INC = 1, DEC = 2, NADA = 0

bandera_minutos: .byte 1
bandera_horas: .byte 1
badera_dias: .byte 1
bandera_mes: .byte 1

copia_0: .byte 1
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
.org OC0Aaddr // Vector de interrupcion por comparacion
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


//Puerto D: configuracion como salida. Se utilizara para imprimir en display

LDI R16, 0xFF
OUT DDRD, R16

//Puerto B: Configuración como salida: Se utilizara para control de los display, por medio de transistores

LDI R16, 0xFF
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



// Inicialización de variables
CLR contador_modo
CLR contador_1_seg
CLR contador_60_seg
CLR minutos_u
CLR minutos_d
CLR horas_u
CLR horas_d 
CLR control_display

// Inicializar contadores de registros indirectos en 0

LDI R16, 0x01		// Setear en 1
STS dias_u, R16		// Las unidades de día, empiezan en 1
STS mes_u, R16		// Las unidades de día, empiezan en 1
STS contador_dias, R16 // La cuenta de los días empieza en 1 día

STS contador_mes, R16 // Contador_mes empieza en 1. 

LDI R16, 0x00
STS dias_d, R16		// Las decenas de dia, empiezan en 0
STS mes_d, R16		// Las decenas de dia, empiezan en 0
STS contador_horas, R16 // La cuenta de horas empieza 0
STS bandera_minutos, R16 // Bandera de minutos, empiezan en 0




// Transistor de prueba -- SE VA A QUITAR PARA PRUEBAS EN TODOS LOS DISPLAYs. 
//LDI R16, 0x1
//OUT PORTB, R16


SEI

;**************************************************************************************************
//LOOP
;**************************************************************************************************

LOOP:


	CALL DATE_set_dias_del_mes // Funcion que coloca en el contador dias_del_mes la cantidad de dias del mes. :)
	CALL DATE_cuenta_mes		// Funcion que actualiza el mes en función de los dias
	CALL TIEMPO_cuenta		// Lleva la cuenta de TODO el timpo 
	CALL COPY__FOR_MODE
	CALL PRINT_DISPLAY
	CALL PRINT_contador_modo // Mostrar el contador de modo

RJMP LOOP

;**************************************************************************************************
//FUNCIONES
;**************************************************************************************************



//FUNCION QUE IMPRIME EL CONTADOR DE MODO
PRINT_contador_modo:
		
	CBI PORTC, PC3
	CBI PORTC, PC4
	CBI PORTC, PC5 // Limpiar registros, evitar señales parasitas

	SBRC contador_modo, 0 // Si CONTADOR_MODO[0] = 1, colocar 1, sino sigue en0
	SBI PORTC, PC3
	SBRC contador_modo, 1 // Si CONTADOR_MODO[1] = 1, colocar 1, sino sigue en 0
	SBI PORTC, PC4
	SBRC contador_modo, 2 // Si CONTADOR_MODO[2] = 1, colocar 1, sino sigue en 0
	SBI PORTC, PC5

	RET


//FUNCION QUE ACTUALIZA LOS MESES

;***********************************************************************************************************************************
DATE_cuenta_mes:

	LDS R16, contador_dias // R16 = Contador_dias
	LDS R15, dias_del_mes // R15 = dias_del_mes (calulado en la funcion anterior. Es el número de dias al que debe resetearse la actualizarse de meses)

	CP R16, R15 
	BRNE DATE_cuenta_mes_EXIT	// Si el contador_dias es diferente de dias_del_mes, SALIR y continuar como si nada ha pasado

	//Si son iguales...

	LDI R16, 1
	STS contador_dias, R16		// Colocar cuenta de dias en 1
	STS dias_u, R16			// Colcoar dias_u en 1

	CLR R16
	STS dias_d, R16 // Colocar dias_u en 0


	LDS R16, contador_mes
	INC R16
	STS contador_mes, R16	// Aumentar contador_mes

	LDS R16, mes_u
	INC R16
	

	CPI R16, 10		// Revisar cuando se alcanzen los 10 meses
	BRNE mes_u_set	//Sino han pasado 10 meses, salir

	CLR R16
	STS mes_u, R16 // Si pasaron 10 meses, regresar mes_u a 0

	LDS R16, mes_d // Si pasaron 10 meses, incrementar mes_d
	INC R16
	
	LDS R15, contador_mes

	CP R16, R15	// Cuando hayan pasado 12 meses (1 año), regresar la cuenta 0d, 1u
	BRNE mes_d_set



	LDI R16, 1			//Regresar la cuenta a 01/01
	STS mes_u, R16
	STS contador_mes, R16

	CLR R16
	STS mes_d, R16

	RJMP DATE_cuenta_mes_EXIT

mes_u_set:
	STS mes_u, R16 // Aumentar unidades de mes
	RJMP DATE_cuenta_mes_EXIT

mes_d_set:
	STS mes_d, R16 // Aumentar decenas de mes
	RJMP DATE_cuenta_mes_EXIT

DATE_cuenta_mes_EXIT:
	RET
;***********************************************************************************************************************************


// FUNCION QUE CUENTA TIEMPO


;***********************************************************************************************************************************
TIEMPO_cuenta:

// REVISAR SI HAN PASADO 24 horas ----El contador_horas se encuentra mas abajo :)

	LDS R16, contador_horas // revisar contador_horas
	CPI R16, 24			// Comparar cuando llegue a 24
	BRNE CONTAR_TIEMPO // Si no ha llegado a 24 horas, continuar contando tiempo

	CLR R16
	STS contador_horas, R16	// Resetear el contador de horas, cada que llegue a 24

	CLR horas_u
	CLR horas_d
	CLR minutos_u
	CLR minutos_d

	;**** RUTINA PARA HACER CUENTAS SOBRE LA FECHA****

	LDS R16, contador_dias // Cada 24 horas, incrementar el contador de días, pues ha pasado 1 día :)
	INC R16
	STS contador_dias, R16 // Actualizar contador_dias

	LDS R16, dias_u
	INC R16				 // Cada 24 horas, incrementar dias_u
	CPI R16, 10
	BRNE DATE_dias_u_EXIT // Si no han pasado 10 dias, no resetear la cuenta, pero actualizar días_u

	CLR R16			// Cada 10 dias, resetear en 0 la cuenta de unidades
	STS dias_u, R16		// Actualizar la cuenta de unidades de dias 


	LDS R16, dias_d		// Cargar dias_d
	INC R16		// Cada 10 dias, incrementar en 1 dias_d
	
	CPI R16, 10
	BRNE DATE_dias_d_EXIT


	// Cada vez que pasen 10 veces, 1 dias_d resetear la cuenta
	CLR R16			// resetear a o la cuenta de decenas
	STS dias_d, R16 // actualizar dias_u


	// LOGICA PARA TOPAR LOS DIAS E INCREMENTAR LOS MESES EN OTRA FUNCIÓN


	
	RJMP CONTAR_TIEMPO
	


DATE_dias_u_EXIT:
	STS dias_u, R16 // actualizar dias_u 
	RJMP CONTAR_TIEMPO

DATE_dias_d_EXIT:
	STS dias_d, R16 // Actualizar dias_d
	RJMP CONTAR_TIEMPO 


	

CONTAR_TIEMPO:

	CPI contador_60_seg, 60
	BRNE TIEMPO_cuenta_EXIT // Si no han pasado 60 segundos, SALIR. 

	CLR contador_60_seg // Cada que se alcancen los 60 segundos, limpiar la cuenta de segundos
	INC minutos_u		// Cada que se alcancen 60 segundos, incrementar los minutos 

	CPI minutos_u, 10 // Revisar cuando llegue a 10 minutos
	BRNE TIEMPO_cuenta_EXIT // Salir sino a llegado a los 10 minutos

	CLR minutos_u // Cuando se alcancen los 10 minutos, limpiar la cuenta
	INC minutos_d // Cada 10 minutos, incrementar la cuenta de decenas de minutos

	CPI minutos_d, 6 // Revisar cuando se alcancen 60 minutos, limpiar la cuenta
	BRNE TIEMPO_cuenta_EXIT // Sino se alcanzan los 60 minutos, salir

	CLR minutos_d // Cuando se alcancen los 60 minutos, limpiar la cuenta
	INC horas_u // Cuando se alcanen los 60 minutos, aumentar las horas


	LDS R16, contador_horas
	INC R16
	STS contador_horas, R16 // Incrementar contador de horas. 

	CPI horas_u, 10 // Revisar cuando se alcancen las 10 horas
	BRNE TIEMPO_cuenta_EXIT // Sino se alcanzan las 10 horas, salir

	CLR horas_u // Cuando se alcancen las 10 horas, limpiar la cuenta
	INC horas_d // Cuando se alcancen 10 horas, incrementar las decenas

	CPI horas_d, 10
	BRNE TIEMPO_cuenta_EXIT

	CLR horas_d

	// Incrementar las decenas de hora. Revisar el contador_horas sirve para resetear la cuenta. La cuenta se retea al incio de esta funcion :)
	

	RJMP TIEMPO_cuenta_EXIT



TIEMPO_cuenta_EXIT:
	RET
;***********************************************************************************************************************************


;***********************************************************************************************************************************

DATE_set_dias_del_mes: // Funcion que coloca en dias_del_mes la cantidad de dias del mes

	LDS R16, contador_mes // Extraer el contador de mes. Este indica en que mes estamos. 

	CPI R16, 1 
	BREQ set_31 // Enero

	CPI R16, 2	// Febrero
	BREQ set_28

	CPI R16, 3 // Marzo
	BREQ set_31

	CPI R16, 4		//Abril
	BREQ set_30

	CPI R16, 5 // Mayo
	BREQ set_31

	CPI R16, 6 // Junio
	BREQ set_30

	CPI R16, 7	// Julio
	BREQ set_31

	CPI R16, 8	// Agosto
	BREQ set_31

	CPI R16, 9 // septiembre
	BREQ set_30

	CPI R16, 10 // Octubre
	BREQ set_31

	CPI R16, 11	// Noviembre
	BREQ set_30

	CPI R16, 11 // Diciembre
	BREQ set_31 


set_31:

	LDI R16, 32 // Colocar 30 dias 
	STS dias_del_mes, R16 // Actualizar dias del mes :)
	RET

set_28:
	
	LDI R16, 29 // Colocar 28 dias 
	STS dias_del_mes, R16 // Atualizar dias del mes ::
	RET

set_30:

	LDI R16, 31 // Colocar 30 dias 
	STS dias_del_mes, R16 // Atualizar dias del mes :)
	RET





;***********************************************************************************************************************************


// Funcion que copia registros para imprimirlos en displays en funcion del modo
COPY__FOR_MODE:

	CPI contador_modo, 0
	BREQ view_time
	CPI contador_modo, 1
	BREQ view_date
	CPI contador_modo, 2
	BREQ configurar_minutos
	
	JMP COPY_FOR_MODE_EXIT

view_time: //Copiar contadores de hora, para mostrarlos

	MOV R16, minutos_u
	STS copia_0, R16 // Copiar minutos_u en copia_0

	MOV R16, minutos_d
	STS copia_1, R16 // Copiar minutos_u en copia_1

	MOV R16, horas_u
	STS copia_2, R16 // Copiar minutos_u en copia_2

	MOV R16, horas_d
	STS copia_3, R16 // Copiar minutos_u en copia_3
	
	RJMP COPY_FOR_MODE_EXIT


view_date:

	LDS R16, dias_u
	STS copia_0, R16 // Copiar dia_u en copia_0

	LDS R16, dias_d
	STS copia_1, R16 // Copiar dia_d en copia_1

	LDS R16, mes_u
	STS copia_2, R16 // Copiar mes_u en copia_2

	LDS R16, mes_d
	STS copia_3, R16 // Copiar mes_d en copia_3

	RJMP COPY_FOR_MODE_EXIT

configurar_minutos:
	


	RJMP COPY_FOR_MODE_EXIT



COPY_FOR_MODE_EXIT:
	RET



// Funcion que muestra en display

PRINT_DISPLAY:


CPI control_display, 0
BREQ PRINT_0 // ACTIVAR DISPLAY 1

CPI control_display, 1
BREQ PRINT_1 // ACTIVAR DISPLAY 2

CPI control_display, 2
BREQ PRINT_2 // ACTIVAR DISPLAY 3

CPI control_display, 3
BREQ PRINT_3 // ACTIVAR DISPLAY 3


PRINT_0:

// Imprimir en DISPLAY MINUTOS_U
CBI PORTB, 0
CBI PORTB, 1
CBI PORTB, 2
CBI PORTB, 3

LDS R16, copia_0  // Cargar la copia  en R16
LDI ZL, LOW(TABLA7SEG << 1)
LDI ZH, HIGH(TABLA7SEG << 1)
ADD ZL, R16 // Sumar la copia
LPM R16, Z // pasar el resultado de la suma a R16
OUT PORTD, R16  // Imprimir la copia

SBI PORTB, 3


PRINT_1:


// Imprimir en DISPLAY MINUTOS_D
CBI PORTB, 0
CBI PORTB, 1
CBI PORTB, 2
CBI PORTB, 3

LDS R16, copia_1		// Cargar copia_1
LDI ZL, LOW(TABLA7SEG << 1)
LDI ZH, HIGH(TABLA7SEG << 1)
ADD ZL, R16				// Sumar copia 1
LPM R16, Z
OUT PORTD, r16

SBI PORTB, 2

PRINT_2:

CBI PORTB, 0
CBI PORTB, 1
CBI PORTB, 2
CBI PORTB, 3

LDS R16, copia_2
LDI ZL, LOW(TABLA7SEG << 1)
LDI ZH, HIGH(TABLA7SEG << 1)
ADD ZL, R16
LPM R16, Z
OUT PORTD, r16

SBI PORTB, 1

PRINT_3:

CBI PORTB, 0
CBI PORTB, 1
CBI PORTB, 2
CBI PORTB, 3

LDS R16, copia_3
LDI ZL, LOW(TABLA7SEG << 1)
LDI ZH, HIGH(TABLA7SEG << 1)
ADD ZL, R16
LPM R16, Z
OUT PORTD, R16

SBI PORTB, 0



PRINT_DISPLAY_EXIT:
	RET

	
// Funcion que maneja banderas de incremento y decremento


INC_minutos:
	
	INC minutos_u		//Incrementar minutos
	
	CLR R16
	STS bandera_minutos, R16 // Limpiar bandera de minutos

	JMP BANDERAS_MODO_EXIT

DEC_minutos:
	
	DEC minutos_u

	
	CLR R16
	STS bandera_minutos, R16 // Limpiar bandera de minutos

	JMP BANDERAS_MODO_EXIT

BANDERAS_MODO_EXIT:
	RET
	
;**************************************************************************************************
// RUTINAS DE INTERRUPCIONES
;**************************************************************************************************


ISR_PCI1:

	SBIS PINC, PC0 // Revisa cuando se presione el boton
	INC contador_modo
	ANDI contador_modo, 0x07 // Mascara para regresar a 0 cada vez que se alcanze 0.


CHECK_MODO_ISR:

	CPI contador_modo, 0 // Cuando este en modo 0
	BREQ modo_0_PC	// Saltar a modo 0
	
	CPI contador_modo, 1 // Cuando este en modo 1
	BREQ modo_1_PC // Saltar a modo 1

	CPI contador_modo, 2
	BREQ modo_2_PC

	RJMP ISP_PCI1_OUT
	

modo_0_PC:
	RJMP ISP_PCI1_OUT // En modo 0, los botones NO hacen nada. 
modo_1_PC:
	RJMP ISP_PCI1_OUT // En modo 0, los botones NO hacen nada. 

modo_2_PC:
	RJMP ISP_PCI1_OUT	// Por configurar




ISP_PCI1_OUT:
RETI


// Rutina de interrupcion por comparación (sucede cada 10ms)
ISR_CPMA:

	INC control_display
	CPI control_display, 4
	BRNE TIEMPO_cuenta_segundo
	CLR control_display


TIEMPO_cuenta_segundo:

	// Cada 10ms incrementar el contador hasta alcanzar 1 segundo. 
	INC contador_1_seg // Incrementar el contador cada 10ms
	CPI contador_1_seg, comparacion_1seg// Comparar el contador con 100. Cuando sean iguales, habrá pasado 1 segundo
	BRNE ISR_CPMA_OUT // Cuando no sean iguales, salir. si son iguales...
	
	CLR contador_1_seg // LIMPIAR el contador de 1 seg, cada que este se alcanze para reiniciar la cuenta. 
	INC contador_60_seg // Cada que pasa 1 segundo, aumentar el contador de 60segundos. Este se limpia en otra funcion. 

	

ISR_CPMA_OUT:
	RETI

