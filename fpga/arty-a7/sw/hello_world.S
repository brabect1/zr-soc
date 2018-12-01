# Copyright 2018 Tomas Brabec
#
# See LICENSE for license details.
#
# Description:
#   Prints the "Hello World!" string over UART at 115.2 kbps.


#include "init.h"

#undef CODE_RV64M
#define CODE_RV64M CODE_RV32M

#include "soc.h"


CODE_RV32M
CODE_BEGIN

    # Make sure UART TxD and RxD pass through GPIO interface is
    # enabled.
io_map:
    li t4, GPIO0_BASE
    li t5, 0x00030000
    sw t5,GPIO_IOFEN_OFST(t4)

    # Set the baud rate to 115.2 kbps @ 20Mhz (div=1s/50ns / 115200 = 173.6 ~ 174)
baud_rate:
    li t4,UART0_BASE
    li t6,174
    sw t6,UART_DIV_OFST(t4)

    # enable transfer
en_xfer:
    li t6, 1
    li t4, UART0_BASE
    sw t6, UART_RXCTRL_OFST(t4)  # enable receiver
    sw t6, UART_TXCTRL_OFST(t4)  # enable transmitter

exec_xfer:
    # write characters into Tx FIFO
    li t4,UART0_BASE
    la t6,msg
msg_loop:
    # Wait for Tx FIFO not full
1:  lw t2,UART_TXDATA_OFST(t4)
    bltz t2,1b

    # Load char of a string
    lb t2,0(t6)
    andi t2,t2,0x000000ff
    beqz t2,msg_done
    sw t2,UART_TXDATA_OFST(t4)
    addi t6,t6,1
    j msg_loop
msg_done:

    # Infinite loop
1:  j 1b

CODE_END

.data
CODE_DATA_BEGIN

msg:
.string "Hello World!"
.word 0
#msg_len =    . - msg

#data1: .word 0
#data2: .word 0

CODE_DATA_END
