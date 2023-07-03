.SUFFIXES:

BUILD_NAME := $(notdir $(CURDIR))
SRC_DIR = source
CLEAN_FILES :=

LDS := gba-cart.lds
ROM := $(BUILD_NAME).gba
ELF := $(BUILD_NAME).elf
MAP := $(BUILD_NAME).map

PREFIX :=arm-none-eabi-
AS := $(PREFIX)as
LD := $(PREFIX)ld
OBJCOPY := $(PREFIX)objcopy

ASFLAGS  := -mcpu=arm7tdmi -mthumb-interwork -I include

ASM_SRCS := $(shell find $(SRC_DIR) -name *.S)
ASM_OBJS := $(ASM_SRCS:%.S=%.o)

ALL_OBJS := $(ASM_OBJS)
CLEAN_FILES += $(ALL_OBJS)

$(ROM): $(ELF)
	$(OBJCOPY) --strip-debug -O binary $< $@

$(ELF): $(ASM_OBJS) $(LDS)
	$(LD) -T $(LDS) $(ALL_OBJS) -o $@

# ASM object
%.o: %.S
	$(AS) $(ASFLAGS) $< -o $@

clean:
	rm -f $(ROM) $(ELF) $(CLEAN_FILES)

.PHONY: clean
