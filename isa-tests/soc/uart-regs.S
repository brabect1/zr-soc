# Copyright 2018 Tomas Brabec
#
# See LICENSE for license details.

#include "riscv_test.h"
#undef RVTEST_RV64M
#define RVTEST_RV64M RVTEST_RV32M

#include "test_macros.h"
#include "soc.h"


RVTEST_RV32M
RVTEST_CODE_BEGIN

# -----------------------------------------------
# Test the UART0
# -----------------------------------------------

    # Make sure UART TxD and RxD pass through GPIO interface is
    # enabled.
io_map:
    li t4, GPIO0_BASE
    li t5, 0x00030000
    sw t5,GPIO_IOFEN_OFST(t4)

test_reset_value:
    TEST_LD_ADDR       ( 1, lw, UART_TXDATA_RSTV,   UART_TXDATA_OFST,    UART0_BASE )
    TEST_LD_ADDR_IGNORE( 2, lw, UART_RXDATA_RSTV,   UART_RXDATA_OFST,    UART0_BASE, 0xffffff00 )
    TEST_LD_ADDR       ( 3, lw, UART_TXCTRL_RSTV,   UART_TXCTRL_OFST,    UART0_BASE )
    TEST_LD_ADDR       ( 4, lw, UART_RXCTRL_RSTV,   UART_RXCTRL_OFST,    UART0_BASE )
    TEST_LD_ADDR       ( 5, lw, UART_IE_RSTV,       UART_IE_OFST,        UART0_BASE )
    TEST_LD_ADDR       ( 6, lw, UART_IP_RSTV,       UART_IP_OFST,        UART0_BASE )
    TEST_LD_ADDR       ( 7, lw, UART_DIV_RSTV,      UART_DIV_OFST,       UART0_BASE )

test_read_write:
    TEST_RW_ADDR( 100, 0xFFFFFFFF, UART_DIV_MASK, UART_DIV_OFST, UART0_BASE )
    TEST_RW_ADDR( 101, 0xaaaaaaaa, UART_DIV_MASK, UART_DIV_OFST, UART0_BASE )
    TEST_RW_ADDR( 102, 0x55555555, UART_DIV_MASK, UART_DIV_OFST, UART0_BASE )
    # Intentionally avoiding 0 value
    TEST_RW_ADDR( 103, 0x00000010, UART_DIV_MASK, UART_DIV_OFST, UART0_BASE )

    TEST_RO_ADDR_IGNORE( 110, 0xFFFFFFFF, UART_RXDATA_RSTV, UART_RXDATA_OFST, UART0_BASE, 0xffffff00 )
    TEST_RO_ADDR_IGNORE( 111, 0xaaaaaaaa, UART_RXDATA_RSTV, UART_RXDATA_OFST, UART0_BASE, 0xffffff00 )
    TEST_RO_ADDR_IGNORE( 112, 0x55555555, UART_RXDATA_RSTV, UART_RXDATA_OFST, UART0_BASE, 0xffffff00 )
    TEST_RO_ADDR_IGNORE( 113, 0x00000000, UART_RXDATA_RSTV, UART_RXDATA_OFST, UART0_BASE, 0xffffff00 )

    TEST_RW_ADDR( 120, 0xFFFFFFFF, UART_TXCTRL_MASK, UART_TXCTRL_OFST, UART0_BASE )
    TEST_RW_ADDR( 121, 0xaaaaaaaa, UART_TXCTRL_MASK, UART_TXCTRL_OFST, UART0_BASE )
    TEST_RW_ADDR( 122, 0x55555555, UART_TXCTRL_MASK, UART_TXCTRL_OFST, UART0_BASE )
    TEST_RW_ADDR( 123, 0x00000000, UART_TXCTRL_MASK, UART_TXCTRL_OFST, UART0_BASE )

    TEST_RW_ADDR( 130, 0xFFFFFFFF, UART_RXCTRL_MASK, UART_RXCTRL_OFST, UART0_BASE )
    TEST_RW_ADDR( 131, 0xaaaaaaaa, UART_RXCTRL_MASK, UART_RXCTRL_OFST, UART0_BASE )
    TEST_RW_ADDR( 132, 0x55555555, UART_RXCTRL_MASK, UART_RXCTRL_OFST, UART0_BASE )
    TEST_RW_ADDR( 133, 0x00000000, UART_RXCTRL_MASK, UART_RXCTRL_OFST, UART0_BASE )

    TEST_RW_ADDR( 140, 0xFFFFFFFF, UART_IE_MASK, UART_IE_OFST, UART0_BASE )
    TEST_RW_ADDR( 141, 0xaaaaaaaa, UART_IE_MASK, UART_IE_OFST, UART0_BASE )
    TEST_RW_ADDR( 142, 0x55555555, UART_IE_MASK, UART_IE_OFST, UART0_BASE )
    TEST_RW_ADDR( 143, 0x00000000, UART_IE_MASK, UART_IE_OFST, UART0_BASE )

    TEST_RO_ADDR( 150, 0xFFFFFFFF, UART_IP_RSTV, UART_IP_OFST, UART0_BASE )
    TEST_RO_ADDR( 151, 0xaaaaaaaa, UART_IP_RSTV, UART_IP_OFST, UART0_BASE )
    TEST_RO_ADDR( 152, 0x55555555, UART_IP_RSTV, UART_IP_OFST, UART0_BASE )
    TEST_RO_ADDR( 153, 0x00000000, UART_IP_RSTV, UART_IP_OFST, UART0_BASE )

    TEST_RO_ADDR( 160, 0xFFFFFFFF, UART_TXDATA_RSTV, UART_TXDATA_OFST, UART0_BASE )
    TEST_RO_ADDR( 161, 0xaaaaaaaa, UART_TXDATA_RSTV, UART_TXDATA_OFST, UART0_BASE )
    TEST_RO_ADDR( 162, 0x55555555, UART_TXDATA_RSTV, UART_TXDATA_OFST, UART0_BASE )
    TEST_RO_ADDR( 163, 0x00000000, UART_TXDATA_RSTV, UART_TXDATA_OFST, UART0_BASE )

    # initialize registers
    .set divisor,32
test_init:
    li t4, UART0_BASE
    li t5, divisor
    sw t5, UART_DIV_OFST(t4)     # min useful divisor is 16
    sw x0, UART_IE_OFST(t4)      # disable interrupts

    # write another 4 bytes into Tx FIFO
    # (four bytes were already written during reg. RW test)
    li t5,4
1:  sw t5,UART_TXDATA_OFST(t4)
    addi t5,t5,-1
    bnez t5,1b

    # check Tx/Rx FIFO status
    TEST_LD_ADDR       ( 200, lw, 0x80000000,         UART_TXDATA_OFST,    UART0_BASE )
    TEST_LD_ADDR_IGNORE( 201, lw, UART_RXDATA_RSTV,   UART_RXDATA_OFST,    UART0_BASE, 0xffffff00 )

    # enable transfer
test_en_xfer:
    li t5, 1
    li t4, UART0_BASE
    sw t5, UART_RXCTRL_OFST(t4)  # enable receiver
    sw t5, UART_TXCTRL_OFST(t4)  # enable transmitter

    # wait loop (8 bytes, max 11 bauds each, plus some overhead)
    # (since the wait loop will take at least 2 cycles, we adjust the number
    # of loops accordingly)
    .set wait_cycs, divisor * 11 * 8 + 100
    li t5,wait_cycs
    srli t5,t5,2 # adjust to 1/4 (two instr per cycle + branch recovery)
1:  addi t5,t5,-1
    bgez t5,1b

    # check Tx FIFO status
    TEST_LD_ADDR       ( 203, lw, UART_TXDATA_RSTV,         UART_TXDATA_OFST,    UART0_BASE )

    # check received data
    TEST_LD_ADDR       ( 204, lw, 0x000000ff,   UART_RXDATA_OFST,    UART0_BASE )
    TEST_LD_ADDR       ( 205, lw, 0x000000aa,   UART_RXDATA_OFST,    UART0_BASE )
    TEST_LD_ADDR       ( 206, lw, 0x00000055,   UART_RXDATA_OFST,    UART0_BASE )
    TEST_LD_ADDR       ( 207, lw, 0x00000000,   UART_RXDATA_OFST,    UART0_BASE )
    TEST_LD_ADDR       ( 208, lw, 0x00000004,   UART_RXDATA_OFST,    UART0_BASE )
    TEST_LD_ADDR       ( 209, lw, 0x00000003,   UART_RXDATA_OFST,    UART0_BASE )
    TEST_LD_ADDR       ( 210, lw, 0x00000002,   UART_RXDATA_OFST,    UART0_BASE )
    TEST_LD_ADDR       ( 211, lw, 0x00000001,   UART_RXDATA_OFST,    UART0_BASE )

    # check empty Rx FIFO
    TEST_LD_ADDR_IGNORE( 212, lw, UART_RXDATA_RSTV,   UART_RXDATA_OFST,    UART0_BASE, 0xffffff00 )

    # Test End
    TEST_PASSFAIL


RVTEST_CODE_END

.data
RVTEST_DATA_BEGIN

TEST_DATA

#data1: .word 0
#data2: .word 0

RVTEST_DATA_END
