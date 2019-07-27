RISC-V ISA Tests
================

This folder is a modified subset of `riscv-tests` (riscv/riscv-tests) used for ISA compliance.
It is used both for ISA compliance testing and for debugging (especially the code under `soc/`).

The code base came from some version of https://github.com/SI-RISCV/e200_opensource and was
adapted to zero-riscy/ibex.

Setup
-----

It is recommended to export environment variables pointing to RISC-V GCC binaries:

    # Export path to individual binaries
    export RISCV_GCC=/some/path/to/riscv-none-embed-gcc
    export RISCV_OBJDUMP=/some/path/to/riscv-none-embed-objdump
    export RISCV_OBJCOPY=/some/path/to/riscv-none-embed-objcopy
    
    # --OR--
    # Alternatively export the path prefix
    export RISCV_PREFIX=/some/path/to/riscv-none-embed-

It is possible to go without exports but you may need to supply the path overrides
when calling `make`, for example:

    make build RISCV_PREFIX=/some/path/to/riscv-none-embed-

Building
--------

    # Create and enter a build directory.
    mkdir build-dir
    cd build-dir

    # Rebuild all tests (the `-B` option is to force rebuild)
    make -B -f ../Makefile src_dir=..
    
    # Rebuild specific test (the `-B` option is to force rebuild)
    make -B -f ../Makefile src_dir=.. rv32ui-p-add.dump

