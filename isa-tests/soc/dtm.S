# Copyright 2018 Tomas Brabec
#
# See LICENSE for license details.

#include "riscv_test.h"
#undef RVTEST_RV64M
#define RVTEST_RV64M RVTEST_RV32M

#include "test_macros.h"
#include "soc.h"

#define DTM_BASE 0x00004000

#define DTM_REQ_NOP 0
#define DTM_REQ_RD  1
#define DTM_REQ_WR  2

#define DTM_RSP_OK 0
#define DTM_RSP_BUSY 2
#define DTM_RSP_ERR 1

#define DTM_REQ_DWORD_OFST 0
#define DTM_REQ_DWORD_RSTV 0x00000000
#define DTM_REQ_DWORD_MASK 0xFFFFFFFF

#define DTM_REQ_OTHERS_OFST 4
#define DTM_REQ_OTHERS_RSTV 0x00000000
#define DTM_REQ_OTHERS_MASK 0x000001FF

#define DTM_RSP_DWORD_OFST 8
#define DTM_RSP_DWORD_RSTV 0x00000000
#define DTM_RSP_DWORD_MASK 0x00000000

#define DTM_RSP_OTHERS_OFST 12
#define DTM_RSP_OTHERS_RSTV 0x00000000
#define DTM_RSP_OTHERS_MASK 0x00000000

#define DTM_CTRL_OFST 16
#define DTM_CTRL_RSTV 0x00000000
#define DTM_CTRL_MASK 0x00000000

#define DTM_STAT_OFST 20
#define DTM_STAT_RSTV 0x00000000
#define DTM_STAT_MASK 0x00000000

#define DTM_IEN_OFST 24
#define DTM_IEN_RSTV 0x00000000
#define DTM_IEN_MASK 0x00000001

#define DTM_TMP_IDIS_OFST 28
#define DTM_TMP_IDIS_RSTV 0x00000000
#define DTM_TMP_IDIS_MASK 0x00000001

#define DM_BASE 0x00000000

#define DM_DRAM_OFST 0x400

#define DM_HALTED_OFST 256
#define DM_GOING_OFST 260
#define DM_RESUMING_OFST 264
#define DM_EXCEPTION_OFST 268

#define DM_DATA0_OFST 0x380
#define DM_DATA1_OFST 0x384
#define DM_DATA2_OFST 0x388
#define DM_DATA3_OFST 0x38c

// The start of the Program Buffer is relative to the Data Start
// (i.e. DM_DATA0_OFST) and depends on the buffer size (which is
// currently set to 8).
#define DM_PBUF0_OFST 0x360
#define DM_PBUF1_OFST 0x364
#define DM_PBUF2_OFST 0x368
#define DM_PBUF3_OFST 0x36c

//---->>>> TBRABEC (31-Aug-2019): To be deprecated (no longer used with DM v0.13).
#define DM_CLEARDEBINT_OFST 256
#define DM_CLEARDEBINT_RSTV 0x00000000
#define DM_CLEARDEBINT_MASK 0x00000001

#define DM_HALTNOT_OFST 268
#define DM_HALTNOT_RSTV 0x00000000
#define DM_HALTNOT_MASK 0x00000001
//<<<<----

#define DBUS_DRAM_OFST      0x00
#define DBUS_DMCONTROL_OFST 0x10
#define DBUS_DMCONTROL_RSTV 0x00000000

#define DBUS_DATA0_OFST    0x04
#define DBUS_DATA1_OFST    0x05
#define DBUS_DATA2_OFST    0x06
#define DBUS_DATA3_OFST    0x07

#define DBUS_DMSTATUS_OFST    0x11
#define DBUS_DMSTATUS_RSTV    0x000c0c82

#define DBUS_HARTINFO_OFST  0x12
#define DBUS_HARTINFO_RSTV  0x00212380

#define DBUS_HALTSUM_OFST  0x13
#define DBUS_HALTSUM_RSTV  0x00000000

#define DBUS_HAWINSEL_OFST  0x14
#define DBUS_HAWINSEL_RSTV  0x00000000

#define DBUS_HAWIN_OFST  0x15
#define DBUS_HAWIN_RSTV  0x00000000

#define DBUS_PBUF0_OFST    0x20
#define DBUS_PBUF1_OFST    0x21
#define DBUS_PBUF2_OFST    0x22
#define DBUS_PBUF3_OFST    0x23


#define TEST_DTM2DM_WR( testnum, value, irq, haltnot, addr ) \
    .set others,(addr<<4) | DTM_REQ_WR<<2; \
    li x5, DTM_BASE; \
    li x6, value; \
    sw x6, DTM_REQ_DWORD_OFST(x5); \
    lw x6, DTM_STAT_OFST(x5); \
    bgez x6,2f; \
3:  li TESTNUM,testnum; \
    j  fail; \
2:  li x6, others; \
    li x29,10; \
    sw x6, DTM_REQ_OTHERS_OFST(x5); \
1:  lw x6, DTM_STAT_OFST(x5); \
    addi x29,x29,-1; \
    bltz x29,3b; \
    bltz x6,1b;

#define TEST_DTM2DM_RD( testnum, value, irq, haltnot, addr ) \
    .set others,(irq&1)<<1 | (haltnot&1) | (addr<<4) | DTM_REQ_RD<<2; \
    li x5, DTM_BASE; \
    lw x6, DTM_STAT_OFST(x5); \
    bgez x6,2f; \
3:  li TESTNUM,testnum; \
    j  fail; \
2:  li x6, others; \
    li x29,10; \
    sw x6, DTM_REQ_OTHERS_OFST(x5); \
1:  lw x6, DTM_STAT_OFST(x5); \
    addi x29,x29,-1; \
    bltz x29,3b; \
    bltz x6,1b; \
    lw x31, DTM_RSP_DWORD_OFST(x5); \
    li  x29, MASK_XLEN(value); \
    li  TESTNUM, testnum; \
    bne x31, x29, fail; \
    .set others,(irq&1)<<1 | (haltnot&1) | (addr<<4); \
    lw x31, DTM_RSP_OTHERS_OFST(x5); \
    li  x29, others; \
    bne x31, x29, fail;

RVTEST_RV32M
RVTEST_CODE_BEGIN

test_reset_value:
    TEST_LD_ADDR       ( 1, lw, DTM_REQ_DWORD_RSTV,  DTM_REQ_DWORD_OFST,  DTM_BASE )
    TEST_LD_ADDR       ( 2, lw, DTM_REQ_OTHERS_RSTV, DTM_REQ_OTHERS_OFST, DTM_BASE )
    TEST_LD_ADDR       ( 3, lw, DTM_RSP_DWORD_RSTV,  DTM_RSP_DWORD_OFST,  DTM_BASE )
    TEST_LD_ADDR       ( 4, lw, DTM_RSP_OTHERS_RSTV, DTM_RSP_OTHERS_OFST, DTM_BASE )
    TEST_LD_ADDR       ( 5, lw, DTM_CTRL_RSTV,       DTM_CTRL_OFST,       DTM_BASE )
    TEST_LD_ADDR       ( 6, lw, DTM_STAT_RSTV,       DTM_STAT_OFST,       DTM_BASE )
    TEST_LD_ADDR       ( 7, lw, DTM_IEN_RSTV,        DTM_IEN_OFST,        DTM_BASE )
    TEST_LD_ADDR       ( 8, lw, DTM_TMP_IDIS_RSTV,   DTM_TMP_IDIS_OFST,   DTM_BASE )

test_read_write:
    TEST_RW_ADDR( 10, 0xFFFFFFFF, DTM_REQ_DWORD_MASK, DTM_REQ_DWORD_OFST, DTM_BASE )
    TEST_RW_ADDR( 11, 0xaaaaaaaa, DTM_REQ_DWORD_MASK, DTM_REQ_DWORD_OFST, DTM_BASE )
    TEST_RW_ADDR( 12, 0x55555555, DTM_REQ_DWORD_MASK, DTM_REQ_DWORD_OFST, DTM_BASE )
    TEST_RW_ADDR( 13, 0x00000000, DTM_REQ_DWORD_MASK, DTM_REQ_DWORD_OFST, DTM_BASE )

//---->>>> tbrabec (31-Aug-2019): DM slave flag interface (halted, going, resuming)
//         has only write path and write effects can be observed only indirectly.
//    TEST_RW_ADDR( 20, 0xFFFFFFFF, DM_CLEARDEBINT_MASK, DM_CLEARDEBINT_OFST, DM_BASE )
//    TEST_RW_ADDR( 21, 0xaaaaaaaa, DM_CLEARDEBINT_MASK, DM_CLEARDEBINT_OFST, DM_BASE )
//    TEST_RW_ADDR( 22, 0x55555555, DM_CLEARDEBINT_MASK, DM_CLEARDEBINT_OFST, DM_BASE )
//    TEST_RW_ADDR( 23, 0x00000000, DM_CLEARDEBINT_MASK, DM_CLEARDEBINT_OFST, DM_BASE )
//<<<<----

    # RW test of the HALTNOT bus access appears later as it may affect
    # testing of the HALTNOT flag in DMCONTROL.

    # 1st we need to turn on DM active in dmctrl as DM would remain
    # reset otherwise.
activate_dm:
    TEST_DTM2DM_WR( 20, 0x00000001, 0, 0, DBUS_DMCONTROL_OFST )

    # Test DMI access to Abstract Data registers.
    # Note: DM implementation presently implements only two abstract
    # data words.
test_abstract_data_dmiaccess:
    TEST_DTM2DM_WR( 30, 0xaaaaaaaa, 0, 0, DBUS_DATA0_OFST )
    TEST_DTM2DM_RD( 31, 0xaaaaaaaa, 0, 0, DBUS_DATA0_OFST )

    TEST_DTM2DM_WR( 32, 0x55555555, 0, 0, DBUS_DATA0_OFST )
    TEST_DTM2DM_WR( 33, 0xFFFFFFFF, 0, 0, DBUS_DATA1_OFST )
//    TEST_DTM2DM_WR( 34, 0xaaaaaaaa, 0, 0, DBUS_DATA3_OFTS )

    TEST_DTM2DM_RD( 35, 0x55555555, 0, 0, DBUS_DATA0_OFST )
    TEST_DTM2DM_RD( 36, 0xFFFFFFFF, 0, 0, DBUS_DATA1_OFST )
//    TEST_DTM2DM_RD( 37, 0xaaaaaaaa, 0, 0, DBUS_DATA3_OFST )

    # Test System Bus access to Abstract Data registers.
test_abstract_data_busaccess:
    TEST_LD_ADDR( 41, lw, 0x55555555,  DM_DATA0_OFST,  DM_BASE )
    TEST_LD_ADDR( 42, lw, 0xffffffff,  DM_DATA1_OFST,  DM_BASE )
//    TEST_LD_ADDR( 43, lw, 0xaaaaaaaa,  DM_DATA3_OFST,  DM_BASE )

    TEST_RW_ADDR( 50, 0x00000000, 0xffffffff, DM_DATA0_OFST, DM_BASE )
    TEST_RW_ADDR( 51, 0xaaaaaaaa, 0xffffffff, DM_DATA1_OFST, DM_BASE )
//    TEST_RW_ADDR( 52, 0xffffffff, 0xffffffff, DM_DATA3_OFST, DM_BASE )
//    TEST_RW_ADDR( 53, 0x55555555, 0xffffffff, DM_DATA2_OFST, DM_BASE )

    TEST_DTM2DM_RD( 60, 0xaaaaaaaa, 0, 0, DBUS_DATA1_OFST )
    TEST_DTM2DM_RD( 61, 0x00000000, 0, 0, DBUS_DATA0_OFST )
//    TEST_DTM2DM_RD( 62, 0x55555555, 0, 0, DBUS_DATA2_OFST )
//    TEST_DTM2DM_RD( 63, 0xffffffff, 0, 0, DBUS_DATA3_OFST )


    # Test default (after reset) values of certain DMI registers.
test_dbus_reset:
//    TEST_DTM2DM_RD( 70, DBUS_DMCONTROL_RSTV, 0, 0, DBUS_DMCONTROL_OFST )
    TEST_DTM2DM_RD( 71, DBUS_DMSTATUS_RSTV,    0, 0, DBUS_DMSTATUS_OFST )
    TEST_DTM2DM_RD( 72, DBUS_HARTINFO_RSTV,    0, 0, DBUS_HARTINFO_OFST )
    TEST_DTM2DM_RD( 73, DBUS_HALTSUM_RSTV,     0, 0, DBUS_HALTSUM_OFST )
    TEST_DTM2DM_RD( 74, DBUS_HAWINSEL_RSTV,    0, 0, DBUS_HAWINSEL_OFST )
    TEST_DTM2DM_RD( 75, DBUS_HAWIN_RSTV,       0, 0, DBUS_HAWIN_OFST )

    # Test DMI access to Program Buffer registers.
test_pbuf_data_dmiaccess:
    TEST_DTM2DM_WR( 80, 0xaaaaaaaa, 0, 0, DBUS_PBUF0_OFST )
    TEST_DTM2DM_RD( 81, 0xaaaaaaaa, 0, 0, DBUS_PBUF0_OFST )

    TEST_DTM2DM_WR( 82, 0x55555555, 0, 0, DBUS_PBUF0_OFST )
    TEST_DTM2DM_WR( 83, 0xFFFFFFFF, 0, 0, DBUS_PBUF1_OFST )
    TEST_DTM2DM_WR( 84, 0xaaaaaaaa, 0, 0, DBUS_PBUF3_OFST )
    TEST_DTM2DM_WR( 85, 0x81000099, 0, 0, DBUS_PBUF2_OFST )

    TEST_DTM2DM_RD( 86, 0x55555555, 0, 0, DBUS_PBUF0_OFST )
    TEST_DTM2DM_RD( 87, 0xFFFFFFFF, 0, 0, DBUS_PBUF1_OFST )
    TEST_DTM2DM_RD( 88, 0xaaaaaaaa, 0, 0, DBUS_PBUF3_OFST )
    TEST_DTM2DM_RD( 89, 0x81000099, 0, 0, DBUS_PBUF2_OFST )

    # Test System Bus access to Program Buffer registers. This access
    # is read-only.
test_pbuf_data_busaccess:
    TEST_LD_ADDR(100, lw, 0x55555555,  DM_PBUF0_OFST,  DM_BASE )
    TEST_LD_ADDR(101, lw, 0xffffffff,  DM_PBUF1_OFST,  DM_BASE )
    TEST_LD_ADDR(102, lw, 0xaaaaaaaa,  DM_PBUF3_OFST,  DM_BASE )
    TEST_LD_ADDR(103, lw, 0x81000099,  DM_PBUF2_OFST,  DM_BASE )

    TEST_RO_ADDR(110, 0x00000000, 0x55555555, DM_PBUF0_OFST, DM_BASE )
    TEST_RO_ADDR(111, 0xaaaaaaaa, 0xffffffff, DM_PBUF1_OFST, DM_BASE )
    TEST_RO_ADDR(112, 0xffffffff, 0xaaaaaaaa, DM_PBUF3_OFST, DM_BASE )
    TEST_RO_ADDR(113, 0x00000000, 0x81000099, DM_PBUF2_OFST, DM_BASE )

    # Remember to first enable `ebreak` in DCSR.
breakpoint:
    csrr x6, dcsr
    li x5, 0x00008000
    or x6,x6,x5
    csrw dcsr, x6
    ebreak;

test_haltnot:
    # Test that writing to the HALTNOT bus register with the presently selecte
    # hard ID (in the DMCONTROL Debug Register) will be reflected in DMCONTROL
    # value as well as reads from DRAM.
    li x5, DM_BASE
    li x6, 0
    sw x6, DM_HALTNOT_OFST(x5)
    TEST_DTM2DM_RD(500, DBUS_DMCONTROL_RSTV, 0, 1, DBUS_DMCONTROL_OFST )
    TEST_DTM2DM_RD( 81, 0x55555555, 0, 1, 0 )
    TEST_DTM2DM_RD( 82, 0xaaaaaaaa, 0, 1, 1 )

    # Test writing 1 to the HALTNOT flag in the DMCONTROL register will not
    # clear the flag.
    TEST_DTM2DM_WR( 83, DBUS_DMCONTROL_RSTV, 0, 1, DBUS_DMCONTROL_OFST )
    TEST_DTM2DM_RD( 84, DBUS_DMCONTROL_RSTV, 0, 1, DBUS_DMCONTROL_OFST )

    # Test clearing the HALTNOT flag by writing into the DMCONTROL register.
    TEST_DTM2DM_WR( 85, DBUS_DMCONTROL_RSTV, 0, 0, DBUS_DMCONTROL_OFST )
    TEST_DTM2DM_RD( 86, DBUS_DMCONTROL_RSTV, 0, 0, DBUS_DMCONTROL_OFST )
    TEST_DTM2DM_RD( 87, 0x55555555, 0, 0, 0 )
    TEST_DTM2DM_RD( 88, 0xaaaaaaaa, 0, 0, 1 )

    # Test writing 1 to the HALTNOT flag in the DMCONTROL register will not
    # set the flag.
    TEST_DTM2DM_WR( 89, DBUS_DMCONTROL_RSTV, 0, 1, DBUS_DMCONTROL_OFST )
    TEST_DTM2DM_RD( 90, DBUS_DMCONTROL_RSTV, 0, 0, DBUS_DMCONTROL_OFST )

    # Select other hart ID.
    .set dmctrl, DBUS_DMCONTROL_RSTV | 4
    TEST_DTM2DM_WR(100, dmctrl, 0, 0, DBUS_DMCONTROL_OFST )
    TEST_DTM2DM_RD(101, dmctrl, 0, 0, DBUS_DMCONTROL_OFST )

    # Test that writing to the HALTNOT bus register a hart ID that is not presently
    # selected does not set the HALTNOT flag.
    li x5, DM_BASE
    li x6, 0
    sw x6, DM_HALTNOT_OFST(x5)
    TEST_DTM2DM_RD(102, dmctrl, 0, 0, DBUS_DMCONTROL_OFST )
    TEST_DTM2DM_RD(103, 0x55555555, 0, 0, 0 )

    # Test that changing to a halt indicated hart ID will set the HALTNOT flag.
    .set dmctrl, DBUS_DMCONTROL_RSTV
    TEST_DTM2DM_WR(104, dmctrl, 0, 1, DBUS_DMCONTROL_OFST )
    TEST_DTM2DM_RD(105, dmctrl, 0, 1, DBUS_DMCONTROL_OFST )
    TEST_DTM2DM_RD(106, 0x55555555, 0, 1, 0 )

    # Select other hart ID and test no HALTNOT indicated.
    # (Keep HALTNOT in DTM write set not as it would otherwise clear the
    # flag for the presently selected hart.)
    .set dmctrl, DBUS_DMCONTROL_RSTV | 4
    TEST_DTM2DM_WR(107, dmctrl, 0, 1, DBUS_DMCONTROL_OFST )
    TEST_DTM2DM_RD(108, dmctrl, 0, 0, DBUS_DMCONTROL_OFST )

    # Test that changing back to a halt indicated hart ID will again indicate the HALTNOT flag.
    # (Note that we cleared HALTNOT in DTM write as it does not affect the
    # the hart we are selecting in the same write.)
    .set dmctrl, DBUS_DMCONTROL_RSTV
    TEST_DTM2DM_WR(109, dmctrl, 0, 0, DBUS_DMCONTROL_OFST )
    TEST_DTM2DM_RD(110, dmctrl, 0, 1, DBUS_DMCONTROL_OFST )

test_read_write_bus_haltnot:
    TEST_RW_ADDR(120, 0xFFFFFFFF, DM_HALTNOT_MASK, DM_HALTNOT_OFST, DM_BASE )
    TEST_RW_ADDR(121, 0xaaaaaaaa, DM_HALTNOT_MASK, DM_HALTNOT_OFST, DM_BASE )
    TEST_RW_ADDR(122, 0x55555555, DM_HALTNOT_MASK, DM_HALTNOT_OFST, DM_BASE )
    TEST_RW_ADDR(123, 0x00000000, DM_HALTNOT_MASK, DM_HALTNOT_OFST, DM_BASE )

    # Make sure to clear the HALTNOT flasg.
    TEST_DTM2DM_WR(124, DBUS_DMCONTROL_RSTV, 0, 0, DBUS_DMCONTROL_OFST )
    TEST_DTM2DM_RD(125, DBUS_DMCONTROL_RSTV, 0, 0, DBUS_DMCONTROL_OFST )

test_debint:
    TEST_DTM2DM_WR(130, DBUS_DMCONTROL_RSTV, 1, 0, DBUS_DMCONTROL_OFST )
    TEST_DTM2DM_RD(131, DBUS_DMCONTROL_RSTV, 1, 0, DBUS_DMCONTROL_OFST )
    TEST_DTM2DM_WR(132, DBUS_DMCONTROL_RSTV, 0, 0, DBUS_DMCONTROL_OFST )
    TEST_DTM2DM_RD(133, DBUS_DMCONTROL_RSTV, 1, 0, DBUS_DMCONTROL_OFST )

    li x5, DM_BASE
    li x6, 0
    sw x6, DM_CLEARDEBINT_OFST(x5)
    TEST_DTM2DM_RD(134, DBUS_DMCONTROL_RSTV, 0, 0, DBUS_DMCONTROL_OFST )

test_dbus_err:
    # Test that initiating two DTM-to-DM writes back-to-back leads to
    # BUSY status response.
    .set testnum,140
    li x5, DTM_BASE
    li x6, 0xf0f00f0f
    sw x6, DTM_REQ_DWORD_OFST(x5)
    .set addr,0
    .set others, (addr<<4) | DTM_REQ_WR<<2
    li x6, others
    sw x6, DTM_REQ_OTHERS_OFST(x5)
    sw x6, DTM_REQ_OTHERS_OFST(x5)
    li x29,10
    li  TESTNUM, testnum
1:  lw x6, DTM_STAT_OFST(x5)
    addi x29,x29,-1
    bltz x29,fail
    bnez x6,1b
    .set others,(addr<<4) | DTM_RSP_BUSY<<2
    lw x31, DTM_RSP_OTHERS_OFST(x5)
    li  x29, others
    bne x31, x29, fail

    # TODO: test sticky status of BUSY
    # TODO: test clearing the sticky status

# Test entering and leaving the debug mode. The mode is enetered
# by asserting debug interrupt (through DM) and enabling the interrupt
# to propagate to the core (using DTM int. enable).
# The mode is left by clearing the interrupt and calling dret (using
# a program copied to DRAM).
test_dmode:
    # Copy a debug program into DRAM
    li  a0,4
    la  a1,prog_clrdint
    li  a2,0x400
    call copy_code

    # Set DM Interrupt
    .set testnum,150
    .set others,2 | (DBUS_DMCONTROL_OFST<<4) | DTM_REQ_WR<<2
    li x5, DTM_BASE
    lw x6, DTM_STAT_OFST(x5)
    bgez x6,2f
3:  li TESTNUM,testnum
    j  fail
2:  li x29,10
    li x6, DBUS_DMCONTROL_RSTV
    sw x6, DTM_REQ_DWORD_OFST(x5)
    li x6, others
    sw x6, DTM_REQ_OTHERS_OFST(x5)
1:  lw x6, DTM_STAT_OFST(x5)
    addi x29,x29,-1
    bltz x29,3b
    bltz x6,1b

    # Set data at address 0x418 (DRAM), which is used for communication
    # between a hart and a debugger. In this test, DM (through a DROM
    # code) shall clear this location.
    .set testnum,testnum+1 # 151
    li TESTNUM,testnum
    li x6,-1
    sw x6,1048(x0) # 0x418
    lw x6,1048(x0) # 0x418
    beqz x6,fail

    # Enable Debug Interrupts
    .set testnum,testnum+1 # 152
    li TESTNUM,testnum
    li x7,0
    li x5, DTM_BASE
    li x6, -1
    sw x6, DTM_IEN_OFST(x5)

    # Perform a series of arith ops on x7 (to make sure all have executed
    # and each only once). This is to make sure that taking the debug IRQ
    # returns properly.
    addi x7,x7,1
    addi x7,x7,1
    addi x7,x7,1
    addi x7,x7,1
    addi x7,x7,-4
    bnez x7,fail

    # See that DROM code executed.
    .set testnum,testnum+1 # 153
    li TESTNUM,testnum
    lw x6,1048(x0) # 0x418
    bnez x6,fail

# Tests entering the debug mode on executing `ebreak` outside of debug mode.
# Note that the DROM code is designed to wait for debug IRQ from a debugger
# (i.e. DM) and will do so in a wait loop. Hence without the debug IRQ the
# processor would never recover from `ebreak`.
test_ebreak:
    # Copy a debug program into DRAM
    .set testnum,160
    li TESTNUM,testnum
#    sw x0,1024(x0) # 0x400 -> will cause illegal instr when DRAM code is called
    li  a0,5
    la  a1,prog_clrdint_and_halt
    li  a2,0x400
    call copy_code

    # Disable Debug Interrupts
    .set testnum,testnum+1 # 161
    li TESTNUM,testnum
    li x7,0
    li x5, DTM_BASE
    sw x0, DTM_IEN_OFST(x5)

    # Set DM Interrupt
    .set others,2 | (DBUS_DMCONTROL_OFST<<4) | DTM_REQ_WR<<2
    .set testnum,testnum+1 # 162
    li TESTNUM,testnum
    li x5, DTM_BASE
    lw x6, DTM_STAT_OFST(x5)
    bgez x6,2f
3:  j  fail
2:  li x29,10
    li x6, DBUS_DMCONTROL_RSTV
    sw x6, DTM_REQ_DWORD_OFST(x5)
    li x6, others
    sw x6, DTM_REQ_OTHERS_OFST(x5)
1:  lw x6, DTM_STAT_OFST(x5)
    addi x29,x29,-1
    bltz x29,3b
    bltz x6,1b

    # Temporarily block Debug Interrupts
    # (x5 shall be set to DTM_BASE)
    .set testnum,testnum+1 # 163
    li TESTNUM,testnum
    li x6,-1
    sw x6, DTM_TMP_IDIS_OFST(x5)

    # Enable Debug Interrupts
    # (x5 shall be set to DTM_BASE)
    .set testnum,testnum+1 # 164
    li TESTNUM,testnum
    li x6,-1
    sw x6, DTM_IEN_OFST(x5)

    # Execute EBREAK
    li x7,0
    ebreak

    # Perform a series of arith ops on x7 (to make sure all have executed
    # and each only once). This is to make sure that taking the debug IRQ
    # returns properly.
    addi x7,x7,1
    addi x7,x7,1
    addi x7,x7,1
    addi x7,x7,1
    addi x7,x7,-4
    bnez x7,fail

//TODO other things that'll need to be tested
// - entering debug mode by setting `halt` in `dcsr`
// - setting `halt` when in the debug mode does not change `cause` in `dcsr` (this is not
//   specified anywhere in v0.11, but it is somewhat implied or a debugger could not otherwise
//   distinguish why the Debug Mode was enetered spontaneously (as each enter other than Debug
//   IRQ sets `halt` in `dcsr`).
// - using `halt` bit to enter debug mode right after reset (v0.11, sec. 8.6.1, p. 29)
// - exception in debug mode
//   - All exceptions don't update any registers, and cause the hart to jump to exception in Debug ROM.
// - interrupt in debug mode (+ different combination of races when entering/leaving debug mode)
//   - All interrupts are masked. Whether slow watchdog timers (10s or longer) are masked is left to the implementation.
// - ebreak entering the debug mode
// - Executing dret outside of Debug Mode causes an illegal instruction exception.

    # Test End
    TEST_PASSFAIL

# Clears DM IRQ by writing hart ID into Cleardebint, then jumps
# to the <resume> vector in DROM.
    .align 4
prog_clrdint:
    li x5, DM_BASE
    sw x0, DM_CLEARDEBINT_OFST(x5)
    li x6, 0x804
    jr x6  # jump to DROM <resume> target
    .align 4

prog_clrdint_and_halt:
    li x5, DM_BASE
    sw x0, DM_CLEARDEBINT_OFST(x5)
    csrci dcsr,8 # clear HALT
    li x6, 0x804
    jr x6  # jump to DROM <resume> target
    .align 4

    # Copies `a0` number of words from address `a1` to address `a2`.
    # This is a procedure to be called with the following arguments:
    # a0 - Number of words.
    # a1 - Source address.
    # a2 - Target address.
copy_code:
    addi a0,a0,-1
    bltz a0,copy_code_end
copy_code_loop:
    lw   x31,0(a1)
    sw   x31,0(a2)
    addi a1,a1,4
    addi a2,a2,4
    addi a0,a0,-1
    bgez a0,copy_code_loop
copy_code_end:
    ret

RVTEST_CODE_END

.data
RVTEST_DATA_BEGIN

TEST_DATA

#data1: .word 0
#data2: .word 0

RVTEST_DATA_END
