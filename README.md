# NEX-RR-1609 Computer

An open-source parallel 6-core processor system designed for **Hack Club Half-Life (Week 5: Freestyle / Design Your Own Computer)**.

The project encompasses the evolution from an initial discrete 16-bit concept (`sim_16bit`) to a verified **32-bit RISC-V (RV32I)** architecture (`sim`), scaled into a multi-core SoC on the **Sipeed Tang Nano 9K (Gowin GW1NR-9 FPGA)** running alongside a custom memory-mapped PSRAM controller, round-robin bus arbiter, dual PS/2 receiver, HDMI framebuffer, and sound generator.

---

## Historic Fun Fact & Dedication: The Year 1609

> **1609: The Telescope & The Astronomical Revolution**  
> Johannes Kepler published *Astronomia nova*, establishing his first two laws of planetary motion, while Galileo Galilei built his first astronomical telescope to observe the Moon and the moons of Jupiter.

---

## Hardware Architecture & SoC Specifications

- **Target FPGA:** Sipeed Tang Nano 9K (Gowin GW1NR-LV9QN88PC6/I5).
- **Compute Cluster:** 6x RV32I RISC-V single-cycle cores running in parallel.
- **Clock Domain:** 40.5 MHz system clock with positive slack ($F_{\text{max}} \approx 40.76\text{ MHz}$).
- **Video Subsystem:** 640x480 @ 60 Hz RGB565 HDMI output driven by a custom hardware framebuffer.
- **Memory:** 8 MB external PSRAM managed via a round-robin hardware arbiter.
- **Audio:** Custom square-wave chiptune synthesizer routed through HDMI audio packets.
- **Peripherals:** Dual PS/2 interface (keyboard and mouse) and high-speed SPI MicroSD card reader.

---

## FPGA Pinout Configuration (`tangnano9k.cst`)

The following physical pin assignments are configured for the Tang Nano 9K:

### System & Clock
| Function | FPGA Pin | IO Standard | Notes |
| :--- | :--- | :--- | :--- |
| `clk_27m` | 52 | LVCMOS33 | On-board 27 MHz crystal |
| `btn_rst_n` | 3 | LVCMOS18 | On-board user button S1 (Active LOW) |

### Status LEDs
| Function | FPGA Pin | Description |
| :--- | :--- | :--- |
| `leds[0]` | 10 | Core 0 Bus Grant / Activity (Active LOW) |
| `leds[1]` | 11 | Core 1 Bus Grant / Activity (Active LOW) |
| `leds[2]` | 13 | Core 2 Bus Grant / Activity (Active LOW) |
| `leds[3]` | 14 | Core 3 Bus Grant / Activity (Active LOW) |
| `leds[4]` | 15 | Core 4 Bus Grant / Activity (Active LOW) |
| `leds[5]` | 16 | PS/2 Keyboard Data Ready / Activity |

### HDMI Output (Differential TMDS)
| Function | FPGA Pin | Notes |
| :--- | :--- | :--- |
| `tmds_clk_p` / `n` | 69, 68 | HDMI Pixel Clock Differential Pair |
| `tmds_d_p[0]` / `n` | 71, 70 | Blue / Audio Subpackets |
| `tmds_d_p[1]` / `n` | 73, 72 | Green / Guard Band |
| `tmds_d_p[2]` / `n` | 75, 74 | Red |

### MicroSD Card SPI Interface
| Function | FPGA Pin | SD Pin | Notes |
| :--- | :--- | :--- | :--- |
| `sd_cs_n` | 38 | CS / DAT3 | Chip Select (Active LOW) |
| `sd_mosi` | 37 | DI / CMD | Master Out, Slave In |
| `sd_miso` | 36 | DO / DAT0 | Master In, Slave Out (Pulled up) |
| `sd_sck` | 39 | CLK | SPI Clock |

### PS/2 Input Interface
| Function | FPGA Pin | Notes |
| :--- | :--- | :--- |
| `ps2_kbd_clk` | 25 | Keyboard Clock Line |
| `ps2_kbd_dat` | 26 | Keyboard Data Line |
| `ps2_mouse_clk` | 27 | Mouse Clock Line |
| `ps2_mouse_dat` | 28 | Mouse Data Line |

---

## Memory-Mapped I/O (MMIO) Registers

| Address | Mode | Description |
| :--- | :--- | :--- |
| `0x00000000 - 0x00095FFF` | R/W | 640x480 RGB565 Framebuffer (PSRAM) |
| `0x80000000` | W | On-board Status LEDs (Bits 5:0) |
| `0x80000004` | R | PS/2 Keyboard (Bit 8: Data Ready, Bits 7:0: Scancode) |
| `0x80000008` | W | Sound Generator (Bit 16: Enable, Bits 15:0: Clock Divider) |
| `0x80000010` | R | Core Hardware ID (`0` to `5`) |

---

## Schematic Walkthrough

### 1. Top-Level CPU (`cpu.dig`)
The integrated processing core combining PC, Program ROM, instruction decode, register file, sign extension, ALU, and branch/jump control logic.

<img width="1299" height="691" alt="cpu" src="https://github.com/user-attachments/assets/ade75cc2-da4e-4424-9605-6628e138c1db" />

---

### 2. Program Counter Subsystem (`pc.dig`)
Handles synchronous instruction fetching with direct jump/branch target loading.
- Inputs: `Load`, `CLR`, `CLK`, `JumpTarget` [31:0].
- Features synchronous loading on evaluated branch conditions and reset logic.

<img width="1265" height="655" alt="pc" src="https://github.com/user-attachments/assets/f308b397-954b-4862-83b8-fe614c6b1fc2" />

---

### 3. Instruction Decoder (`instruction_decoder.dig`)
Splits the 32-bit instruction word from the ROM into standard RISC-V fields.

<img width="1278" height="631" alt="instruction_decoder" src="https://github.com/user-attachments/assets/43f43561-72de-4677-8841-5e8658678b1e" />

---

### 4. Control Unit (`control_unit.dig`)
Decodes instruction opcodes and function fields to generate synchronous control signals (`RegWrite`, `ALUSrc`, `Branch`, `Jump`, `ALU_Op`, `Imm_Src`).

<img width="1302" height="656" alt="control_unit" src="https://github.com/user-attachments/assets/ff69dff3-345a-4a38-8f1f-62a0797b7b6d" />

---

### 5. Register File (`registers.dig`)
32-register dual-read, single-write storage block. Enforces standard RISC-V zero-register behavior on `x0`.

<img width="1141" height="609" alt="registers" src="https://github.com/user-attachments/assets/bf6ec756-258b-4965-8ca3-6ba11b8097fb" />

---

### 6. Sign-Extension Unit (`sign_extend.dig`)
Dynamically constructs sign-extended 32-bit immediate values from instruction bitfields:
- **I-Type:** Arithmetic and immediate loads.
- **S-Type:** Store instruction address offsets.
- **B-Type:** Reassembles scrambled branch bits ($Imm[12\vert{}11\vert{}10:5\vert{}4:1]$) and aligns them to word-offset targets for relative branching.

<img width="1281" height="661" alt="sign_extend" src="https://github.com/user-attachments/assets/b251b4fd-cf0f-4a10-8ad8-1182273c3f11" />

---

### 7. Arithmetic Logic Unit (ALU Hierarchy)

#### 1-Bit ALU Slice (`alu_1bit.dig`)
Fundamental slice executing 1-bit full addition, subtraction borrow logic, and bitwise boolean gates.

<img width="1303" height="632" alt="alu_1bit" src="https://github.com/user-attachments/assets/1d623d19-8ce8-4c5e-b986-13d5bd259008" />

#### 16-Bit ALU Stage (`alu_16bit.dig`)
Chains 1-bit slices with ripple-carry interconnects.

<img width="786" height="1254" alt="alu_16bit" src="https://github.com/user-attachments/assets/af2c00ed-c886-4cfd-adf1-7f3206249dcf" />

#### 32-Bit ALU Core (`alu_32bit.dig`)
Dual 16-bit blocks combined to produce full 32-bit results alongside condition indicators (`Flag_Z` / Zero detection).

<img width="1008" height="686" alt="alu_32bit" src="https://github.com/user-attachments/assets/1bcebabc-0b02-40f2-8254-8116cb069f82" />

---

## Toolchain & Build Instructions

### Prerequisites
Install the bare-metal RISC-V cross-compiler:
```bash
sudo apt update
sudo apt install gcc-riscv64-unknown-elf