/*
 * ALE_ADC_lib.h
 *
 * Created: 8/05/2025 23:49:31
 *  Author: Alejandro Martinez
 */ 


#ifndef ALE_ADC_LIB_H_
#define ALE_ADC_LIB_H_


#include <stdint.h>

void adc_init(void);
uint8_t adc_read(uint8_t channel);


#endif /* ALE_ADC_LIB_H_ */