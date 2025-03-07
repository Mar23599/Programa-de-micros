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

.equ comparacion_1seg = 100 // Numero que cuenta 10ms para alcanzar 1 segundos
.equ CTC_TMR0_cuenta = 156 // Numero hasta el que cuenta el timer0, en modo CTC


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




// Transistor de prueba -- SE VA A QUITAR PARA PRUEBAS EN TODOS LOS DISPLAYs. 
//LDI R16, 0x1
//OUT PORTB, R16


SEI

;**************************************************************************************************
//LOOP
;**************************************************************************************************

LOOP:
	CALL TIEMPO_cuenta		// Lleva la cuenta de TODO el timpo 
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

// FUNCION QUE CUENTA TIEMPO

TIEMPO_cuenta:


	CPI contador_60_seg, 60
	BRNE TIEMPO_cuenta_EXIT // Si no han pasado 60 segundos, SALIR. 

	CLR contador_60_seg // Cada que se alcancen los 60 segundos, limpiar la cuenta de segundos
	INC minutos_u		// Cada que se alcancen 60 segundos, incrementar los minutos 

	CPI minutos_u, 10 // Revisar cuando llegue a 10 minutos
	BRNE TIEMPO_cuenta_EXIT // Salir sino a llegado a los 10 minutos

	CLR minutos_u // Cuando se alcancen los 10 minutos, limpiar la cuenta
	INC minutos_d // Cada 10 minutos, incrementar la cuenta de decenas de minutos

	CPI minutos_d, 60 // Revisar cuando se alcancen 60 minutos, limpiar la cuenta
	BRNE TIEMPO_cuenta_EXIT // Sino se alcanzan los 60 minutos, salir

	CLR minutos_D // Cuando se alcancen los 60 minutos, limpiar la cuenta
	INC horas_u // Cuando se alcanen los 60 minutos, aumentar las horas

	CPI horas_u, 10 // Revisar cuando se alcancen las 10 horas
	BRNE TIEMPO_cuenta_EXIT // Sino se alcanzan las 10 horas, salir

	CLR horas_u // Cuando se alcancen las 10 horas, limpiar la cuenta
	INC horas_d // Cuando se alcancen 10 horas, incrementar las decenas

	//Logica para resetearse en 24 horas

	CPI horas_d, 2 // Revisar cuando se alcancen las 20 horas
	BRNE TIEMPO_cuenta_EXIT // Si no se alcanzaron 20 horas, salir

	CPI horas_u, 4 // Cuando se alzancen las 20 horas, revisar las 4 unidades de hora
	BRNE TIEMPO_cuenta_EXIT // Sino se alcanzan las 24 horas, salir

	CLR horas_u
	CLR horas_d // Cuando se alcanzen las 24 horas, limpiar las horas

	// INC DIA CUENTA DE LOS DIAS


TIEMPO_cuenta_EXIT:
RET


// Funcion que muestra en display

PRINT_DISPLAY:

CBI PORTB, 0 
CBI PORTB, 1
CBI PORTB, 2
CBI PORTB, 3

CPI control_display, 0
BREQ PRINT_0 // ACTIVAR DISPLAY 1
CPI control_display, 1
BREQ PRINT_1 // ACTIVAR DISPLAY 2
CPI control_display, 2
BREQ PRINT_2 // ACTIVAR DISPLAY 3
CPI control_display, 3
BREQ PRINT_3 // ACTIVAR DISPLAY 3



PRINT_0:


SBI PORTB, 3 // ACTIVAR DISPLAY 1 
LDI R16, 0x01
OUT PORTD, R16

PRINT_1:

SBI PORTB, 2 // ACTIVAR DISPLAY 2 



OUT PORTD, R16

PRINT_2:

SBI PORTB, 1 // ACTIVAR DISPLAY 3 


OUT PORTD, R16

PRINT_3:

SBI PORTB, 0 // ACTIVAR DISPLAY 4

LDI R16, 0x00
OUT PORTD, R16

//OUT PORTD, horas_d


PRINT_DISPLAY_EXIT:
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

	RJMP ISP_PCI1_OUT
	

modo_0_PC:
	RJMP ISP_PCI1_OUT // En modo 0, los botones NO hacen nada. 
modo_1_PC:
	RJMP ISP_PCI1_OUT // En modo 0, los botones NO hacen nada. 


	


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

