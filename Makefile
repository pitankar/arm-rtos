# Replace the Project name
PROJECT = Blink
ARM_CC = /home/installation/arm/bin/

# ICDI port
ICDI    = /dev/ttyACM0

# Source code related information
SOURCE  = ./src/
INCLUDE = ./inc/
LINKER_SCRIPT = ./.msc/scatter.ld
FLASH   = ./.msc/lm4flash.c
FLASH_TOOL = lm4flash
ARM_GDB = /home/installation/arm/bin/arm-none-eabi-gdb


# Part specific information
PART    ?= TM4C123GH6PM
TARGET  ?= TM4C123_RB1
CFLAGS  ?= -mthumb -mcpu=cortex-m4 -mfpu=fpv4-sp-d16 -mfloat-abi=softfp -ffunction-sections -fdata-sections -std=c99 -g -Os -Wall 
LDFLAGS ?= --gc-sections

# Flags
LIBGCC  := ${shell $(ARM_CC)arm-none-eabi-gcc ${CFLAGS} -print-libgcc-file-name}
LIBC    := ${shell $(ARM_CC)arm-none-eabi-gcc ${CFLAGS} -print-file-name=libc.a}
LIBM    := ${shell $(ARM_CC)arm-none-eabi-gcc ${CFLAGS} -print-file-name=libm.a}

.PHONY: all clean

all: $(PROJECT).axf

clean:
	@echo "Cleaning the Source code ..."
	@rm -rf ./*/*.d ./*/*.o *.axf
	@echo "Done! :) "

$(PROJECT).axf: $(patsubst %.c, %.o, $(wildcard $(SOURCE)*.c))
	@echo "Compiling the source ..."
	@$(ARM_CC)arm-none-eabi-ld ${LDFLAGS} -T $(LINKER_SCRIPT) --entry ResetIntHandler -o $@ $^ ${LIBGCC} ${LIBC} ${LIBM}
	@echo "Doing some house keeping ..."
	@rm -rf ./*/*.d ./*/*.o
	@echo "Generated Output: ./$(PROJECT).axf"
	@echo "Done! :)"

-include $(wildcard *.d)

%.o: %.c
	@$(ARM_CC)arm-none-eabi-gcc ${CFLAGS} -I$(INCLUDE) -Dgcc -DPART_${PART} -DTARGET_IS_${TARGET} -DUART_BUFFERED -MD -c -o $@ $<
	
flash: $(PROJECT).axf
	@echo "Building the flash tool ..."
	@gcc -Wall $(shell pkg-config --cflags libusb-1.0) $(FLASH) $(shell pkg-config --libs libusb-1.0) -o $(FLASH_TOOL)
	@echo "Uploading the Binary to the Board ..."
	@./$(FLASH_TOOL) -E -S $(ICDI) $(PROJECT).axf
	@echo "Removing the flash tool"
	@rm -rf $(FLASH_TOOL)
	@echo "Done! :)"

openocd: $(PROJECT).axf
	openocd --file /usr/local/share/openocd/scripts/board/ek-lm4f120xl.cfg

gdb: $(PROJECT).axf
	$(ARM_GDB) $(PROJECT).axf
