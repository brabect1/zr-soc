# Copyright 2019 Tomas Brabec
#
# See LICENSE for license details.

#include "riscv_test.h"
#undef RVTEST_RV64M
#define RVTEST_RV64M RVTEST_RV32M

#include "test_macros.h"
#include "soc.h"

#define CSR_PCMR_OFST   0x7a1
#define CSR_PCMR_MASK   0x00000003
#define CSR_PCMR_RSTV   0x00000003

// Counters 11+ are "extra" and exist only when RTL has been configured
// so. Here we assume the default state with no extra counters.
#define CSR_PCER_OFST   0X7a0
#define CSR_PCER_MASK   0x000007ff
#define CSR_PCER_RSTV   0x00000000

#define CSR_PCCR0_OFST  0x780
#define CSR_PCCR0_MASK  0xffffffff
#define CSR_PCCR0_RSTV  0x00000000

#define NUM_EXTRA_PCCR 0

#define CSB_PCMR_SAT        1 // saturation enable
#define CSB_PCMR_GE         0 // global enable

#define CSB_PCER_TCDM_CONT  16
#define CSB_PCER_ST_EXT_CYC 15
#define CSB_PCER_LD_EXT_CYC 14
#define CSB_PCER_ST_EXT     13
#define CSB_PCER_LD_EXT     12
#define CSB_PCER_DEL_SLOT   11
#define CSB_PCER_BRANCH     10
#define CSB_PCER_JUMP       9
#define CSB_PCER_ST         8
#define CSB_PCER_LD         7
#define CSB_PCER_WBR_CYC    6
#define CSB_PCER_WBR        5
#define CSB_PCER_IMISS      4
#define CSB_PCER_INSTR      1
#define CSB_PCER_CYC        0

RVTEST_RV32M
RVTEST_CODE_BEGIN

#define TEST_CSRR_ADDR( testnum, result, regaddr ) \
    TEST_CASE( testnum, x30, result, \
      csrr x30, regaddr; \
    )

#define TEST_CSRRW_ADDR( testnum, value, mask, regaddr ) \
      .set myres,value & mask; \
      li  x29, MASK_XLEN(value); \
      csrw regaddr, x29; \
      csrr  x30,regaddr; \
      li  x29, MASK_XLEN(myres); \
      li  TESTNUM, testnum; \
      bne x30, x29, fail;


test_reset_value:
    TEST_CSRR_ADDR       ( 1, CSR_PCMR_RSTV,  CSR_PCMR_OFST )
    TEST_CSRR_ADDR       ( 2, CSR_PCER_RSTV,  CSR_PCER_OFST )

    // reset values of PCCRx
    .set tnum,3
    .set csraddr,CSR_PCCR0_OFST
.rept (11 + NUM_EXTRA_PCCR)
    csrr  x30,csraddr
    li  x29, MASK_XLEN(CSR_PCCR0_RSTV)
    li  TESTNUM, tnum
    bne x30, x29, fail
    .set tnum,tnum + 1
    .set csraddr,csraddr + 1
.endr

test_read_write:
    TEST_CSRRW_ADDR( 100, 0xFFFFFFFF, CSR_PCMR_MASK, CSR_PCMR_OFST )
    TEST_CSRRW_ADDR( 101, 0xaaaaaaaa, CSR_PCMR_MASK, CSR_PCMR_OFST )
    TEST_CSRRW_ADDR( 102, 0x55555555, CSR_PCMR_MASK, CSR_PCMR_OFST )
    TEST_CSRRW_ADDR( 103, 0x00000000, CSR_PCMR_MASK, CSR_PCMR_OFST )

    TEST_CSRRW_ADDR( 110, 0xFFFFFFFF, CSR_PCER_MASK, CSR_PCER_OFST )
    TEST_CSRRW_ADDR( 111, 0xaaaaaaaa, CSR_PCER_MASK, CSR_PCER_OFST )
    TEST_CSRRW_ADDR( 112, 0x55555555, CSR_PCER_MASK, CSR_PCER_OFST )
    TEST_CSRRW_ADDR( 113, 0x00000000, CSR_PCER_MASK, CSR_PCER_OFST )

    // read/write PCCRx
    .set tnum,210
    .set csraddr,CSR_PCCR0_OFST
.rept (11 + NUM_EXTRA_PCCR)
    TEST_CSRRW_ADDR( tnum, 0xFFFFFFFF, CSR_PCCR0_MASK, csraddr )
    .set tnum,tnum + 1
    TEST_CSRRW_ADDR( tnum, 0xaaaaaaaa, CSR_PCCR0_MASK, csraddr )
    .set tnum,tnum + 1
    TEST_CSRRW_ADDR( tnum, 0x55555555, CSR_PCCR0_MASK, csraddr )
    .set tnum,tnum + 1
    TEST_CSRRW_ADDR( tnum, 0x00000000, CSR_PCCR0_MASK, csraddr )
    .set tnum,(tnum/10 + 1) * 10
    .set csraddr,csraddr + 1
.endr

test_counting:
    // ordinary counting from 0
    TEST_CSRR_ADDR       ( 500, 0x00000000,  CSR_PCCR0_OFST )
    csrwi CSR_PCMR_OFST,3
    csrwi CSR_PCER_OFST,1
    nop
    nop
    csrwi CSR_PCER_OFST,0
    csrr  x30, CSR_PCCR0_OFST
    li  TESTNUM, 501
    beq x30, x0, fail       // assume x30 != 0

    // test that now the counter does not advance
    csrr  x29, CSR_PCCR0_OFST
    li  TESTNUM, 502
    bne x30, x29, fail      // assume x30 == x29

    // test saturation (saturation on)
    li x29, 0xffffffff
    csrw CSR_PCCR0_OFST,x29
    csrwi CSR_PCER_OFST,1
    nop
    nop
    csrwi CSR_PCER_OFST,0
    csrr  x30, CSR_PCCR0_OFST
    li  TESTNUM, 503
    bne x30, x29, fail      // assume x30 == x29

    // test wrap around (saturation off)
//TODO    csrci CSR_PCMR_OFST, CSB_PCMR_SAT // bit clear does not work (https://github.com/pulp-platform/zero-riscy/issues/16)
    csrwi CSR_PCMR_OFST,1
    csrwi CSR_PCER_OFST,1
    nop
    nop
    csrwi CSR_PCER_OFST,0
    csrr  x30, CSR_PCCR0_OFST
    li  TESTNUM, 504
    beq x30, x29, fail      // assume x30 != x29

    // test global enable (turn counters off by clearing GE)
    csrwi CSR_PCMR_OFST,2       // clear GE, set SAT
    csrr  x29, CSR_PCCR0_OFST   // get actual PCCR0
    csrwi CSR_PCER_OFST,1       // enable PCCR0
    nop
    nop
    csrwi CSR_PCER_OFST,0       // disable PCCR0
    csrr  x30, CSR_PCCR0_OFST   // get new PCCR0
    li  TESTNUM, 505
    bne x30, x29, fail      // assume x30 == x29 (no change due to GE cleared)

    # Test End
    TEST_PASSFAIL


RVTEST_CODE_END

.data
RVTEST_DATA_BEGIN

TEST_DATA

#data1: .word 0
#data2: .word 0

RVTEST_DATA_END

