/*
Copyright 2018 Tomas Brabec

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

Change log:
    2018, Nov., Tomas Brabec
    - Created.
*/

`timescale 1ns/1ps

module arty_a7_shell (
    input wire clk_100M,
    input wire ck_rst_n,

    // Green LEDs
    // (making "inout" for readback of the actual value through the GPIO interface)
    inout wire [3:0] led,

    // RGB LEDs, 3 pins each
    // (making "inout" for readback of the actual value through the GPIO interface)
    inout wire [2:0] r_led,
    inout wire [2:0] g_led,
    inout wire [2:0] b_led,

    // Sliding switches.
    input  logic[3:0] sw,

    // Buttons.
    input logic[3:0] btn,

    // Dedicated QSPI interface
    output logic        qspi_cs,
    output logic        qspi_sck,
    inout  wire [3:0]   qspi_dq,

//    // JD (used for JTAG connection)
////    input wire jd_6, // SRST_n
////    inout wire jd_1, // TRST_n
//    inout wire jtag_tdo, // TDO
//    inout wire jtag_tck, // TCK
//    inout wire jtag_tdi, // TDI
//    inout wire jtag_tms  // TMS

    // UART0 (connected to micro USB)
    input  logic uart_rxd,
    output logic uart_txd
);

wire clk_16M;
wire mmcm_locked;

wire rst_periph;

localparam logic[31:0] TCM_ADDR_BASE = 32'h8000_0000;
//localparam logic[31:0] TCM_ADDR_MASK = 32'h0000_3fff;
localparam int TCM_AWIDTH = 15;

logic[31:0] io_gpio_i;
logic[31:0] io_gpio_o;
logic[31:0] io_gpio_oe;
logic[31:0] io_gpio_pue;

logic[3:0] io_qspi_dq_o;
logic[3:0] io_qspi_dq_oe;


// Mirror outputs of GPIOs with PWM peripherals to RGB LEDs on Arty
// assign RGB LED0 R,G,B inputs = PWM0(1,2,3) when iof_1 is active
assign r_led[0] = io_gpio_oe[1] ? io_gpio_o[1] : 1'bz;
assign g_led[0] = io_gpio_oe[2] ? io_gpio_o[2] : 1'bz;
assign b_led[0] = io_gpio_oe[3] ? io_gpio_o[3] : 1'bz;

// Note that this is the one which is actually connected on the HiFive/Crazy88
// Board. Same with RGB LED1 R,G,B inputs = PWM1(1,2,3) when iof_1 is active
assign r_led[1] = io_gpio_oe[21] ? io_gpio_o[21] : 1'bz;
assign g_led[1] = io_gpio_oe[22] ? io_gpio_o[22] : 1'bz;
assign b_led[1] = io_gpio_oe[23] ? io_gpio_o[23] : 1'bz;

// and RGB LED2 R,G,B inputs = PWM2(1,2,3) when iof_1 is active
assign r_led[2] = io_gpio_oe[13] ? io_gpio_o[13] : 1'bz;
assign g_led[2] = io_gpio_oe[14] ? io_gpio_o[14] : 1'bz;
assign b_led[2] = io_gpio_oe[15] ? io_gpio_o[15] : 1'bz;

// Use the LEDs for some more useful debugging things.
assign led[0] = io_gpio_oe[4] ? io_gpio_o[4] : 1'bz;
assign led[1] = io_gpio_oe[5] ? io_gpio_o[5] : 1'bz;
assign led[2] = io_gpio_oe[6] ? io_gpio_o[6] : 1'bz;
assign led[3] = io_gpio_oe[7] ? io_gpio_o[7] : 1'bz;

PULLDOWN u_pd_led[3:0]( .O(led) );

// UART output
assign uart_txd = io_gpio_oe[17] ? io_gpio_o[17] : 1'bz;


assign io_gpio_i = '{
     1: r_led[0],
     2: g_led[0],
     3: b_led[0],
     4: led[0],
     5: led[1],
     6: led[2],
     7: led[3],
     8: btn[0],
     9: btn[1],
    10: btn[2],
    11: btn[3],
    13: r_led[2],
    14: g_led[2],
    15: b_led[2],
    16: uart_rxd,
    21: r_led[1],
    22: g_led[1],
    23: b_led[1],
    24: sw[0],
    25: sw[1],
    26: sw[2],
    27: sw[3],
//    30: btn[1],
//    31: btn[2],
    default: 1'b0
};


// ----------------------------------------------
// System on Chip
// ----------------------------------------------
zr_soc #(
    .RV32E(0),
    .RV32M(1),
`ifdef TCM_INIT_FILE
    .TCM_INIT_FILE(`TCM_INIT_FILE),
`endif
    .TCM_ADDR_BASE(TCM_ADDR_BASE),
//    .TCM_ADDR_MASK(TCM_ADDR_MASK),
    .TCM_AWIDTH(TCM_AWIDTH),
    .BOOT_ADDR(TCM_ADDR_BASE)
) u_soc (
    .irq_i      ( 1'b0 ),
    .irq_id_i   ( '0 ),
    .irq_ack_o  ( ),
    .irq_id_o   ( ),

    .io_gpio_ds ( ),

    .io_qspi_sck_o      ( qspi_sck ),
    .io_qspi_sck_oe     ( ),
    .io_qspi_sck_pue    ( ),
    .io_qspi_cs_0_o     ( qspi_cs ),
    .io_qspi_cs_0_oe    ( ),
    .io_qspi_cs_0_pue   ( ),
    .io_qspi_dq_i       ( qspi_dq ),
    .io_qspi_dq_pue     ( ),

    .clk(clk_16M),
    .rst_n(rst_n),
    
    .*
);


// ----------------------------------------------
// Clock & Reset
// ----------------------------------------------

mmcm u_ip_mmcm (
    .clk_in1(clk_100M),
    //.clk_out1(clk_8388), // 8.388 MHz = 32.768 kHz * 256
    .clk_out1(), // 8.388 MHz = 32.768 kHz * 256
    //.clk_out2(), // 65 MHz
    .clk_out2(clk_16M), // 16 MHz, this clock we set to 16MHz on Arty board
    .resetn(ck_rst_n),
    .locked(mmcm_locked)
);

reset_sys u_ip_reset_sys (
    .slowest_sync_clk(clk_16M),
    //.ext_reset_in(ck_rst & SRST_n), // Active-low
    .ext_reset_in(ck_rst_n), // Active-low
    .aux_reset_in(1'b1),
    .mb_debug_sys_rst(1'b0),
    .dcm_locked(mmcm_locked),
    .mb_reset(),
    .bus_struct_reset(),
    .peripheral_reset(),
    .interconnect_aresetn(),
    .peripheral_aresetn(rst_n)
);

// ----------------------------------------------
// QSPI Flash Interface
// ----------------------------------------------

//---->>>> Pull ups defined in XDC physical constraints. No need for them here.
//PULLUP u_pu_qspi_dq[3:0] ( .O(qspi_dq) );
//<<<<----

for (genvar i=0; i < $size(qspi_dq); i++)
    assign qspi_dq[i] = io_qspi_dq_oe[i] ? io_qspi_dq_o[i] : 1'bz;

endmodule
