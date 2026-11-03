# NEX-RR-1609 Computer

An open-source 16-bit discrete processor architecture designed from fundamental logic gates and 74xx-series components for **Hack Club Half-Life (Week 5: Freestyle / Design Your Own Computer)**.

---

## Dedication: The 1609 Astronomical Revolution

> **1609: Das Fernrohr und die Astronomische Revolution**  
> Johannes Kepler veröffentlicht die *Astronomia nova* (die ersten beiden Keplerschen Gesetze der Planetenbewegung) und Galileo Galilei baut sein erstes astronomisches Fernrohr, um den Mond und die Jupiter-Monde zu beobachten.  

---

## Architecture Specification

- **Word & Bus Width:** 16-Bit synchronous data and address paths.
- **Internal Registers:**
  - `PC` (Program Counter, 16-Bit): Instruction pointer.
  - `MAR` (Memory Address Register, 16-Bit): Memory bus addressing.
  - `R0` (Accumulator / Primary Register, 16-Bit).
  - `R1` (Auxiliary / Scratch Register, 16-Bit).
  - `FLAGS` (Status Register, 2-Bit: Zero `Z`, Carry `C`).
  - `IR` (Instruction Register, 16-Bit): Holds decoded opcode and operands.
- **ALU Operations:** 16-Bit Ripple-Carry Addition, Two's Complement Subtraction, Bitwise `AND`, `OR`, `XOR`.
- **Instruction Encoding (16-Bit Word):**
  ```text
  [ 15 ... 12 ] [ 11 ... 8 ] [ 7 ......... 0 ]
     Opcode       Register      Immediate / Addr
     (4 Bit)       (4 Bit)           (8 Bit)