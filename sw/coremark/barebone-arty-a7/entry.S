// See LICENSE for license details.

#include "encoding.h"

#ifndef CAUSE_LOAD_PAGE_FAULT
#error "CAUSE_LOAD_PAGE_FAULT not defined!"
#endif

#define TESTNUM gp

.macro init
.endm


#define DELEGATE_NO_TRAPS                                               \
  la t0, 1f;                                                            \
  csrw mtvec, t0;                                                       \
  csrwi medeleg, 0;                                                     \
  csrwi mideleg, 0;                                                     \
  csrwi mie, 0;                                                         \
  .align 2;                                                             \
1:


#define EXTRA_TVEC_USER
#define EXTRA_TVEC_MACHINE
#define EXTRA_INIT
#define EXTRA_INIT_TIMER

#define INTERRUPT_HANDLER j other_exception /* No interrupts should occur */

    .section .text.init
    .align  6
    .weak stvec_handler
    .weak mtvec_handler
    .globl _start
    .rept 32
        .align 2
        j trap_vector
    .endr
    .align 2
_start:
    /* reset vector */
    j reset_vector
    .align 2
trap_illegal_instr:
    j trap_vector
    .align 2
trap_ecall:
    j trap_vector
    .align 2
trap_vector:
    csrw mscratch, a0
    la  a0, test_trap_data 
    sw t5, 0(a0)
    sw t6, 4(a0)
    .pushsection .data
        .align 2
test_trap_data:
        .word 0
        .word 0
    .popsection
    csrr t5, mcause
    bltz t5, other_interrupts
    li t6, CAUSE_USER_ECALL
    beq t5, t6, write_tohost
    li t6, CAUSE_SUPERVISOR_ECALL
    beq t5, t6, write_tohost
    li t6, CAUSE_MACHINE_ECALL
    beq t5, t6, write_tohost
    li t6, CAUSE_FETCH_ACCESS
    beq t5, t6, ifetch_error_handler
    li t6, CAUSE_LOAD_ACCESS
    beq t5, t6, load_error_handler
    li t6, CAUSE_STORE_ACCESS
    beq t5, t6, store_error_handler
    /* if an mtvec_handler is defined, jump to it */
    la t5, mtvec_handler
    beqz t5, 1f
    jr t5
    /* was it an interrupt or an exception? */
1:  csrr t5, mcause
    bgez t5, handle_exception
    INTERRUPT_HANDLER
handle_exception:
    /* we don't know how to handle whatever the exception was */
other_exception:
    /* some unhandlable exception occurred */
    /* Bob add IRQ Cause here: begin */
    j 1f
other_interrupts:
    li t6, CAUSE_IRQ_M_SFT
    beq t5, t6, sft_irq_handler
    li t6, CAUSE_IRQ_M_TMR
    beq t5, t6, tmr_irq_handler
    li t6, CAUSE_IRQ_M_EXT
    beq t5, t6, ext_irq_handler
1:  ori TESTNUM, TESTNUM, 1337
write_tohost:
    li a0, MSTATUS_MIE
    csrs mstatus, a0
    sw TESTNUM, tohost, t5
    j write_tohost
ext_irq_handler:
    la  a0, test_trap_data
    lw t5, 0(a0)
    lw t6, 4(a0)
    csrr a0, mscratch
    mret
sft_irq_handler:
    la  a0, test_trap_data
    lw t5, 0(a0)
    lw t6, 4(a0)
    csrr a0, mscratch
    mret
tmr_irq_handler:
    la  a0, test_trap_data
    lw t5, 0(a0)
    lw t6, 4(a0)
    csrr a0, mscratch
    mret
ifetch_error_handler:
    la  a0, test_trap_data
    lw t5, 0(a0)
    lw t6, 4(a0)
    csrr a0, mbadaddr
    csrr a0, mscratch
    mret
load_error_handler:
    la  a0, test_trap_data
    lw t5, 0(a0)
    lw t6, 4(a0)
    csrr a0, mbadaddr
    csrr a0, mscratch
    mret
store_error_handler:
    la  a0, test_trap_data
    lw t5, 0(a0)
    lw t6, 4(a0)
    csrr a0, mbadaddr
    csrr a0, mscratch
    mret
reset_vector:
    mv t5, x0
    mv t6, x0
    /*RISCV_MULTICORE_DISABLE*/
    /*DELEGATE_NO_TRAPS;*/
    li TESTNUM, 0
    la t0, trap_vector
    li a0, MSTATUS_MIE
    csrs mstatus, a0
    li a0, 0xFFFFFFFF
    csrs mie, a0
    csrw mtvec, t0
    /* if an stvec_handler is defined, delegate exceptions to it */
post_mtvec:
    la t0, stvec_handler
    beqz t0, 1f
    csrw stvec, t0
    li t0, (1 << CAUSE_LOAD_PAGE_FAULT) | (1 << CAUSE_STORE_PAGE_FAULT) | (1 << CAUSE_FETCH_PAGE_FAULT) | (1 << CAUSE_MISALIGNED_FETCH) | (1 << CAUSE_USER_ECALL) | (1 << CAUSE_BREAKPOINT)
    csrw medeleg, t0
    csrr t1, medeleg
    bne t0, t1, other_exception
1:  csrwi mstatus, 0
    li a0, MSTATUS_MPIE
    csrs mstatus, a0
    li a0, 0x0      // We need to enable the ecc exception
    csrw 0xbfc, a0
    init
    EXTRA_INIT
    EXTRA_INIT_TIMER
    la t0, 1f
    csrw mepc, t0
    csrr a0, mhartid
    mret
1:
    la sp, __Ram_end    // set the stack pointer
    jal main            // start C <main>
    ecall               // cause exception that will handshake to simulation
                        // environment


//-----------------------------------------------------------------------
// Data Section Macro
//-----------------------------------------------------------------------

    .data
    .pushsection .tohost,"aw",@progbits
    .align 6; .global tohost; tohost: .dword 0
    .align 6; .global fromhost; fromhost: .dword 0
    .popsection;                                                    \
    .align 4; .global begin_signature; begin_signature:
    .align 4; .global end_signature; end_signature:

