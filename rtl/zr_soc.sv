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

module zr_soc #(
    parameter int RV32E = 0,
    parameter int RV32M = 1,
    parameter bit[200*8-1:0] TCM_INIT_FILE = '0,           // Specify name/location of RAM initialization file if using one (leave blank if not)
    parameter logic[31:0] TCM_ADDR_BASE = 32'h8000_0000,
//    parameter logic[31:0] TCM_ADDR_MASK = 32'h0000_3fff,
    parameter int TCM_AWIDTH = 15, // number of address LSBs to use for TCM addressing
    parameter logic[31:0] BOOT_ADDR = TCM_ADDR_BASE
) (
    input  logic[31:0] io_gpio_i,
    output logic[31:0] io_gpio_o,
    output logic[31:0] io_gpio_oe,
    output logic[31:0] io_gpio_pue,
    output logic[31:0] io_gpio_ds,

    output logic      io_qspi_sck_o,
    output logic      io_qspi_sck_oe,
    output logic      io_qspi_sck_pue,
    output logic      io_qspi_cs_0_o,
    output logic      io_qspi_cs_0_oe,
    output logic      io_qspi_cs_0_pue,
    input  logic[3:0] io_qspi_dq_i,
    output logic[3:0] io_qspi_dq_o,
    output logic[3:0] io_qspi_dq_oe,
    output logic[3:0] io_qspi_dq_pue,

    input  logic clk,
    input  logic rst_n
);

// Instruction peripheral bus
logic       pi_icb_cmd_valid;
logic       pi_icb_cmd_ready;
logic[31:0] pi_icb_cmd_addr;
logic       pi_icb_rsp_valid;
logic       pi_icb_rsp_ready;
logic[31:0] pi_icb_rsp_rdata;

// Data peripheral bus
logic       pd_icb_cmd_valid;
logic       pd_icb_cmd_ready;
logic       pd_icb_cmd_read;
logic[31:0] pd_icb_cmd_addr;
logic[31:0] pd_icb_cmd_wdata;
logic[ 3:0] pd_icb_cmd_wmask;
logic       pd_icb_rsp_valid;
logic       pd_icb_rsp_ready;
logic[31:0] pd_icb_rsp_rdata;
logic       pd_icb_rsp_err;

// ----------------------------------------------
// CPU Coreplex
// ----------------------------------------------
zr_coreplex #(
    .RV32E(0),
    .RV32M(1),
    .TCM_INIT_FILE(TCM_INIT_FILE),
    .TCM_ADDR_BASE(TCM_ADDR_BASE),
//    .TCM_ADDR_MASK(TCM_ADDR_MASK),
    .TCM_AWIDTH(TCM_AWIDTH),
    .BOOT_ADDR(BOOT_ADDR)
) u_cpu (
    // interrupts - tie off for now 
    .irq_software_i(1'b0),
    .irq_timer_i(1'b0),
    .irq_external_i(1'b0),
    .irq_fast_i('0),
    .irq_nm_i(1'b0),       // non-maskeable interrupt

    // jtag debug interface - tie off for now
    .tck(1'b0),    // JTAG test clock pad
    .tms(1'b0),    // JTAG test mode select pad
    .trstn(1'b0),  // JTAG test reset pad
    .tdi(1'b0),    // JTAG test data input pad
    .tdo_o(    ),  // JTAG test data output pad
    .tdo_t(    ),  // Data out output enable
    .pi_icb_rsp_err(1'b0),
    .*
);


// ----------------------------------------------
// Peripheral Subsystem
// ----------------------------------------------

logic       qspi0_irq;
logic       uart0_irq;
logic[ 3:0] pwm0_irqs;
logic[31:0] gpio_irq;

logic[31:0] gpio_i;
logic[31:0] gpio_ie;

assign gpio_i = io_gpio_i & gpio_ie;

e203_subsys_perips u_ppi(
    .ppi_icb_cmd_valid( pd_icb_cmd_valid ),
    .ppi_icb_cmd_ready( pd_icb_cmd_ready ),
    .ppi_icb_cmd_addr ( pd_icb_cmd_addr  ), 
    .ppi_icb_cmd_read ( pd_icb_cmd_read  ), 
    .ppi_icb_cmd_wdata( pd_icb_cmd_wdata ),
    .ppi_icb_cmd_wmask( pd_icb_cmd_wmask ),

    .ppi_icb_rsp_valid( pd_icb_rsp_valid ),
    .ppi_icb_rsp_ready( pd_icb_rsp_ready ),
    .ppi_icb_rsp_err  ( pd_icb_rsp_err   ),
    .ppi_icb_rsp_rdata( pd_icb_rsp_rdata ),
  
    .qspi0_ro_icb_cmd_valid( pi_icb_cmd_valid ),
    .qspi0_ro_icb_cmd_ready( pi_icb_cmd_ready ),
    .qspi0_ro_icb_cmd_addr ( pi_icb_cmd_addr  ), 
    .qspi0_ro_icb_cmd_read ( 1'b1             ), 
    .qspi0_ro_icb_cmd_wdata( '0               ),

    .qspi0_ro_icb_rsp_valid( pi_icb_rsp_valid ),
    .qspi0_ro_icb_rsp_ready( pi_icb_rsp_ready ),
    .qspi0_ro_icb_rsp_rdata( pi_icb_rsp_rdata ),

    .io_pads_gpio_i_ival( gpio_i ),
    .io_pads_gpio_o_oval( io_gpio_o ),
    .io_pads_gpio_o_oe  ( io_gpio_oe ),
    .io_pads_gpio_o_ie  ( gpio_ie ),
    .io_pads_gpio_o_pue ( io_gpio_pue ),
    .io_pads_gpio_o_ds  ( io_gpio_ds  ),

    .io_pads_qspi_sck_o_oval ( io_qspi_sck_o   ),
    .io_pads_qspi_sck_o_oe   ( io_qspi_sck_oe  ),
    .io_pads_qspi_sck_o_pue  ( io_qspi_sck_pue ),
    .io_pads_qspi_cs_0_o_oval( io_qspi_cs_0_o  ),
    .io_pads_qspi_cs_0_o_oe  ( io_qspi_cs_0_oe ),
    .io_pads_qspi_cs_0_o_pue ( io_qspi_cs_0_pue),
    .io_pads_qspi_dq_i_ival  ( io_qspi_dq_i    ),
    .io_pads_qspi_dq_o_oval  ( io_qspi_dq_o    ),
    .io_pads_qspi_dq_o_oe    ( io_qspi_dq_oe   ),
    .io_pads_qspi_dq_o_ie    (                 ),
    .io_pads_qspi_dq_o_pue   ( io_qspi_dq_pue  ),

    .qspi0_irq( qspi0_irq ),
    .uart0_irq( uart0_irq ),
    .pwm0_irqs( pwm0_irqs ),
    .gpio_irq ( gpio_irq  ),

    .pllbypass(),
    .pll_RESET(),
    .pll_ASLEEP(),
    .pll_OD(),
    .pll_M(),
    .pll_N(),
    .plloutdivby1(),
    .plloutdiv(),

    .hfxoscen( ),
    .clk( clk ),
    .rst_n( rst_n )
);

endmodule: zr_soc
