Prebuild bitstream with the `hello_world` binary included. There is one
small change for th ebuild (using the fix to riscv-dbg submitted in
https://github.com/pulp-platform/riscv-dbg/pull/27).

After programming, it shall print `Hello world!` over UART at 115.2 kbps:

    # to exit mincom use Ctlr+A and X
    sudo minicom -b 115200 --device /dev/ttyUSB1

To connect through debugger:

    # in one terminal run OpenOCD
    openocd -f openocd.cfg
    
    # in another terminal run riscv GDB
    $RISCV_GDB -ex "set remotetimeout 240" -ex "target extended-remote localhost:3333" hello_world.elf

