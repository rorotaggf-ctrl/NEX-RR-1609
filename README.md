# NEX-RR-1609 Computer

An open-source processor architecture designed in [Digital](https://github.com/hneemann/Digital) for **Hack Club Half-Life (Week 5: Freestyle / Design Your Own Computer)**.

The project encompasses the evolution from an initial discrete 16-bit concept (`sim_16bit`) to a fully functional, verified **32-bit RISC-V (RV32I)** single-cycle CPU (`sim`), ready for Verilog export and FPGA synthesis.

---

## Dedication: The 1609 Astronomical Revolution

> **1609: Das Fernrohr und die Astronomische Revolution**  
> Johannes Kepler veröffentlicht die *Astronomia nova* (die ersten beiden Keplerschen Gesetze der Planetenbewegung) und Galileo Galilei baut sein erstes astronomisches Fernrohr, um den Mond und die Jupiter-Monde zu beobachten.

---

## Architecture Overview (32-Bit RISC-V RV32I)

The primary processor located in `/sim` is a synchronous 32-bit RISC-V implementation adhering to standard instruction formats and hardware semantics.

- **Data & Address Width:** 32-bit synchronous data paths.
- **Instruction Memory Addressing:** Word-addressed Program Counter ($PC \leftarrow PC + 1$).
- **Register File:**
  - 32 general-purpose registers (`x0`–`x31`), each 32 bits wide.
  - Hardware hardwired constant `x0 = 0x00000000` (write-protected).
  - Dual asynchronous read ports (`Rs1`, `Rs2`) and single synchronous write port (`Rd`).
- **ALU Subsystem:**
  - Modular bit-slice design: 1-Bit ALU $\rightarrow$ 16-Bit ALU $\rightarrow$ 32-Bit ALU.
  - Hardware operations: Addition (`ADD`), Two's complement Subtraction (`SUB`), bitwise `AND`, `OR`, `XOR`, comparison checks, and `Zero`-Flag generation (`Flag_Z`).
- **Control & Immediate Logic:**
  - Dedicated `instruction_decoder` extracting `opcode`, `rd`, `funct3`, `rs1`, `rs2`, and `funct7`.
  - Hardwired `control_unit` resolving control signals for ALU, register write-enable, and branch/jump multiplexers.
  - Custom `sign_extend` unit resolving I-Type, S-Type, and B-Type immediates (calibrated to word-aligned target calculation).

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

## Repository Structure

```text
.
├── sim/                     # 32-Bit RISC-V (RV32I) Production Circuit
│   ├── cpu.dig              # Top-level integrated processor schematic
│   ├── cpu.v                # Synthesizable Verilog export for FPGA synthesis
│   ├── pc.dig               # Program Counter circuit
│   ├── registers.dig        # 32-Bit Register file (x0–x31)
│   ├── alu_32bit.dig        # 32-Bit ALU block
│   ├── alu_16bit.dig        # 16-Bit ALU block
│   ├── alu_1bit.dig         # 1-Bit ALU bit-slice
│   ├── instruction_decoder.dig # RISC-V instruction field splitter
│   ├── control_unit.dig     # Main control logic
│   └── sign_extend.dig      # Immediate extraction & sign extension logic
├── sim_16bit/               # Legacy 16-bit discrete processor design
└── README.md