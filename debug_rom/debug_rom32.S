# This code should be functional. Doesn't have to be optimal.
# I'm writing it to prove that it can be done.

#include "riscv/encoding.h"

# TODO: Update these constants once they're finalized in the doc.

#define DEBUG_RAM               0x400
#define DEBUG_RAM_SIZE          28

#define CLEARDEBINT             0x100
#define SETHALTNOT              0x10c

        .global entry
        .global resume
        .global exception

        # Automatically called when Debug Mode is first entered.
entry:  j       _entry
        # Should be called by Debug RAM code that has finished execution and
        # wants to return to Debug Mode.
resume:
        j       _resume
exception:
        # Set the last word of Debug RAM to all ones, to indicate that we hit
        # an exception.
        li      s0, ~0
        j       _resume2

_resume:
        li      s0, 0
_resume2:
        fence

        # Restore s1.
        lw      s1, (DEBUG_RAM + DEBUG_RAM_SIZE - 4)(zero)

        # s0 contains ~0 if we got here through an exception, and 0 otherwise.
        # Store this to the last word in Debug RAM so the debugger can tell if
        # an exception occurred.
        sw      s0, (DEBUG_RAM + DEBUG_RAM_SIZE - 4)(zero)

        # Clear debug interrupt.
        csrr    s0, CSR_MHARTID
        sw      s0, CLEARDEBINT(zero)

check_halt:
        csrr    s0, CSR_DCSR
        andi    s0, s0, DCSR_HALT
        beqz    s0, exit
        j       wait_for_interrupt

exit:
        # Restore s0.
        csrr    s0, CSR_DSCRATCH
        dret

_entry:
        # Save s0 in DSCRATCH
        csrw    CSR_DSCRATCH, s0

        # Check why we're here
        csrr    s0, CSR_DCSR
        # cause is in bits 8:6 of dcsr
        andi    s0, s0, DCSR_CAUSE
        addi    s0, s0, -(DCSR_CAUSE_DEBUGINT<<6)
        bnez    s0, spontaneous_halt

jdebugram:
        # Save s1 so that the debug program can use two registers.
        fence.i
        sw      s1, (DEBUG_RAM + DEBUG_RAM_SIZE - 4)(zero)
        jr      zero, DEBUG_RAM

spontaneous_halt:
        csrr    s0, CSR_MHARTID
        sw      s0, SETHALTNOT(zero)
        csrsi   CSR_DCSR, DCSR_HALT

wait_for_interrupt:
        csrr    s0, CSR_DCSR
        andi    s0, s0, DCSR_DEBUGINT
        beqz    s0, wait_for_interrupt

        j       jdebugram
