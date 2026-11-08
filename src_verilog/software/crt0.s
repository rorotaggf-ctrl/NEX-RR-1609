.section .text.init
.globl _start

_start:
    # Core ID lesen (z. B. aus Register oder MMIO)
    li t0, 0x80000010
    lw t1, 0(t0)            # t1 = core_id (0..5)

    # Separater 1-KB-Stack pro Kern im oberen RAM-Bereich (ab 0x000F0000)
    li t2, 0x000F0000
    slli t3, t1, 10         # t3 = core_id * 1024
    sub sp, t2, t3          # sp = Stack-Spitze fuer diesen Kern

    # Sprung in die C-Hauptfunktion
    call main

hang:
    j hang
