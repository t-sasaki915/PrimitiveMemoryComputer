#define F_CPU 24000000UL

#include <avr/io.h>
#include <util/delay.h>

void VGAInit(void)
{
    /*
    水平同期信号

    640x480@60Hzでは、ピクセルクロックは25.175MHz、合計水平ピクセルは640+16+96+48=800ピクセルです。
    この装置は24MHz駆動ですから、(1/(24*10^6))*x=(1/(25.175*10^6))*800を解く必要があります。
    VGA信号において負の誤差はモニター側で吸収されやすいので、小数点以下切り捨てを行います。つまり、x≈762です。
    したがって、周期は762クロックにするのが妥当です。

    水平ピクセルのうち同期パルスは96ピクセルです。
    24MHzでは、(1/(24*10^6))*x=(1/(25.175*10^6))*96、x≈91クロックです。

    TCA0の設定においては、カウントは0からスタートするので-1が必要です。
    CMP0には、762クロックのうちLOWではない区間、つまり762-91を設定します。
    */
    TCA0.SINGLE.PER = 762 - 1;
    TCA0.SINGLE.CMP0 = 762 - 91;

    TCA0.SINGLE.CTRLB = TCA_SINGLE_WGMODE_SINGLESLOPE_gc | TCA_SINGLE_CMP0EN_bm;
    TCA0.SINGLE.CTRLA = TCA_SINGLE_CLKSEL_DIV1_gc | TCA_SINGLE_ENABLE_bm;

    EVSYS.CHANNEL0 = EVSYS_CHANNEL0_TCA0_OVF_LUNF_gc;
    EVSYS.USERTCB1CAPT = EVSYS_USER_CHANNEL0_gc;

    TCB0.CCMP = 525; // TODO

    TCB0.CTRLB = TCB_CNTMODE_PWM8_gc | TCB_CCMPEN_bm;
    TCB0.CTRLA = TCB_CLKSEL_EVENT_gc | TCB_ENABLE_bm;
}

void DMMLInit(void)
{
    _PROTECTED_WRITE(CLKCTRL.OSCHFCTRLA, CLKCTRL_FRQSEL_24M_gc);

    PORTMUX.TCAROUTEA = 0x2;
    PORTC.DIRSET = PIN0_bm;
    PORTA.DIRSET = PIN2_bm;

    VGAInit();

    for (;;)
    {
    }
}
