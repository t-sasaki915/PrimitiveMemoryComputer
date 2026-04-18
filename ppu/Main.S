#include <avr/io.h>

#define H_SYNC_PIN 1
#define V_SYNC_PIN 2

#define WAIT_CNT R16
#define ZERO_REG R17
#define H_SYNC_PIN_BITMASK R18
#define V_SYNC_PIN_BITMASK R19
#define LINE_CNT_L R24
#define LINE_CNT_H R25

.section .text
.ORG 0x0000
    RJMP RESET

RESET:
    CLI

    LDI  R16, 0xD8                               ; 0xD8 = CCP_IOREG_gc
    LDI  R17, 0x24                               ; 0x24 = CLKCTRL_FRQSEL_24M_gc
    OUT  CPU_CCP, R16
    STS  CLKCTRL_OSCHFCTRLA, R17

    LDI  R16, (1 << H_SYNC_PIN) | (1 << V_SYNC_PIN)
    STS  PORTD_DIR, R16
    STS  PORTD_OUT, R16

    LDI  ZERO_REG, 0
    LDI  H_SYNC_PIN_BITMASK, (1 << H_SYNC_PIN)
    LDI  V_SYNC_PIN_BITMASK, (1 << V_SYNC_PIN)

    LDI  LINE_CNT_H, hi8(525)
    LDI  LINE_CNT_L, lo8(525)

SYNC_PULSE:                                      ; --- Begin Sync Pulse ---
    STS  PORTD_OUTCLR, H_SYNC_PIN_BITMASK        ; 2 clocks

    CPI  LINE_CNT_L, 34                          ; 1 clock
    CPC  LINE_CNT_H, ZERO_REG                    ; 1 clock
    BREQ WAIT_THREE_CLOCKS_AND_SET_VSYNC_LOW     ; if LINE_CNT == 34 then 2 clocks else 1 clock.
    CPI  LINE_CNT_L, 35                          ; 1 clock
    CPC  LINE_CNT_H, ZERO_REG                    ; 1 clock
    BREQ SET_VSYNC_LOW                           ; if LINE_CNT == 35 then 2 clocks else 1 clock.

    STS  PORTD_OUTSET, V_SYNC_PIN_BITMASK        ; 2 clocks
    RJMP VSYNC_IS_SET                            ; 2 clocks

WAIT_THREE_CLOCKS_AND_SET_VSYNC_LOW:
    NOP                                          ; 1 clock
    NOP                                          ; 1 clock
    NOP                                          ; 1 clock

SET_VSYNC_LOW:
    STS  PORTD_OUTCLR, V_SYNC_PIN_BITMASK        ; 2 clocks
    NOP                                          ; 1 clock

VSYNC_IS_SET:                                    ; 12 clocks so far.
    LDI  WAIT_CNT, 24                            ; 1 clock

SYNC_PULSE_WAIT:
    DEC  WAIT_CNT                                ; 1 clock
    BRNE SYNC_PULSE_WAIT                         ; if WAIT_CNT /= 0 then 2 clocks else 1 clock.
    CPI  LINE_CNT_L, 46                          ; 1 clock
    CPC  LINE_CNT_H, ZERO_REG                    ; 1 clock
    BRSH WAIT_THREE_CLOCKS_AND_BACK_PORCH        ; 2 clocks (>= 46) / 1 clock (< 46)

    NOP                                          ; 1 clock
    JMP  VBLANK                                  ; 3 clocks

WAIT_THREE_CLOCKS_AND_BACK_PORCH:
    NOP                                          ; 1 clock
    NOP                                          ; 1 clock
    NOP                                          ; 1 clock
                                                 ; Total 91 clocks.
                                                 ; --- End Sync Pulse ---

BACK_PORCH:                                      ; --- Begin Back Porch ---
    STS  PORTD_OUTSET, H_SYNC_PIN_BITMASK        ; 2 clocks
    LDI  WAIT_CNT, 14                            ; 1 clock

BACK_PORCH_WAIT:
    DEC  WAIT_CNT                                ; 1 clock
    BRNE BACK_PORCH_WAIT                         ; 2 clocks (/= 0) / 1 clock (== 0)
    NOP                                          ; 1 clock
                                                 ; Total 45 clocks.
                                                 ; -- End Back Porch ---

ACTIVE_VIDEO:                                    ; -- Begin Active Video ---
    LDI  WAIT_CNT, 203                           ; 1 clock

ACTIVE_VIDEO_WAIT:
    DEC  WAIT_CNT                                ; 1 clock
    BRNE ACTIVE_VIDEO_WAIT                       ; 2 clocks (/= 0) / 1 clock (== 0)
    NOP                                          ; 1 clock
                                                 ; Total 610 clocks.
                                                 ; -- End Active Video ---

FRONT_PORCH:                                     ; --- Begin Front Porch ---
    SBIW LINE_CNT_L, 1                           ; 2 clocks
    NOP                                          ; 1 clock
    NOP                                          ; 1 clock
    NOP                                          ; 1 clock
    NOP                                          ; 1 clock
    NOP                                          ; 1 clock
    NOP                                          ; 1 clock
    NOP                                          ; 1 clock
    NOP                                          ; 1 clock
    NOP                                          ; 1 clock
    NOP                                          ; 1 clock
    NOP                                          ; 1 clock
    RJMP SYNC_PULSE                              ; 2 clocks
                                                 ; Total 15 clocks.
                                                 ; -- End Front Porch ---

VBLANK:
    STS  PORTD_OUTSET, H_SYNC_PIN_BITMASK        ; 2 clocks

    SBIW LINE_CNT_L, 1                           ; 2 clocks
    BREQ RESET_LINE_CNT                          ; 2 clocks (== 0) / 1 clock (/= 0)
    NOP                                          ; 1 clock
    RJMP VBLANK_CONTINUE                         ; 2 clocks

RESET_LINE_CNT:
    LDI  LINE_CNT_H, hi8(525)                    ; 1 clock
    LDI  LINE_CNT_L, lo8(525)                    ; 1 clock

VBLANK_CONTINUE:                                 ; 8 clocks so far
    LDI  WAIT_CNT, 219                           ; 1 clock

VBLANK_WAIT:
    DEC  WAIT_CNT                                ; 1 clock
    BRNE VBLANK_WAIT                             ; 2 clocks (/= 0) / 1 clock (== 0)
    NOP                                          ; 1 clock
    NOP                                          ; 1 clock
    JMP  SYNC_PULSE                              ; 3 clocks
                                                 ; Total 670 clocks.
