TOP       := serv_system_top
BUILD_DIR := build
LPF       := gecko5.lpf

# Path defines
SERV_SYSTEM_DIR := ../vhdl
MODULES_DIR 	:= ../../../modules

VHDL_FILES := \
	$(SERV_SYSTEM_DIR)/$(TOP).vhdl \
	$(SERV_SYSTEM_DIR)/wishBoneSharedBusTop.vhdl \
	$(SERV_SYSTEM_DIR)/picBus.vhdl \
	$(SERV_SYSTEM_DIR)/tickGenerator.vhdl \
	$(MODULES_DIR)/tickGenerator.vhdl \

JSON   := $(BUILD_DIR)/$(TOP).json
CONFIG := $(BUILD_DIR)/$(TOP).config
BIT    := $(BUILD_DIR)/$(TOP).bit

.PHONY: all synth pnr bit prog clean

all: bit

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

# 1. Analyze + Synthesize (re-runs only when VHDL_FILES change)
$(JSON): $(VHDL_FILES) | $(BUILD_DIR)
	ghdl -i --std=08 --workdir=$(BUILD_DIR) $(VHDL_FILES)
	ghdl -m --std=08 --workdir=$(BUILD_DIR) $(TOP)
	yosys -m ghdl.so -p "ghdl --std=08 --workdir=$(BUILD_DIR) $(TOP); synth_ecp5 -top $(TOP) -json $@"

# 2. Place & Route (re-runs when JSON or LPF changes)
$(CONFIG): $(JSON) $(LPF)
	nextpnr-ecp5 --threads 7 --timing-allow-fail --85k --package CABGA381 \
		--json $< --lpf $(LPF) --textcfg $@

# 3. Pack bitstream
$(BIT): $(CONFIG)
	ecppack --compress --freq 62.0 --input $< --bit $@

# Convenience targets
synth: $(JSON)
pnr:   $(CONFIG)
bit:   $(BIT)

prog: $(BIT)
	openFPGALoader $<

clean:
	rm -rf $(BUILD_DIR)