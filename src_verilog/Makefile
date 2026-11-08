# Pfade
HW_DIR = hardware
SW_DIR = software

# Software Build
firmware:
	riscv64-unknown-elf-gcc -march=rv32i -mabi=ilp32 -nostdlib -T linker.ld -O2 $(SW_DIR)/crt0.s $(SW_DIR)/main.c $(SW_DIR)/sound.c -o firmware.elf
	riscv64-unknown-elf-objcopy -O verilog --verilog-data-width=4 firmware.elf rom_init.hex

# Hardware Build
bitstream:
	yosys -p "read_verilog -sv $(HW_DIR)/*.v; synth_gowin -top top -json hardware.json"
	nextpnr-gowin --json hardware.json --write pnr_hardware.json --device GW1NR-LV9QN88PC6/I5 --cst tangnano9k.cst
	gowin_pack -d GW1N-9C -o pack.fs pnr_hardware.json

flash:
	openFPGALoader -b tangnano9k -f pack.fs

all: firmware bitstream flash