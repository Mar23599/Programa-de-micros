;
; Ejemplo timer0.asm
;
; Created: 7/02/2025 18:24:29
; Author : aleja
;


; Replace with your application code
start:
    inc r16
    rjmp start

	

setup 

	
	LDI R16, (1 << CLKPCE) // CLKP <- 0b10000000 
	STS CLKPR, R16
	LDI R16, 0b10000000
	STS CLKPR,  R16 




