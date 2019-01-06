# See LICENSE for license details.

#ifndef __soc_h
#define __soc_h



#define TEST_RW_ADDR( testnum, value, mask, offset, base ) \
      .set myres,value & mask; \
    TEST_CASE( testnum, x30, myres, \
      li  x1, base; \
      li  x30,value; \
      sw x30, offset(x1); \
      lw x30, offset(x1); \
    )

#define TEST_RW_ADDR_IGNORE( testnum, value, mask, offset, base, ignmask ) \
      .set myres,value & mask & ignmask; \
    TEST_CASE( testnum, x30, myres, \
      li  x1, base; \
      li  x30,value; \
      sw x30, offset(x1); \
      lw x30, offset(x1); \
      li x29,ignmask; \
      and x30,x30,x29; \
    )

#define TEST_RO_ADDR( testnum, value, expected, offset, base ) \
    TEST_CASE( testnum, x30, expected, \
      li  x1, base; \
      li  x30,value; \
      sw x30, offset(x1); \
      lw x30, offset(x1); \
    )

#define TEST_RO_ADDR_IGNORE( testnum, value, expected, offset, base, mask ) \
    TEST_CASE( testnum, x30, expected, \
      li  x1, base; \
      li  x30,value; \
      sw x30, offset(x1); \
      lw x30, offset(x1); \
      andi x30,x30, mask; \
    )

#define TEST_LD_ADDR( testnum, inst, result, offset, base ) \
    TEST_CASE( testnum, x30, result, \
      li  x1, base; \
      inst x30, offset(x1); \
    )

#define TEST_LD_ADDR_IGNORE( testnum, inst, result, offset, base, mask ) \
    TEST_CASE( testnum, x30, result, \
      li  x1, base; \
      inst x30, offset(x1); \
      andi x30,x30, mask; \
    )


# -----------------------------------------------
# AON (Always ON)
# -----------------------------------------------

#define AON_BASE 0x10000000

# -----------------------------------------------
# WDOG (Watchdog Counter)
# -----------------------------------------------
# The memory map is listed below. For complete periph IP reference
# see "SiFive E300 Platform Reference Manual"
#
# IMPORTANT: Offsets are relative to AON (Always ON) module base.
#
# Memory map:
#   0x10000000 wdogcfg  Watchdog configuration
#   0x10000008 wdogcnt  Watchdog count
#   0x10000010 wdogs    Watchdog value scaled
#   0x10000018 wdogfeed Watchdog feed
#   0x1000001c wdogkey  Watchdog key
#   0x10000020 wdogcmp  Watchdog compare

#define WDOG_CFG_OFST 0
#define WDOG_CFG_RSTV 0x00000000
#define WDOG_CFG_MASK 0x1000330f

#define WDOG_CNT_OFST 8
#define WDOG_CNT_RSTV 0x00000000
#define WDOG_CNT_MASK 0x7fffffff

#define WDOG_SCALED_OFST 16
#define WDOG_SCALED_RSTV 0x00000000
#define WDOG_SCALED_MASK 0x0000ffff

#define WDOG_FEED_OFST 24
#define WDOG_FEED_RSTV 0x00000000
#define WDOG_FEED_MASK 0x00000000

#define WDOG_KEY_OFST 28
#define WDOG_KEY_RSTV 0x00000000
#define WDOG_KEY_MASK 0x00000001

#define WDOG_CMP_OFST 32
#define WDOG_CMP_RSTV 0x0000ffff
#define WDOG_CMP_MASK 0x0000ffff

#define WDOG_KEY_VALUE 0x51f15e
#define WDOG_FEED_VALUE 0xd09f00d

# -----------------------------------------------
# RTC (Real-Time Clock)
# -----------------------------------------------
# The memory map is listed below. For complete periph IP reference
# see "SiFive E300 Platform Reference Manual"
#
# IMPORTANT: Offsets are relative to AON (Always ON) module base.
#
# Memory map:
#   0x10000040 rtccfg   RTC configuration
#   0x10000048 rtclo    RTC count low
#   0x1000004c rtchi    RTC count high
#   0x10000050 rtcs     RTC value scaled
#   0x10000060 rtccmp   RTC comapre

#define RTC_CFG_OFST 64
#define RTC_CFG_RSTV 0x00000000
#define RTC_CFG_MASK 0x1000100f

#define RTC_LO_OFST 72
#define RTC_LO_RSTV 0x00000000
#define RTC_LO_MASK 0xffffffff

#define RTC_HI_OFST 76
#define RTC_HI_RSTV 0x00000000
#define RTC_HI_MASK 0x0000ffff

#define RTC_SCALED_OFST 80
#define RTC_SCALED_RSTV 0x00000000
#define RTC_SCALED_MASK 0xFFFFFFFF

#define RTC_CMP_OFST 96
#define RTC_CMP_RSTV 0xffffffff
#define RTC_CMP_MASK 0xFFFFFFFF


# -----------------------------------------------
# QSPI0 (Flash QSPI)
# -----------------------------------------------
# The memory map is listed below. For complete periph IP reference
# see "SiFive E300 Platform Reference Manual"
#
# Memory map:
#   0x10014000 sckdiv Serial clock divisor
#   0x10014004 sckmode Serial clock mode
#   0x10014010 csid Chip select ID
#   0x10014014 csdef Chip select default
#   0x10014018 csmode Chip select mode
#   0x10014028 delay0 Delay control 0
#   0x1001402C delay1 Delay control 1
#   0x10014040 fmt Frame format
#   0x10014048 txdata Tx FIFO data
#   0x1001404C rxdata Rx FIFO data
#   0x10014050 txmark Tx FIFO watermark
#   0x10014054 rxmark Rx FIFO watermark
#   0x10014060 fctrl* SPI flash interface control
#   0x10014064 ffmt* SPI flash instruction format
#   0x10014070 ie SPI interrupt enable
#   0x10014074 ip SPI interrupt pending

#define SPI0_BASE 0x10014000

#define SPI_SCKDIV_OFST 0
#define SPI_SCKDIV_RSTV 0x00000003
#define SPI_SCKDIV_MASK 0x00000fff

#define SPI_SCKMODE_OFST 4
#define SPI_SCKMODE_RSTV 0x00000000
#define SPI_SCKMODE_MASK 0x00000003

# !!! There is a change in e203 SoC as opposed to SiFive freedom-e300-arty
# !!! (SiFive assumes full register width RW, whicle sirv uses only LSB)
#define SPI_CSID_OFST 16
#define SPI_CSID_RSTV 0x00000000
#define SPI_CSID_MASK 0x00000001

# !!! There is a change in e203 SoC as opposed to SiFive freedom-e300-arty
# !!! (SiFive resets to 0x0000ffff and assumes register full width, sirv uses
# !!! only LSB)
#define SPI_CSDEF_OFST 20
#define SPI_CSDEF_RSTV 0x00000001
#define SPI_CSDEF_MASK 0x00000001

#define SPI_CSMODE_OFST 24
#define SPI_CSMODE_RSTV 0x00000000
#define SPI_CSMODE_MASK 0x00000003

#define SPI_DELAY0_OFST 40
#define SPI_DELAY0_RSTV 0x00010001
#define SPI_DELAY0_MASK 0x00ff00ff

#define SPI_DELAY1_OFST 44
#define SPI_DELAY1_RSTV 0x00000001
#define SPI_DELAY1_MASK 0x00ff00ff

#define SPI_FMT_OFST 64
#define SPI_FMT_RSTV 0x00080000
#define SPI_FMT_MASK 0x000f000f

#define SPI_TXDATA_OFST 72
#define SPI_TXDATA_RSTV 0x00000000
#define SPI_TXDATA_MASK 0x800000FF

#define SPI_RXDATA_OFST 76
#define SPI_RXDATA_RSTV 0x80000000
#define SPI_RXDATA_MASK 0x800000FF

# !!! There is a change in e203 SoC as opposed to SiFive freedom-e300-arty
# !!! (SiFive assumes 3-bit register, sirv uses 4 bits)
#define SPI_TXMARK_OFST 80
#define SPI_TXMARK_RSTV 0x00000000
#define SPI_TXMARK_MASK 0x0000000F

# !!! There is a change in e203 SoC as opposed to SiFive freedom-e300-arty
# !!! (SiFive assumes 3-bit register, sirv uses 4 bits)
#define SPI_RXMARK_OFST 84
#define SPI_RXMARK_RSTV 0x00000000
#define SPI_RXMARK_MASK 0x0000000F

#define SPI_FCTRL_OFST 96
#define SPI_FCTRL_RSTV 0x00000001
#define SPI_FCTRL_MASK 0x00000001

#define SPI_FFMT_OFST 100
#define SPI_FFMT_RSTV 0x00030007
#define SPI_FFMT_MASK 0xffff3fff

#define SPI_IE_OFST 112
#define SPI_IE_RSTV 0x00000000
#define SPI_IE_MASK 0x00000003

#define SPI_IP_OFST 116
#define SPI_IP_RSTV 0x00000000
#define SPI_IP_MASK 0x00000003

#define SPI_BIT_IRQ_TXWM 0
#define SPI_BIT_IRQ_RXWM 1

#define SPI_BIT_FMT_PROTO 0
#define SPI_BIT_FMT_ENDIAN 2
#define SPI_BIT_FMT_DIR 3
#define SPI_BIT_FMT_LEN 16

#define SPI_MASK_FMT_PROTO  0x00000003
#define SPI_MASK_FMT_ENDIAN 0x00000004
#define SPI_MASK_FMT_DIR    0x00000008
#define SPI_MASK_FMT_LEN    0x000f0000

#define SPI_CSMODE_AUTO 0
#define SPI_CSMODE_HOLD 2
#define SPI_CSMODE_OFF  3

#define SPI_PROTO_SINGLE 0
#define SPI_PROTO_DUAL   1
#define SPI_PROTO_QUAD   2

#define SPI_DIR_RX 0
#define SPI_DIR_TX 1

#define SPI_ENDIAN_MSBF 0
#define SPI_ENDIAN_LSBF 1

#define SPI_BIT_FFMT_CMD_EN 0
#define SPI_BIT_FFMT_ADDR_LEN 1
#define SPI_BIT_FFMT_PAD_CNT 4
#define SPI_BIT_FFMT_CMD_PROTO 8
#define SPI_BIT_FFMT_ADDR_PROTO 10
#define SPI_BIT_FFMT_DATA_PROTO 12
#define SPI_BIT_FFMT_CMD_CODE 16
#define SPI_BIT_FFMT_PAD_CODE 24

# -----------------------------------------------
# GPIO0
# -----------------------------------------------
# The memory map is listed below. For complete periph IP reference
# see "SiFive E300 Platform Reference Manual"
#
# Memory map:
#   0x10012000 value    Pin value
#   0x10012004 inen     Pin input enable
#   0x10012008 outen    Pin output enable
#   0x1001200c port     Output port value
#   0x10012010 pue      Pull up enable
#   0x10012014 ds       Drive strength 
#   0x10012018 rise_ie  Rise interrupt enable
#   0x1001201c rise_ip  Rise interrupt pending
#   0x10012020 fall_ie  Fall interrupt enable
#   0x10012024 fall_ip  Fall interrupt pending
#   0x10012028 high_ie  High interrupt enable
#   0x1001202c high_ip  High interrupt pending
#   0x10012030 low_ie   Low interrupt enable
#   0x10012034 low_ip   Low interrupt pending
#   0x10012038 iofen    IOF enable
#   0x1001203c iofsel   IOF select
#   0x10012040 outxor   Ouput XOR mask
#
# IOF Map:
#   IO  0   1:PWM0(0)
#   IO  1   1:PWM0(1)
#   IO  2   1:PWM0(2)
#   IO  3   1:PWM0(3)
#TODO   IO 10   1:PWM1(0)
#TODO   IO 11   1:PWM1(1)
#TODO   IO 12   1:PWM1(2)
#TODO   IO 13   1:PWM1(3)
#   IO 16   0:UART0 RxD
#   IO 17   0:UART0 TxD
#TODO   IO 19   1:PWM2(1)
#TODO   IO 20   1:PWM2(0)
#TODO   IO 21   1:PWM2(2)
#TODO   IO 22   1:PWM2(3)

#define GPIO0_BASE 0x10012000

#define GPIO_VALUE_OFST 0
#define GPIO_VALUE_RSTV 0x00000000
#define GPIO_VALUE_MASK 0xffffffff

#define GPIO_INEN_OFST 4
#define GPIO_INEN_RSTV 0x00000000
#define GPIO_INEN_MASK 0xffffffff

#define GPIO_OUTEN_OFST 8
#define GPIO_OUTEN_RSTV 0x00000000
#define GPIO_OUTEN_MASK 0xffffffff

#define GPIO_PORT_OFST 12
#define GPIO_PORT_RSTV 0x00000000
#define GPIO_PORT_MASK 0xffffffff

#define GPIO_PUE_OFST 16
#define GPIO_PUE_RSTV 0x00000000
#define GPIO_PUE_MASK 0xffffffff

#define GPIO_DS_OFST 20
#define GPIO_DS_RSTV 0x00000000
#define GPIO_DS_MASK 0xffffffff

#define GPIO_RIE_OFST 24
#define GPIO_RIE_RSTV 0x00000000
#define GPIO_RIE_MASK 0xffffffff

#define GPIO_RIP_OFST 28
#define GPIO_RIP_RSTV 0x00000000
#define GPIO_RIP_MASK 0xffffffff

#define GPIO_FIE_OFST 32
#define GPIO_FIE_RSTV 0x00000000
#define GPIO_FIE_MASK 0xffffffff

#define GPIO_FIP_OFST 36
#define GPIO_FIP_RSTV 0x00000000
#define GPIO_FIP_MASK 0xffffffff

#define GPIO_HIE_OFST 40
#define GPIO_HIE_RSTV 0x00000000
#define GPIO_HIE_MASK 0xffffffff

#define GPIO_HIP_OFST 44
#define GPIO_HIP_RSTV 0x00000000
#define GPIO_HIP_MASK 0xffffffff

#define GPIO_LIE_OFST 48
#define GPIO_LIE_RSTV 0x00000000
#define GPIO_LIE_MASK 0xffffffff

# The Low interrupt pending defaults to all-1 as inputs
# are disabled and hence resolve to logic 0.
#define GPIO_LIP_OFST 52
#define GPIO_LIP_RSTV 0xFFFFFFFF
#define GPIO_LIP_MASK 0xffffffff

#define GPIO_IOFEN_OFST 56
#define GPIO_IOFEN_RSTV 0x00000000
#define GPIO_IOFEN_MASK 0xffffffff

#define GPIO_IOFSEL_OFST 60
#define GPIO_IOFSEL_RSTV 0x00000000
#define GPIO_IOFSEL_MASK 0xffffffff

#define GPIO_XOR_OFST 64
#define GPIO_XOR_RSTV 0x00000000
#define GPIO_XOR_MASK 0xffffffff

# -----------------------------------------------
# UART0
# -----------------------------------------------
# The memory map is listed below. For complete periph IP reference
# see "SiFive E300 Platform Reference Manual"
#
# Memory map:
#   0x10013000 txdata Transmit data 
#   0x10013004 rxdata Receive data
#   0x10013008 txctrl Transmit control
#   0x1001300c rxctrl Receive control
#   0x10013010 ie UART interrupt enable
#   0x10013014 ip UART interrupt pending
#   0x10013018 div Baud rate divisor

#define UART0_BASE 0x10013000

#define UART_TXDATA_OFST 0
#define UART_TXDATA_RSTV 0x00000000
#define UART_TXDATA_MASK 0x800000FF

#define UART_RXDATA_OFST 4
#define UART_RXDATA_RSTV 0x80000000
#define UART_RXDATA_MASK 0x800000FF

#define UART_TXCTRL_OFST 8
#define UART_TXCTRL_RSTV 0x00000000
#define UART_TXCTRL_MASK 0x000F0003

#define UART_RXCTRL_OFST 12
#define UART_RXCTRL_RSTV 0x00000000
#define UART_RXCTRL_MASK 0x000F0001

#define UART_IE_OFST 16
#define UART_IE_RSTV 0x00000000
#define UART_IE_MASK 0x00000003

#define UART_IP_OFST 20
#define UART_IP_RSTV 0x00000000
#define UART_IP_MASK 0x00000003

#define UART_DIV_OFST 24
#define UART_DIV_RSTV 0x0000021e
#define UART_DIV_MASK 0x0000ffff

# -----------------------------------------------
# PWM0
# -----------------------------------------------
# The memory map is listed below. For complete periph IP reference
# see "SiFive FE310-G000 Manual v2p3"
#
# Memory map:
#   0x10015000 pwmcfg   PWM configuration 
#   0x10015008 pwmcount PWM count
#   0x10015010 pwms     PWM scaled
#   0x10015020 pwmcmp0  PWM compare 0
#   0x10015024 pwmcmp1  PWM compare 1
#   0x10015028 pwmcmp2  PWM compare 2
#   0x1001502c pwmcmp3  PWM compare 3

#define PWM0_BASE 0x10015000
#define PWM1_BASE 0x10025000
#define PWM2_BASE 0x10035000

#ifndef PWM_CMPWIDTH
#define PWM_CMPWIDTH 8
#endif

# The reset value of IP bits is 1 as defined by the reset value of
# other registers and the compare function.
#define PWM_CFG_OFST 0
#define PWM_CFG_RSTV 0xF0000000
#define PWM_CFG_MASK 0xFF0F370F

#define PWM_CNT_OFST 8
#define PWM_CNT_RSTV 0x00000000
#define PWM_CNT_MASK ((1 << (15+PWM_CMPWIDTH))-1)

#define PWM_SCALED_OFST 16
#define PWM_SCALED_RSTV 0x00000000
#define PWM_SCALED_MASK ((1 << PWM_CMPWIDTH)-1)

#define PWM_CMP0_OFST 32
#define PWM_CMP0_RSTV 0x00000000
#define PWM_CMP0_MASK ((1 << PWM_CMPWIDTH)-1)

#define PWM_CMP1_OFST 36
#define PWM_CMP1_RSTV 0x00000000
#define PWM_CMP1_MASK ((1 << PWM_CMPWIDTH)-1)

#define PWM_CMP2_OFST 40
#define PWM_CMP2_RSTV 0x00000000
#define PWM_CMP2_MASK ((1 << PWM_CMPWIDTH)-1)

#define PWM_CMP3_OFST 44
#define PWM_CMP3_RSTV 0x00000000
#define PWM_CMP3_MASK ((1 << PWM_CMPWIDTH)-1)

#define PWM_BIT_CFG_SCALE 0
#define PWM_BIT_CFG_SCALE_HI 3
#define PWM_BIT_CFG_STICKY 8
#define PWM_BIT_CFG_ZEROCMP 9
#define PWM_BIT_CFG_DEGLITCH 10
#define PWM_BIT_CFG_ENALWAYS 12
#define PWM_BIT_CFG_ENONESHOT 13
#define PWM_BIT_CFG_CMP0CENTER 16
#define PWM_BIT_CFG_CMP1CENTER 17
#define PWM_BIT_CFG_CMP2CENTER 18
#define PWM_BIT_CFG_CMP3CENTER 19
#define PWM_BIT_CFG_CMP0GANG 24
#define PWM_BIT_CFG_CMP1GANG 25
#define PWM_BIT_CFG_CMP2GANG 26
#define PWM_BIT_CFG_CMP3GANG 27
#define PWM_BIT_CFG_CMP0IP 28
#define PWM_BIT_CFG_CMP1IP 29
#define PWM_BIT_CFG_CMP2IP 30
#define PWM_BIT_CFG_CMP3IP 31

#endif
