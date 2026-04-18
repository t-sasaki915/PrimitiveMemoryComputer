#include <avr/io.h>

.extern DMMLInit

.section .text
.ORG 0x0000
    RJMP RESET

RESET:
    CALL DMMLInit
