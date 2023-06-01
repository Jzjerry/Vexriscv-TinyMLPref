SRC_DIR = src
MODEL_DIR = $(SRC_DIR)/models
TF_DIR = $(SRC_DIR)/tensorflow
THIRD_PARTY_DIR = $(SRC_DIR)/third_party

MARCH := rv32i
ifeq ($(MULDIV),yes)
	MARCH := $(MARCH)m
endif
ifeq ($(COMPRESSED),yes)
	MARCH := $(MARCH)c
endif

OUTFLAG = -o
CC 		= riscv64-unknown-elf-gcc
LD		= riscv64-unknown-elf-g++
OBJ_DUMP = riscv64-unknown-elf-objdump
OBJ_COPY = riscv64-unknown-elf-objcopy
RISCV_PATH=~/riscv64-unknown-elf-gcc-10.1.0-2020.08.2-x86_64-linux-ubuntu14/
RISCV_CLIB=$(RISCV_PATH)/riscv64-unknown-elf/lib/rv32i/ilp32
AS		= riscv64-unknown-elf-as
PORT_CFLAGS = -O3 -g
FLAGS_STR = "$(PORT_CFLAGS) $(XCFLAGS) $(XLFLAGS) $(LFLAGS_END)"


THIRD_PARTY_INCLUDES = -I$(THIRD_PARTY_DIR)/kissfft -I$(THIRD_PARTY_DIR)/kissfft/tools \
	-I$(THIRD_PARTY_DIR)/flatbuffers/include -I$(THIRD_PARTY_DIR)/gemmlowp \
	-I$(THIRD_PARTY_DIR)/ruy
INCLUDE_FLAGS = -I$(SRC_DIR)/ -I. $(THIRD_PARTY_INCLUDES)

TF_FLAGS = -D__ZEPHYR__

CFLAGS = $(PORT_CFLAGS) $(INCLUDE_FLAGS) $(TF_FLAGS) -DFLAGS_STR=\"$(FLAGS_STR)\"  -march=$(MARCH) -mabi=ilp32 -lgcc  -lc -nostartfiles -ffreestanding -Wl,-Bstatic,-T,$(SRC_DIR)/ram.ld,-Map,tflitemicro.map,--print-memory-usage
OBJOUT 	= -o
LFLAGS 	= -march=$(MARCH) -mabi=ilp32  -lgcc -lc -lm -lstdc++ -nostartfiles -ffreestanding -Wl,-Bstatic,-T,$(SRC_DIR)/ram.ld,-Map,tflitemicro.map,--print-memory-usage,--gc-sections
ASFLAGS = -march=$(MARCH) -mabi=ilp32
OFLAG 	= -o
COUT 	= -c

BUILD_DIR = build

C_SOURCES = $(shell find $(SRC_DIR) -type f -name "*.c")
CPP_SOURCES = $(shell find $(SRC_DIR) -type f -name "*.cc")
ASM_SOURCES = $(shell find $(SRC_DIR) -type f -name "*.s")
C_OBJS = $(patsubst $(SRC_DIR)/%.c, $(BUILD_DIR)/$(MARCH)/%.o, $(C_SOURCES))
CPP_OBJS = $(patsubst $(SRC_DIR)/%.cc, $(BUILD_DIR)/$(MARCH)/%.o, $(CPP_SOURCES))
ASM_OBJS = $(patsubst $(SRC_DIR)/%.s, $(BUILD_DIR)/$(MARCH)/%.o, $(ASM_SOURCES))

CFLAGS += -DBENCHMARK_$(BENCH)

TARGET = tflite_$(BENCH)
TARGET := $(TARGET)_$(MARCH)

all: $(BUILD_DIR)/$(TARGET).elf $(BUILD_DIR)/$(TARGET).hex $(BUILD_DIR)/$(TARGET).asm

$(BUILD_DIR)/$(TARGET).elf: $(C_OBJS) $(CPP_OBJS) $(ASM_OBJS)
	$(LD) $(LFLAGS) $(C_OBJS) $(CPP_OBJS) $(ASM_OBJS) -o $@

$(BUILD_DIR)/$(MARCH)/%.o: $(SRC_DIR)/%.c
	mkdir -p $(dir $@)
	$(CC) $(CFLAGS) -c $< -o $@

$(BUILD_DIR)/$(MARCH)/%.o: $(SRC_DIR)/%.cc
	mkdir -p $(dir $@)
	$(CC) $(CFLAGS) -c $< -o $@

$(BUILD_DIR)/$(MARCH)/%.o: $(SRC_DIR)/%.s
	mkdir -p $(dir $@)
	$(AS) $(ASFLAGS) $< $(OBJOUT) $@

%.hex: %.elf
	$(OBJ_COPY) -O ihex $^ $@

%.bin: %.elf
	$(OBJ_COPY) -O binary $^ $@

%.v: %.elf
	$(OBJ_COPY) -O verilog $^ $@

%.asm: %.elf
	$(OBJ_DUMP) -S -d $^ > $@

clean:
	rm -rf $(BUILD_DIR) tflitemicro.map

echo:
	@echo $(C_OBJS)

.PHONY: all clean