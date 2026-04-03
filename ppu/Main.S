#include <avr/io.h>

.section .text
.org 0x0000
    RJMP MAIN

.org 0x002C
    RJMP TIMER1_COMPA_ISR

MAIN:
    LDI  R16, lo8(RAMEND)                        ; Initialise stack pointers
    OUT  _SFR_IO_ADDR(SPL), R16
    LDI  R16, hi8(RAMEND)
    OUT  _SFR_IO_ADDR(SPH), R16

    LDI  R16, (1 << PORTB1)                      ; Set PORTB1 as output.
    OUT  _SFR_IO_ADDR(DDRB), R16

    LDI  R16, hi8(15624)                         ; Initialise Timer1 (1 second)
    STS  OCR1AH, R16
    LDI  R16, lo8(15624)
    STS  OCR1AL, R16
    LDI  R16, ((1 << WGM12) | (1 << CS10) | (1 << CS12))
    STS  TCCR1B, R16
    LDI  R16, (1 << OCIE1A) 
    STS  TIMSK1, R16

    SEI                                          ; Enable interrupts

MAIN_LOOP:
    RJMP MAIN_LOOP

TIMER1_COMPA_ISR:
    LDI  R16, (1 << PORTB1)
    OUT  _SFR_IO_ADDR(PORTB), R16

    RETI
