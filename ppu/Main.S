#include <avr/io.h>

#define V_SYNC_PIN 1
#define H_SYNC_PIN 2

#define ZERO_REG R16
#define WAIT_CNT R17
#define LINE_OF_FONT R18
#define VERTICAL_REPEAT_FLG R19
#define FONT_BYTE R20
#define TEXT_BUFFER_ADDR_INCR_FLG R21
#define TEMP_REG R22
#define LINE_CNT_L R24
#define LINE_CNT_H R25
#define TEXT_BUFFER_ADDR_L XL
#define TEXT_BUFFER_ADDR_H XH
#define TEXT_BUFFER_ADDR X
#define FONT_BYTE_ADDR_BASE_L YL
#define FONT_BYTE_ADDR_BASE_H YH
#define FONT_BYTE_ADDR_L ZL
#define FONT_BYTE_ADDR_H ZH
#define FONT_BYTE_ADDR Z

.section .text_buffer_section, "aw", @nobits
.ORG 0x0000
TEXT_BUFFER:
    .SPACE 1140

.MACRO SLP3 n                            
    LDI  WAIT_CNT, \n
1:
    DEC  WAIT_CNT
    BRNE 1b
.ENDM

.section .text
.ORG 0x0000
    RJMP RESET

RESET:
    CLI

    LDI  R16, 0xD8                               ; 0xD8 = CCP_IOREG_gc
    LDI  R17, 0x24                               ; 0x24 = CLKCTRL_FRQSEL_24M_gc
    OUT  CPU_CCP, R16
    STS  CLKCTRL_OSCHFCTRLA, R17

    LDI  R16, (1 << H_SYNC_PIN)
    ORI  R16, (1 << V_SYNC_PIN)
    STS  PORTD_DIR, R16
    STS  PORTD_OUT, R16

    LDI  R16, PIN4_bm
    ORI  R16, PIN6_bm
    ORI  R16, PIN7_bm
    STS  PORTA_DIR, R16

    LDI  R16, SPI_MASTER_bm
    ORI  R16, SPI_ENABLE_bm
    ORI  R16, SPI_CLK2X_bm
    STS  SPI0_CTRLA, R16

    LDI  R16, SPI_SSD_bm
    STS  SPI0_CTRLB, R16

    LDI  R16, 0x80
    STS  PORTA_PIN4CTRL, R16

GENERATE_TEST_TEXT_BUFFER:
    LDI  ZH, hi8(TEXT_BUFFER)
    LDI  ZL, lo8(TEXT_BUFFER)
    LDI  XH, hi8(1140)                           ; 38x30
    LDI  XL, lo8(1140)
    LDI  R16, 0

GENERATE_TEST_TEXT_BUFFER_LOOP:
    ST   Z+, R16

    INC  R16
    CPI  R16, 3
    BRNE GENERATE_TEST_TEXT_BUFFER_CONTINUE
    LDI  R16, 0

GENERATE_TEST_TEXT_BUFFER_CONTINUE:
    SBIW XL, 1
    BRNE GENERATE_TEST_TEXT_BUFFER_LOOP

RESET_CONTINUE:
    LDI  ZERO_REG, 0
    LDI  WAIT_CNT, 0
    LDI  LINE_OF_FONT, 0
    LDI  VERTICAL_REPEAT_FLG, 1
    LDI  FONT_BYTE, 0
    LDI  TEXT_BUFFER_ADDR_INCR_FLG, 0
    LDI  TEMP_REG, 0
    LDI  LINE_CNT_H, hi8(525)
    LDI  LINE_CNT_L, lo8(525)
    LDI  TEXT_BUFFER_ADDR_H, hi8(TEXT_BUFFER)
    LDI  TEXT_BUFFER_ADDR_L, lo8(TEXT_BUFFER)
    LDI  FONT_BYTE_ADDR_BASE_H, hi8(0)
    LDI  FONT_BYTE_ADDR_BASE_L, lo8(0)
    LDI  FONT_BYTE_ADDR_H, hi8(0)
    LDI  FONT_BYTE_ADDR_L, lo8(0)

SYNC_PULSE:                                      ; --- Begin Sync Pulse ---
    CBI  VPORTD_OUT, H_SYNC_PIN                  ; 1 clock

    CPI  LINE_CNT_L, 34                          ; 1 clock
    CPC  LINE_CNT_H, ZERO_REG                    ; 1 clock
    BREQ WAIT_THREE_CLOCKS_AND_SET_VSYNC_LOW     ; 2 clocks (== 34) / 1 clock (/= 34)
    CPI  LINE_CNT_L, 35                          ; 1 clock
    CPC  LINE_CNT_H, ZERO_REG                    ; 1 clock
    BREQ SET_VSYNC_LOW                           ; 2 clocks (== 35) / 1 clock (/= 35)

    SBI  VPORTD_OUT, V_SYNC_PIN                  ; 1 clock
    RJMP VSYNC_IS_SET                            ; 2 clocks

WAIT_THREE_CLOCKS_AND_SET_VSYNC_LOW:
    NOP                                          ; 1 clock
    NOP                                          ; 1 clock
    NOP                                          ; 1 clock

SET_VSYNC_LOW:
    CBI  VPORTD_OUT, V_SYNC_PIN                  ; 1 clock
    NOP                                          ; 1 clock

VSYNC_IS_SET:                                    ; 10 clocks so far.
    SLP3 27                                      ; 81 clocks
    NOP                                          ; 1 clock
                                                 ; Total 92 clocks.
                                                 ; --- End Sync Pulse ---

.MACRO LOAD_FONT_BYTE                            ; 11 clocks
    LD   FONT_BYTE_ADDR_L, TEXT_BUFFER_ADDR+     ; 2 clocks
    MUL  FONT_BYTE_ADDR_L, TEMP_REG              ; 2 clocks
    MOVW FONT_BYTE_ADDR_L, R0                    ; 1 clock

    ADD  FONT_BYTE_ADDR_L, FONT_BYTE_ADDR_BASE_L ; 1 clock 
    ADC  FONT_BYTE_ADDR_H, FONT_BYTE_ADDR_BASE_H ; 1 clock

    LPM  FONT_BYTE, FONT_BYTE_ADDR               ; 3 clocks
    COM  FONT_BYTE                               ; 1 clock
.ENDM

BACK_PORCH:                                      ; --- Begin Back Porch ---
    SBI  VPORTD_OUT, H_SYNC_PIN                  ; 1 clock

    TST  TEXT_BUFFER_ADDR_INCR_FLG               ; 1 clock
    BREQ SKIP_TEXT_BUFFER_ADDR_INCR_AND_CONTINUE ; 2 clocks (== 0) / 1 clock (== 1)

    TST  VERTICAL_REPEAT_FLG                     ; 1 clock
    BRNE VERTICAL_REPEAT                         ; 2 clocks (== 1) / 1 clock (== 0)

    LDI  VERTICAL_REPEAT_FLG, 1                  ; 1 clock

    INC  LINE_OF_FONT                            ; 1 clock
    CPI  LINE_OF_FONT, 8                         ; 1 clock
    BRNE LINE_OF_FONT_IS_NOT_EIGHT               ; 2 clocks (/= 8) / 1 clock (== 8)

    LDI  LINE_OF_FONT, 0                         ; 1 clock
    RJMP BACK_PORCH_CONTINUE                     ; 2 clocks

SKIP_TEXT_BUFFER_ADDR_INCR_AND_CONTINUE:
    LDI  TEXT_BUFFER_ADDR_INCR_FLG, 1            ; 1 clock
    NOP                                          ; 1 clock
    NOP                                          ; 1 clock
    NOP                                          ; 1 clock
    NOP                                          ; 1 clock
    NOP                                          ; 1 clock
    RJMP BACK_PORCH_CONTINUE                     ; 2 clocks

VERTICAL_REPEAT:
    LDI  VERTICAL_REPEAT_FLG, 0                  ; 1 clock
    NOP                                          ; 1 clock
    NOP                                          ; 1 clock
    NOP                                          ; 1 clock
    RJMP BACK_PORCH_CONTINUE                     ; 2 clocks

LINE_OF_FONT_IS_NOT_EIGHT:
    SUBI TEXT_BUFFER_ADDR_L, 33                  ; 1 clock
    SBCI TEXT_BUFFER_ADDR_H, 0                   ; 1 clock

BACK_PORCH_CONTINUE:                             ; 12 clocks so far
    LDI  FONT_BYTE_ADDR_BASE_L, lo8(FONT_DATA)   ; 1 clock
    LDI  FONT_BYTE_ADDR_BASE_H, hi8(FONT_DATA)   ; 1 clock
    ADD  FONT_BYTE_ADDR_BASE_L, LINE_OF_FONT     ; 1 clock
    ADC  FONT_BYTE_ADDR_BASE_H, ZERO_REG         ; 1 clock

    LDI  TEMP_REG, 8                             ; 1 clock

    LOAD_FONT_BYTE                               ; 11 clocks

    SLP3 6                                       ; 18 clocks
                                                 ; Total 46 clocks.
                                                 ; -- End Back Porch ---

.MACRO TEMP_MACRO                                ; 18 clocks
    LOAD_FONT_BYTE                               ; 11 clocks
    NOP                                          ; 1 clock
    NOP                                          ; 1 clock
    NOP                                          ; 1 clock
    NOP                                          ; 1 clock
    NOP                                          ; 1 clock
    STS  SPI0_DATA, FONT_BYTE                    ; 2 clocks
.ENDM

ACTIVE_VIDEO:                                    ; -- Begin Active Video ---
    STS  SPI0_DATA, FONT_BYTE                    ; 2 clocks
    TEMP_MACRO                                   ; 18 clocks
    TEMP_MACRO                                   ; 18 clocks
    TEMP_MACRO                                   ; 18 clocks
    TEMP_MACRO                                   ; 18 clocks
    TEMP_MACRO                                   ; 18 clocks
    TEMP_MACRO                                   ; 18 clocks
    TEMP_MACRO                                   ; 18 clocks
    TEMP_MACRO                                   ; 18 clocks
    TEMP_MACRO                                   ; 18 clocks
    TEMP_MACRO                                   ; 18 clocks
    TEMP_MACRO                                   ; 18 clocks
    TEMP_MACRO                                   ; 18 clocks
    TEMP_MACRO                                   ; 18 clocks
    TEMP_MACRO                                   ; 18 clocks
    TEMP_MACRO                                   ; 18 clocks
    TEMP_MACRO                                   ; 18 clocks
    TEMP_MACRO                                   ; 18 clocks
    TEMP_MACRO                                   ; 18 clocks
    TEMP_MACRO                                   ; 18 clocks
    TEMP_MACRO                                   ; 18 clocks
    TEMP_MACRO                                   ; 18 clocks
    TEMP_MACRO                                   ; 18 clocks
    TEMP_MACRO                                   ; 18 clocks
    TEMP_MACRO                                   ; 18 clocks
    TEMP_MACRO                                   ; 18 clocks
    TEMP_MACRO                                   ; 18 clocks
    TEMP_MACRO                                   ; 18 clocks
    TEMP_MACRO                                   ; 18 clocks
    TEMP_MACRO                                   ; 18 clocks
    TEMP_MACRO                                   ; 18 clocks
    TEMP_MACRO                                   ; 18 clocks
    TEMP_MACRO                                   ; 18 clocks
    
    SLP3 10                                      ; 30 clocks
    NOP                                          ; 1 clock
    NOP                                          ; 1 clock
                                                 ; Total 610 clocks.
                                                 ; -- End Active Video ---

FRONT_PORCH:                                     ; --- Begin Front Porch ---
    SBIW LINE_CNT_L, 1                           ; 2 clocks
    BREQ RESET_LINE_CNT                          ; 2 clocks (== 0) / 1 clock (/= 0)
    NOP                                          ; 1 clock
    NOP                                          ; 1 clock
    NOP                                          ; 1 clock
    NOP                                          ; 1 clock
    NOP                                          ; 1 clock
    NOP                                          ; 1 clock
    RJMP FRONT_PORCH_CONTINUE                    ; 2 clocks

RESET_LINE_CNT:
    LDI  LINE_CNT_H, hi8(525)                    ; 1 clock
    LDI  LINE_CNT_L, lo8(525)                    ; 1 clock
    LDI  TEXT_BUFFER_ADDR_H, hi8(TEXT_BUFFER)    ; 1 clock
    LDI  TEXT_BUFFER_ADDR_L, lo8(TEXT_BUFFER)    ; 1 clock
    LDI  LINE_OF_FONT, 0                         ; 1 clock
    LDI  TEXT_BUFFER_ADDR_INCR_FLG, 0            ; 1 clock
    LDI  VERTICAL_REPEAT_FLG, 1                  ; 1 clock

FRONT_PORCH_CONTINUE:                            ; 11 clocks so far
    NOP                                          ; 1 clock
    NOP                                          ; 1 clock
    RJMP SYNC_PULSE                              ; 2 clock
                                                 ; Total 15 clocks.
                                                 ; -- End Front Porch ---

#include "Font.S"
