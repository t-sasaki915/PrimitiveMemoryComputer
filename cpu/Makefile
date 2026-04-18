MCU = avr128db28

PROGRAMMER = serialupdi
PROGRAMMER_PORT = COM9

CC = avr-gcc
OBJCOPY = avr-objcopy
AVRDUDE = avrdude

CFLAGS = -Wall -Wextra -Wpedantic -Os -mmcu=$(MCU)
LDFLAGS = -Wl,-Ttext=0x0000

all: Main.hex Main.S DMML.c

Main.elf: Main.S DMML.c
	$(CC) $(CFLAGS) $(LDFLAGS) -nostartfiles -o Main.elf Main.S DMML.c

Main.hex: Main.elf
	$(OBJCOPY) -O ihex -R .eeprom Main.elf Main.hex

flash: Main.hex
	$(AVRDUDE) -c $(PROGRAMMER) -p $(MCU) -P ${PROGRAMMER_PORT} -U flash:w:Main.hex:i

clean:
	del Main.elf Main.hex
