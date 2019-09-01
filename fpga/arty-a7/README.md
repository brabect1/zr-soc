Digilent Arty-A7 Implementation of zr-soc
=========================================

This FPGA implementation is a simple wrapper of the `zr_soc` module. Pin assignment
is compatible (for the implemented function subset) with SiFive's Freedom Arty system.

Build
-----

Presently the build process is semi-automated. The provided makefile sets up
a Xilinx Vivado GUI project. It is then up to the user to finish the design
flow (i.e. simulate, synthesize and implement).

Vivado project is set up using Verilog/SystemVerilog files from under
`fpga/arty-a7/rtl/` and any other RTL files given through `VSRC` environment
variable. When using the makefile, the user may set either `VSRC` (through
`make setup VSRC=...`) or provide an RTL file list (through `make setup FLIST=...`).

A file list for the default `zr_soc` build is provided in `rtl/files.txt`. Hence
running the default build is no more than:

    make setup FLIST=../../rtl/files.txt

To generate an FPGA build with the program memory pre-loaded with a compiled
code, use the `TCM_INIT` makefile setting to point to a formatted program
memory contents.

The FPGA project comes with an example application in `sw/hello_world.S`. To
compile it be sure to have defined path to GCC toolchain through `RISCV_...`
environment variables (or set them when calling the makefile, e.g.
`make RISCV_GCC=... RISCV_OBJDUMP=... ...`):

    # compile the sample hello_world application
    (cd sw && make)

Now pass the generated `.bram_tcm` to the FPGA build:

    # generate FPGA build with the hello_world application
    make setup FLIST=../../rtl/files.txt TCM_INIT=sw/hello_world.bram_tcm

