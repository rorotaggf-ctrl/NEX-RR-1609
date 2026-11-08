# NEX-RR-1609 Computer

An open-source parallel 6-core RISC-V SoC designed for **Hack Club Half-Life (Week 5: Freestyle / Design Your Own Computer)**.

The project encompasses the evolution from an initial discrete 16-bit logic-gate concept (`sim_16bit`) to a verified **32-bit RISC-V (RV32I)** execution cluster (`sim`), fully mapped onto the **Sipeed Tang Nano 9K (Gowin GW1NR-9 FPGA)**. The SoC features 6 parallel RV32I cores, an 8 MB PSRAM controller, a round-robin bus arbiter, a 640x480 HDMI framebuffer, a dual PS/2 receiver, an SPI MicroSD card reader, and a digital chiptune synthesizer.

---

## Dedication: The 1609 Astronomical Revolution

> **1609: Das Fernrohr und die Astronomische Revolution**  
> Johannes Kepler veröffentlicht die *Astronomia nova* mit den ersten beiden Gesetzen der Planetenbewegung, während Galileo Galilei sein erstes astronomisches Fernrohr baut, um den Mond und die Jupitermonde zu beobachten.

---

## SoC Architecture Specifications

- **FPGA:** Sipeed Tang Nano 9K (Gowin GW1NR-LV9QN88PC6/I5).
- **Core Cluster:** 6x RV32I single-cycle execution cores running in parallel.
- **Clock Frequencies:**
  - CPU & Arbiter: **40.5 MHz** ($F_{\text{max}} = 40.76\text{ MHz}$, positive slack).
  - Video Pixel Clock: **25.2 MHz** (640x480 @ 60 Hz).
  - TMDS Serializer: **126.0 MHz** (5x Pixel Clock).
- **Memory System:** 8 MB external PSRAM arbitrated via round-robin bus controller.
- **Display Engine:** Hardware-driven 640x480 RGB565 HDMI framebuffer with direct TMDS output.
- **Audio Subsystem:** Digital chiptune audio generator embedded directly into HDMI audio data packets (48 kHz PCM stereo).
- **Peripherals:**
  - Dual PS/2 interface for keyboard and mouse.
  - SPI master interface for MicroSD card cartridges.
  - 6 on-board status LEDs.

---

## Physical Pinout Configuration (`tangnano9k.cst`)

The pins are assigned to specific FPGA pads on the Tang Nano 9K board:

### System & Clock
| Function | FPGA Pin | IO Standard | Description |
| :--- | :--- | :--- | :--- |
| `clk_27m` | 52 | LVCMOS33 | On-board 27 MHz crystal oscillator |
| `btn_rst_n` | 3 | LVCMOS18 | On-board push button S1 (Active LOW reset) |

### Status LEDs
| Function | FPGA Pin | Description |
| :--- | :--- | :--- |
| `leds[0]` | 10 | Core 0 Memory Access / Grant (Active LOW) |
| `leds[1]` | 11 | Core 1 Memory Access / Grant (Active LOW) |
| `leds[2]` | 13 | Core 2 Memory Access / Grant (Active LOW) |
| `leds[3]` | 14 | Core 3 Memory Access / Grant (Active LOW) |
| `leds[4]` | 15 | Core 4 Memory Access / Grant (Active LOW) |
| `leds[5]` | 16 | PS/2 Keyboard Scancode Ready |

### HDMI Output (Differential TMDS)
| Function | FPGA Pin (P, N) | Description |
| :--- | :--- | :--- |
| `tmds_clk_p` / `n` | 69, 68 | HDMI Pixel Clock Differential Pair |
| `tmds_d_p[0]` / `n` | 71, 70 | TMDS Channel 0 (Blue + Audio Subpackets) |
| `tmds_d_p[1]` / `n` | 73, 72 | TMDS Channel 1 (Green + Audio Guardband) |
| `tmds_d_p[2]` / `n` | 75, 74 | TMDS Channel 2 (Red) |

### MicroSD Card SPI Interface
| Function | FPGA Pin | SD Header Pin | Description |
| :--- | :--- | :--- | :--- |
| `sd_cs_n` | 38 | CS / DAT3 | Chip Select (Active LOW) |
| `sd_mosi` | 37 | DI / CMD | Master Out, Slave In |
| `sd_miso` | 36 | DO / DAT0 | Master In, Slave Out |
| `sd_sck` | 39 | CLK | SPI Clock |

### PS/2 Peripheral Interface
| Function | FPGA Pin | Description |
| :--- | :--- | :--- |
| `ps2_kbd_clk` | 25 | Keyboard Clock line (Pull-up recommended) |
| `ps2_kbd_dat` | 26 | Keyboard Data line |
| `ps2_mouse_clk` | 27 | Mouse Clock line |
| `ps2_mouse_dat` | 28 | Mouse Data line |

---

## Memory Map & I/O Registers

The system utilizes memory-mapped I/O (MMIO) to control hardware devices:

| Address Range | Type | Peripheral | Description |
| :--- | :--- | :--- | :--- |
| `0x00000000 - 0x00095FFF` | R/W | PSRAM (Framebuffer) | $640 \times 480$ 16-Bit RGB565 Pixel Buffer |
| `0x000A0000 - 0x007FFFFF` | R/W | PSRAM (General) | Main memory for external code & assets |
| `0x80000000` | W | Status LEDs | Lower 6 bits drive LEDs `leds[5:0]` |
| `0x80000004` | R | PS/2 Receiver | Bit 8: Ready flag, Bits 7:0: Scancode |
| `0x80000008` | W | Sound Generator | Bit 16: Sound Enable, Bits 15:0: Divider |
| `0x8000000C` | R/W | SPI SD Controller | Bit 8: Busy, Bits 7:0: SPI Data Byte |
| `0x80000010` | R | Core ID Register | Hardware-fixed Core Index (`0` to `5`) |

---

## Hardware Hierarchy & Schematics

### 1. Top-Level Core (`sim/cpu.dig`)
The integrated execution core connecting Program Counter, instruction memory, register file, sign-extension, ALU, and branch/jump logic.

<img width="1299" height="691" alt="cpu" src="https://github.com/user-attachments/assets/ade75cc2-da4e-4424-9605-6628e138c1db" />

### 2. Program Counter Subsystem (`sim/pc.dig`)
Handles synchronous instruction fetching with relative branch evaluation and reset states.

<img width="1265" height="655" alt="pc" src="https://github.com/user-attachments/assets/f308b397-954b-4862-83b8-fe614c6b1fc2" />

### 3. Instruction Decoder (`sim/instruction_decoder.dig`)
Splits incoming 32-bit instruction words into standard RISC-V fields (`opcode`, `rd`, `funct3`, `rs1`, `rs2`, `funct7`).

<img width="1278" height="631" alt="instruction_decoder" src="https://github.com/user-attachments/assets/43f43561-72de-4677-8841-5e8658678b1e" />

### 4. Control Unit (`sim/control_unit.dig`)
Generates synchronous datapath control lines (`RegWrite`, `ALUSrc`, `Branch`, `Jump`, `ALU_Op`, `Imm_Src`).

<img width="1302" height="656" alt="control_unit" src="https://github.com/user-attachments/assets/ff69dff3-345a-4a38-8f1f-62a0797b7b6d" />

### 5. Register File (`sim/registers.dig`)
32 general-purpose 32-bit registers with dual asynchronous read ports and a single synchronous write port with protected `$x_0 = 0$`.

<img width="1141" height="609" alt="registers" src="https://github.com/user-attachments/assets/bf6ec756-258b-4965-8ca3-6ba11b8097fb" />

### 6. Sign-Extension Unit (`sim/sign_extend.dig`)
Extracts and sign-extends immediate fields for I-Type, S-Type, and word-aligned B-Type branches.

<img width="1281" height="661" alt="sign_extend" src="https://github.com/user-attachments/assets/b251b4fd-cf0f-4a10-8ad8-1182273c3f11" />

### 7. Arithmetic Logic Unit (ALU Hierarchy)
Modular ripple-carry arithmetic logic unit constructed hierarchically:
- **1-Bit ALU Slice (`sim/alu_1bit.dig`):** Foundational adder and boolean gate slice.
- **16-Bit ALU Stage (`sim/alu_16bit.dig`):** Cascaded 1-bit units.
- **32-Bit ALU Core (`sim/alu_32bit.dig`):** Full 32-bit adder/subtractor and logic block with zero flag (`Flag_Z`).

<img width="1008" height="686" alt="alu_32bit" src="https://github.com/user-attachments/assets/1bcebabc-0b02-40f2-8254-8116cb069f82" />

---

## Build & Toolchain Workflow

### 1. Prerequisites (Ubuntu / WSL)
Install the bare-metal RISC-V cross-compiler:
```bash
sudo apt update
sudo apt install gcc-riscv64-unknown-elf
```

### 2. Software Compilation
Compiles the C firmware and audio player into a Verilog-readable initialization file:
```bash
riscv64-unknown-elf-gcc -march=rv32i -mabi=ilp32 -nostdlib -T linker.ld -O2 software/crt0.s software/main.c software/sound.c -o firmware.elf
riscv64-unknown-elf-objcopy -O verilog --verilog-data-width=4 firmware.elf rom_init.hex
```

### 3. FPGA Synthesis, PnR & Flashing
Run the open-source synthesis flow using the OSS CAD Suite:
```bash
# 1. Synthesize Verilog logic
yosys -p "read_verilog -sv hardware/*.v; synth_gowin -top top -json hardware.json"

# 2. Place & Route
nextpnr-gowin --json hardware.json --write pnr_hardware.json --device GW1NR-LV9QN88PC6/I5 --cst tangnano9k.cst

# 3. Pack bitstream
gowin_pack -d GW1N-9C -o pack.fs pnr_hardware.json

# 4. Flash to Tang Nano 9K (SRAM or On-board Flash)
openFPGALoader -b tangnano9k -f pack.fs
```

---

## Directory Organization

```text
.
├── src_verilog/
│   ├── hardware/            # Verilog HDL modules
│   │   ├── top.v            # SoC top-level interconnect
│   │   ├── cpu.v            # Synthesized RV32I processor core
│   │   ├── bus_arbiter.v    # 6-core round-robin PSRAM arbiter
│   │   ├── psram_controller.v # 8 MB QPI memory controller
│   │   ├── hdmi_framebuffer.v # 640x480 HDMI pixel engine
│   │   ├── sound_gen.v      # Square-wave chiptune synthesizer
│   │   ├── spi_sd_reader.v  # SPI master interface for MicroSD
│   │   ├── ps2_receiver.v   # Dual PS/2 keyboard & mouse receiver
│   │   └── gowin_pll.v      # System & video clock PLL
│   ├── software/            # C firmware, melodies & bootstrap
│   │   ├── main.c           # Parallel framebuffer render & event loop
│   │   ├── sound.c          # Melody player (Back in Black, Doom, etc.)
│   │   ├── sound.h          # Audio definitions
│   │   └── crt0.s           # Multi-core startup assembly & stack setup
│   ├── linker.ld            # Memory layout definition
│   ├── tangnano9k.cst       # Physical FPGA pin constraints
│   └── Makefile             # Automated one-step build script
├── sim/                     # Active 32-bit RISC-V schematics (Digital)
└── sim_16bit/               # Historical 16-bit discrete processor design
```