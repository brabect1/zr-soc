#include "riscv_test.h"
#undef RVTEST_RV64M
#define RVTEST_RV64M RVTEST_RV32M

#include "test_macros.h"
#include "soc.h"

#define DTM_BASE 0x00004000

#define DTM_IEN_OFST 24
#define DTM_IEN_RSTV 0x00000000
#define DTM_IEN_MASK 0x00000001

RVTEST_RV32M
RVTEST_CODE_BEGIN

#    # Enable Debug Interrupts
#    li x5, DTM_BASE
#    li x6, -1
#    sw x6, DTM_IEN_OFST(x5)

    # Rationale behind the following loop for debugging the Debug interface:
    # - Have a register increment to see the change is reflected in register info.
    # - Have several NOPs to exercise stepping or setting breakpoints.
infi:
    addi x3,x3,1
    nop
    nop
    nop
    j infi

    # Test End
    TEST_PASSFAIL


RVTEST_CODE_END

.data
RVTEST_DATA_BEGIN

TEST_DATA

#data1: .word 0
#data2: .word 0

RVTEST_DATA_END

