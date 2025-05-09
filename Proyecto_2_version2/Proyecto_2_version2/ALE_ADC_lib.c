/*
 * ALE_ADC_lib.c
 *
 * Created: 8/05/2025 23:49:53
 *  Author: Alejandro Martínez
 */ 

#include "ALE_ADC_lib.h"
#include <avr/io.h>

void adc_init(void) {
	// Configuración del ADC:
	// - Referencia AVcc (REFS0=1)
	// - Justificado a izquierda (ADLAR=1) para leer solo ADCH
	// - Prescaler de 128 (125kHz @ 16MHz)
	ADMUX = (1 << REFS0) | (1 << ADLAR);
	
	// Habilitar ADC con prescaler de 128
	ADCSRA = (1 << ADEN) | (1 << ADPS2) | (1 << ADPS1) | (1 << ADPS0);
}

uint8_t adc_read(uint8_t channel) {
	// Seleccionar canal (0-7) manteniendo la configuración existente
	ADMUX = (ADMUX & 0xF0) | (channel & 0x07);
	
	// Iniciar conversión
	ADCSRA |= (1 << ADSC);
	
	// Esperar fin de conversión
	while (ADCSRA & (1 << ADSC));
	
	// Retornar solo ADCH (8 bits superiores, gracias a ADLAR=1)
	return ADCH;
}
