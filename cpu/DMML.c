#define F_CPU 24000000UL

#include <avr/io.h>
#include <util/delay.h>

void DMMLInit(void)
{
    _PROTECTED_WRITE(CLKCTRL.OSCHFCTRLA, CLKCTRL_FRQSEL_24M_gc);

    for (;;)
    {
    }
}
