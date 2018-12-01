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

wait_loop:
    .rept 32
        1: bnez x0,1b
    .endr
    j wait_loop

    # Test End
    TEST_PASSFAIL


RVTEST_CODE_END

.data
RVTEST_DATA_BEGIN

TEST_DATA

#data1: .word 0
#data2: .word 0

RVTEST_DATA_END

