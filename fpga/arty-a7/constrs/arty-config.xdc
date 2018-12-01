# Copyright 2017 Silicon Integrated Microelectronics, Inc.
#
# See LICENSE for license details.
#
# Source code origin: https://github.com/SI-RISCV/e200_opensource

set_property -dict [list \
  CONFIG_VOLTAGE {3.3} \
  CFGBVS {VCCO} \
  BITSTREAM.CONFIG.SPI_BUSWIDTH {4} \
  ] [current_design]
