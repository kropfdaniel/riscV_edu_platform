CC      = riscv64-unknown-elf-gcc
OBJCOPY = riscv64-unknown-elf-objcopy
CFLAGS  = -march=rv32i_zicsr -mabi=ilp32 -O2 -ffreestanding -nostartfiles -nostdlib -T linker.ld

all: firmware_pkg.vhdl firmware_sim_pkg.vhdl

firmware.elf: start.S main.c linker.ld
	$(CC) $(CFLAGS) start.S main.c -o $@

firmware_sim.elf: start.S main.c linker.ld
	$(CC) $(CFLAGS) -DSIM start.S main.c -o $@

%.bin: %.elf
	$(OBJCOPY) -O binary $< $@

%_pkg.vhdl: %.bin generate_rom.py
	python3 generate_rom.py $< $@

clean:
	rm -f firmware.elf firmware.bin firmware_pkg.vhdl \
	      firmware_sim.elf firmware_sim.bin firmware_sim_pkg.vhdl

.PHONY: all clean