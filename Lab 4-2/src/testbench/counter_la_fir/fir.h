#ifndef __FIR_H__
#define __FIR_H__

#define N 11
#define data_length 64

// Project FIR Base Address
#define reg_fir_control        (*(volatile uint32_t*) 0x30000000)
#define reg_fir_data_length    (*(volatile uint32_t*) 0x30000010)
#define reg_fir_tap_num        (*(volatile uint32_t*) 0x30000014)
#define reg_fir_x              (*(volatile uint32_t*) 0x30000040)
#define reg_fir_y              (*(volatile uint32_t*) 0x30000044)
#define reg_fir_coeff(i)       (*(volatile uint32_t*) (0x30000080 + (i <<2)))

int taps[N] = {0,-10,-9,23,56,63,56,23,-9,-10,0};
int outputsignal[data_length];
#endif
