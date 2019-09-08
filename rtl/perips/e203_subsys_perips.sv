 /*                                                                      
 Copyright 2017 Silicon Integrated Microelectronics, Inc.                
                                                                         
 Licensed under the Apache License, Version 2.0 (the "License");         
 you may not use this file except in compliance with the License.        
 You may obtain a copy of the License at                                 
                                                                         
     http://www.apache.org/licenses/LICENSE-2.0                          
                                                                         
  Unless required by applicable law or agreed to in writing, software    
 distributed under the License is distributed on an "AS IS" BASIS,       
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and     
 limitations under the License.                                          
 */                                                                      
                                                                         
                                                                         
                                                                         
module e203_subsys_perips(
  input                          ppi_icb_cmd_valid,
  output                         ppi_icb_cmd_ready,
  input  [31:0]                  ppi_icb_cmd_addr, 
  input                          ppi_icb_cmd_read, 
  input  [31:0]                  ppi_icb_cmd_wdata,
  input  [3:0]                   ppi_icb_cmd_wmask,
  //
  output                         ppi_icb_rsp_valid,
  input                          ppi_icb_rsp_ready,
  output                         ppi_icb_rsp_err,
  output [31:0]                  ppi_icb_rsp_rdata,
  
//  //////////////////////////////////////////////////////////
//  output                         aon_icb_cmd_valid,
//  input                          aon_icb_cmd_ready,
//  output [`E203_ADDR_SIZE-1:0]   aon_icb_cmd_addr, 
//  output                         aon_icb_cmd_read, 
//  output [`E203_XLEN-1:0]        aon_icb_cmd_wdata,
//  //
//  input                          aon_icb_rsp_valid,
//  output                         aon_icb_rsp_ready,
//  input                          aon_icb_rsp_err,
//  input  [`E203_XLEN-1:0]        aon_icb_rsp_rdata,

  input                      qspi0_ro_icb_cmd_valid,
  output                     qspi0_ro_icb_cmd_ready,
  input  [32-1:0]            qspi0_ro_icb_cmd_addr, 
  input                      qspi0_ro_icb_cmd_read, 
  input  [32-1:0]            qspi0_ro_icb_cmd_wdata,
  
  output                     qspi0_ro_icb_rsp_valid,
  input                      qspi0_ro_icb_rsp_ready,
  output [32-1:0]            qspi0_ro_icb_rsp_rdata,


  input  [31:0] io_pads_gpio_i_ival,
  output [31:0] io_pads_gpio_o_oval,
  output [31:0] io_pads_gpio_o_oe,
  output [31:0] io_pads_gpio_o_ie,
  output [31:0] io_pads_gpio_o_pue,
  output [31:0] io_pads_gpio_o_ds,

  output  io_pads_qspi_sck_o_oval,
  output  io_pads_qspi_sck_o_oe,
  output  io_pads_qspi_sck_o_pue,
  output  io_pads_qspi_cs_0_o_oval,
  output  io_pads_qspi_cs_0_o_oe,
  output  io_pads_qspi_cs_0_o_pue,
  input  [3:0] io_pads_qspi_dq_i_ival,
  output [3:0] io_pads_qspi_dq_o_oval,
  output [3:0] io_pads_qspi_dq_o_oe,
  output [3:0] io_pads_qspi_dq_o_ie,
  output [3:0] io_pads_qspi_dq_o_pue,

  output qspi0_irq, 

  output uart0_irq,                

  output [3:0] pwm0_irqs,

  output [31:0]gpio_irq,

  output pllbypass ,
  output pll_RESET ,
  output pll_ASLEEP ,
  output [1:0]  pll_OD,
  output [7:0]  pll_M,
  output [4:0]  pll_N,
  output plloutdivby1,
  output [5:0] plloutdiv,

  output hfxoscen,



  input  clk,
  input  rst_n
  );

  
//  wire                         i_aon_icb_cmd_valid;
//  wire                         i_aon_icb_cmd_ready;
//  wire [31:0]                  i_aon_icb_cmd_addr; 
//  wire                         i_aon_icb_cmd_read; 
//  wire [31:0]                  i_aon_icb_cmd_wdata;
//
//  wire                         i_aon_icb_rsp_valid;
//  wire                         i_aon_icb_rsp_ready;
//  wire                         i_aon_icb_rsp_err;
//  wire [31:0]                  i_aon_icb_rsp_rdata;

  wire uart0_txd;
  wire uart0_rxd;

  wire [3:0] pwm0_gpio;

  wire qspi0_sck;
  wire qspi0_dq_0_i;
  wire qspi0_dq_0_o;
  wire qspi0_dq_0_oe;
  wire qspi0_dq_1_i;
  wire qspi0_dq_1_o;
  wire qspi0_dq_1_oe;
  wire qspi0_dq_2_i;
  wire qspi0_dq_2_o;
  wire qspi0_dq_2_oe;
  wire qspi0_dq_3_i;
  wire qspi0_dq_3_o;
  wire qspi0_dq_3_oe;
  wire qspi0_cs_0;


  wire [31:0]gpio_iof_0_i_ival   ;
  wire [31:0]gpio_iof_0_o_oval   ;
  wire [31:0]gpio_iof_0_o_oe   ;
  wire [31:0]gpio_iof_0_o_ie   ;
  wire [31:0]gpio_iof_0_o_valid   ;
  
  wire [31:0]gpio_iof_1_i_ival   ;
  wire [31:0]gpio_iof_1_o_oval   ;
  wire [31:0]gpio_iof_1_o_oe   ;
  wire [31:0]gpio_iof_1_o_ie   ;
  wire [31:0]gpio_iof_1_o_valid   ;

  assign gpio_iof_0_o_oval       = '{
      17: uart0_txd, // UART 0 Tx
      16: 1'b0, // UART 0 Rx
      default: 1'd0
  };

  assign gpio_iof_0_o_oe         = '{
      17: 1'b1, // UART 0 Tx
      16: 1'b0, // UART 0 Rx
      default: 1'd0
  };

  assign gpio_iof_0_o_ie         = '{
      17: 1'b0, // UART 0 Tx
      16: 1'b1, // UART 0 Rx
      default: 1'd0
  };

  assign gpio_iof_0_o_valid      = '{
      17: 1'h1, // UART 0 Tx
      16: 1'h1, // UART 0 Rx
      default: 1'd0
  };


  assign gpio_iof_1_o_oval       = '{
      3: pwm0_gpio[3], // PWM 0, channel 3
      2: pwm0_gpio[2], // PWM 0, channel 2
      1: pwm0_gpio[1], // PWM 0, channel 1
      0: pwm0_gpio[0], // PWM 0, channel 0
      default: 1'd0
  };

  assign gpio_iof_1_o_oe         = '{
      3: 1'b1, // PWM 0, channel 3
      2: 1'b1, // PWM 0, channel 2
      1: 1'b1, // PWM 0, channel 1
      0: 1'b1, // PWM 0, channel 0
      default: 1'd0
  };

  assign gpio_iof_1_o_ie         = '{
      3: 1'b0, // PWM 0, channel 3
      2: 1'b0, // PWM 0, channel 2
      1: 1'b0, // PWM 0, channel 1
      0: 1'b0, // PWM 0, channel 0
      default: 1'd0
  };

  assign gpio_iof_1_o_valid      = '{
      3: 1'h1, // PWM 0, channel 3
      2: 1'h1, // PWM 0, channel 2
      1: 1'h1, // PWM 0, channel 1
      0: 1'h1, // PWM 0, channel 0
      default: 1'd0
  };


  assign uart0_rxd = gpio_iof_0_i_ival[16];
//  assign uart_pins_0_io_pins_txd_i_ival = gpio_iof_0_i_ival[17];

//  assign pwm_pins_0_io_pins_pwm_0_i_ival = gpio_iof_1_i_ival[0];
//  assign pwm_pins_0_io_pins_pwm_1_i_ival = gpio_iof_1_i_ival[1];
//  assign pwm_pins_0_io_pins_pwm_2_i_ival = gpio_iof_1_i_ival[2];
//  assign pwm_pins_0_io_pins_pwm_3_i_ival = gpio_iof_1_i_ival[3];


  wire                   gpio_icb_cmd_valid;
  wire                   gpio_icb_cmd_ready;
  wire [31:0]            gpio_icb_cmd_addr; 
  wire                   gpio_icb_cmd_read; 
  wire [31:0]            gpio_icb_cmd_wdata;
  
  wire                   gpio_icb_rsp_valid;
  wire                   gpio_icb_rsp_ready;
  wire [31:0]            gpio_icb_rsp_rdata;

  wire                   uart0_icb_cmd_valid;
  wire                   uart0_icb_cmd_ready;
  wire [31:0]            uart0_icb_cmd_addr; 
  wire                   uart0_icb_cmd_read; 
  wire [31:0]            uart0_icb_cmd_wdata;
  
  wire                   uart0_icb_rsp_valid;
  wire                   uart0_icb_rsp_ready;
  wire [31:0]            uart0_icb_rsp_rdata;

  wire                   qspi0_icb_cmd_valid;
  wire                   qspi0_icb_cmd_ready;
  wire [31:0]            qspi0_icb_cmd_addr; 
  wire                   qspi0_icb_cmd_read; 
  wire [31:0]            qspi0_icb_cmd_wdata;
  
  wire                   qspi0_icb_rsp_valid;
  wire                   qspi0_icb_rsp_ready;
  wire [31:0]            qspi0_icb_rsp_rdata;

  wire                   pwm0_icb_cmd_valid;
  wire                   pwm0_icb_cmd_ready;
  wire [31:0]            pwm0_icb_cmd_addr; 
  wire                   pwm0_icb_cmd_read; 
  wire [31:0]            pwm0_icb_cmd_wdata;
  
  wire                   pwm0_icb_rsp_valid;
  wire                   pwm0_icb_rsp_ready;
  wire [31:0]            pwm0_icb_rsp_rdata;

  wire                   hclkgen_icb_cmd_valid;
  wire                   hclkgen_icb_cmd_ready;
  wire [31:0]            hclkgen_icb_cmd_addr; 
  wire                   hclkgen_icb_cmd_read; 
  wire [31:0]            hclkgen_icb_cmd_wdata;
  wire [41:0]            hclkgen_icb_cmd_wmask;
  
  wire                   hclkgen_icb_rsp_valid;
  wire                   hclkgen_icb_rsp_ready;
  wire [31:0]            hclkgen_icb_rsp_rdata;
  wire                   hclkgen_icb_rsp_err;

  // The total address range for the PPI is from/to
  //  **************0x1000 0000 -- 0x1FFF FFFF
  // There are several slaves for PPI bus, including:
  //  * AON       : 0x1000 0000 -- 0x1000 7FFF
  //  * HCLKGEN   : 0x1000 8000 -- 0x1000 8FFF
  //  * OTP       : 0x1001 0000 -- 0x1001 0FFF
  //  * GPIO      : 0x1001 2000 -- 0x1001 2FFF
  //  * UART0     : 0x1001 3000 -- 0x1001 3FFF
  //  * QSPI0     : 0x1001 4000 -- 0x1001 4FFF
  //  * PWM0      : 0x1001 5000 -- 0x1001 5FFF
  //  * UART1     : 0x1002 3000 -- 0x1002 3FFF
  //  * QSPI1     : 0x1002 4000 -- 0x1002 4FFF
  //  * PWM1      : 0x1002 5000 -- 0x1002 5FFF
  //  * QSPI2     : 0x1003 4000 -- 0x1003 4FFF
  //  * PWM2      : 0x1003 5000 -- 0x1003 5FFF
  //  * Example-AXI      : 0x1004 0000 -- 0x1004 0FFF
  //  * Example-APB      : 0x1004 1000 -- 0x1004 1FFF
  //  * Example-WishBone : 0x1004 2000 -- 0x1004 2FFF
  //  * SysPer    : 0x1100 0000 -- 0x11FF FFFF

  sirv_icb1to16_bus # (
  .ICB_FIFO_DP        (2),// We add a ping-pong buffer here to cut down the timing path
  .ICB_FIFO_CUT_READY (1),// We configure it to cut down the back-pressure ready signal

  .AW                   (32),
  .DW                   (32),
  .SPLT_FIFO_OUTS_NUM   (1),// The peirpherals only allow 1 oustanding
  .SPLT_FIFO_CUT_READY  (1),// The peirpherals always cut ready
  //  * AON       : 0x1000 0000 -- 0x1000 7FFF
  .O0_BASE_ADDR       (32'h1000_0000),       
  .O0_BASE_REGION_LSB (15),
  //  * HCLKGEN   : 0x1000 8000 -- 0x1000 8FFF
  .O1_BASE_ADDR       (32'h1000_8000),       
  .O1_BASE_REGION_LSB (12),
  //  * OTP       : 0x1001 0000 -- 0x1001 0FFF
  .O2_BASE_ADDR       (32'h1001_0000),       
  .O2_BASE_REGION_LSB (12),
  //  * GPIO      : 0x1001 2000 -- 0x1001 2FFF
  .O3_BASE_ADDR       (32'h1001_2000),       
  .O3_BASE_REGION_LSB (12),
  //  * UART0     : 0x1001 3000 -- 0x1001 3FFF
  .O4_BASE_ADDR       (32'h1001_3000),       
  .O4_BASE_REGION_LSB (12),
  //  * QSPI0     : 0x1001 4000 -- 0x1001 4FFF
  .O5_BASE_ADDR       (32'h1001_4000),       
  .O5_BASE_REGION_LSB (12),
  //  * PWM0      : 0x1001 5000 -- 0x1001 5FFF
  .O6_BASE_ADDR       (32'h1001_5000),       
  .O6_BASE_REGION_LSB (12),
  //  * UART1     : 0x1002 3000 -- 0x1002 3FFF
  .O7_BASE_ADDR       (32'h1002_3000),       
  .O7_BASE_REGION_LSB (12),
  //  * QSPI1     : 0x1002 4000 -- 0x1002 4FFF
  .O8_BASE_ADDR       (32'h1002_4000),       
  .O8_BASE_REGION_LSB (12),
  //  * PWM1      : 0x1002 5000 -- 0x1002 5FFF
  .O9_BASE_ADDR       (32'h1002_5000),       
  .O9_BASE_REGION_LSB (12),
  //  * QSPI2     : 0x1003 4000 -- 0x1003 4FFF
  .O10_BASE_ADDR       (32'h1003_4000),       
  .O10_BASE_REGION_LSB (12),
  //  * PWM2      : 0x1003 5000 -- 0x1003 5FFF
  .O11_BASE_ADDR       (32'h1003_5000),       
  .O11_BASE_REGION_LSB (12),
  //  * SysPer    : 0x1100 0000 -- 0x11FF FFFF
  .O12_BASE_ADDR       (32'h1100_0000),       
  .O12_BASE_REGION_LSB (24),

      // * Here is an example AXI Peripheral
  .O13_BASE_ADDR       (32'h1004_0000),       
  .O13_BASE_REGION_LSB (12),
  
      // * Here is an example APB Peripheral
  .O14_BASE_ADDR       (32'h1004_1000),       
  .O14_BASE_REGION_LSB (12),
  
      // * Here is an I2C WishBone Peripheral
  .O15_BASE_ADDR       (32'h1004_2000),       
  .O15_BASE_REGION_LSB (3)// I2C only have 3 bits address width

  )u_sirv_ppi_fab(

    .i_icb_cmd_valid  (ppi_icb_cmd_valid),
    .i_icb_cmd_ready  (ppi_icb_cmd_ready),
    .i_icb_cmd_addr   (ppi_icb_cmd_addr ),
    .i_icb_cmd_read   (ppi_icb_cmd_read ),
    .i_icb_cmd_wdata  (ppi_icb_cmd_wdata),
    .i_icb_cmd_wmask  (ppi_icb_cmd_wmask),
    .i_icb_cmd_lock   (1'b0),
    .i_icb_cmd_excl   (1'b0 ),
    .i_icb_cmd_size   (2'b0 ),
    .i_icb_cmd_burst  (2'b0 ),
    .i_icb_cmd_beat   (2'b0 ),
    
    .i_icb_rsp_valid  (ppi_icb_rsp_valid),
    .i_icb_rsp_ready  (ppi_icb_rsp_ready),
    .i_icb_rsp_err    (ppi_icb_rsp_err  ),
    .i_icb_rsp_excl_ok(),
    .i_icb_rsp_rdata  (ppi_icb_rsp_rdata),
    
  //  * AON 
    .o0_icb_enable     (1'b1),

        //
    .o0_icb_cmd_valid  (),
    .o0_icb_cmd_ready  (1'b1),
    .o0_icb_cmd_addr   (),
    .o0_icb_cmd_read   (),
    .o0_icb_cmd_wdata  (),
//    .o0_icb_cmd_valid  (i_aon_icb_cmd_valid),
//    .o0_icb_cmd_ready  (i_aon_icb_cmd_ready),
//    .o0_icb_cmd_addr   (i_aon_icb_cmd_addr ),
//    .o0_icb_cmd_read   (i_aon_icb_cmd_read ),
//    .o0_icb_cmd_wdata  (i_aon_icb_cmd_wdata),
    .o0_icb_cmd_wmask  (),
    .o0_icb_cmd_lock   (),
    .o0_icb_cmd_excl   (),
    .o0_icb_cmd_size   (),
    .o0_icb_cmd_burst  (),
    .o0_icb_cmd_beat   (),
    
    .o0_icb_rsp_valid  (1'b1),
    .o0_icb_rsp_ready  (),
    .o0_icb_rsp_err    (1'b1),
    .o0_icb_rsp_excl_ok(1'b0  ),
    .o0_icb_rsp_rdata  ('0),
//    .o0_icb_rsp_valid  (i_aon_icb_rsp_valid),
//    .o0_icb_rsp_ready  (i_aon_icb_rsp_ready),
//    .o0_icb_rsp_err    (i_aon_icb_rsp_err),
//    .o0_icb_rsp_excl_ok(1'b0  ),
//    .o0_icb_rsp_rdata  (i_aon_icb_rsp_rdata),

  //  * HCLKGEN      
    .o1_icb_enable     (1'b1),

    .o1_icb_cmd_valid  (hclkgen_icb_cmd_valid),
    .o1_icb_cmd_ready  (hclkgen_icb_cmd_ready),
    .o1_icb_cmd_addr   (hclkgen_icb_cmd_addr ),
    .o1_icb_cmd_read   (hclkgen_icb_cmd_read ),
    .o1_icb_cmd_wdata  (hclkgen_icb_cmd_wdata),
    .o1_icb_cmd_wmask  (),
    .o1_icb_cmd_lock   (),
    .o1_icb_cmd_excl   (),
    .o1_icb_cmd_size   (),
    .o1_icb_cmd_burst  (),
    .o1_icb_cmd_beat   (),
    
    .o1_icb_rsp_valid  (hclkgen_icb_rsp_valid),
    .o1_icb_rsp_ready  (hclkgen_icb_rsp_ready),
    .o1_icb_rsp_err    (1'b0  ),
    .o1_icb_rsp_excl_ok(1'b0  ),
    .o1_icb_rsp_rdata  (hclkgen_icb_rsp_rdata),

  //  * UNUSED (OTP)
    .o2_icb_enable     (1'b1),

    .o2_icb_cmd_valid  (),
    .o2_icb_cmd_ready  (1'b1),
    .o2_icb_cmd_addr   (),
    .o2_icb_cmd_read   (),
    .o2_icb_cmd_wdata  (),
    .o2_icb_cmd_wmask  (),
    .o2_icb_cmd_lock   (),
    .o2_icb_cmd_excl   (),
    .o2_icb_cmd_size   (),
    .o2_icb_cmd_burst  (),
    .o2_icb_cmd_beat   (),
    
    .o2_icb_rsp_valid  (1'b1),
    .o2_icb_rsp_ready  (),
    .o2_icb_rsp_err    (1'b1  ),
    .o2_icb_rsp_excl_ok(1'b0  ),
    .o2_icb_rsp_rdata  ('0),


  //  * GPIO      
    .o3_icb_enable     (1'b1),

    .o3_icb_cmd_valid  (gpio_icb_cmd_valid),
    .o3_icb_cmd_ready  (gpio_icb_cmd_ready),
    .o3_icb_cmd_addr   (gpio_icb_cmd_addr ),
    .o3_icb_cmd_read   (gpio_icb_cmd_read ),
    .o3_icb_cmd_wdata  (gpio_icb_cmd_wdata),
    .o3_icb_cmd_wmask  (),
    .o3_icb_cmd_lock   (),
    .o3_icb_cmd_excl   (),
    .o3_icb_cmd_size   (),
    .o3_icb_cmd_burst  (),
    .o3_icb_cmd_beat   (),
    
    .o3_icb_rsp_valid  (gpio_icb_rsp_valid),
    .o3_icb_rsp_ready  (gpio_icb_rsp_ready),
    .o3_icb_rsp_err    (1'b0  ),
    .o3_icb_rsp_excl_ok(1'b0  ),
    .o3_icb_rsp_rdata  (gpio_icb_rsp_rdata),


  //  * UART0     
    .o4_icb_enable     (1'b1),

    .o4_icb_cmd_valid  (uart0_icb_cmd_valid),
    .o4_icb_cmd_ready  (uart0_icb_cmd_ready),
    .o4_icb_cmd_addr   (uart0_icb_cmd_addr ),
    .o4_icb_cmd_read   (uart0_icb_cmd_read ),
    .o4_icb_cmd_wdata  (uart0_icb_cmd_wdata),
    .o4_icb_cmd_wmask  (),
    .o4_icb_cmd_lock   (),
    .o4_icb_cmd_excl   (),
    .o4_icb_cmd_size   (),
    .o4_icb_cmd_burst  (),
    .o4_icb_cmd_beat   (),
    
    .o4_icb_rsp_valid  (uart0_icb_rsp_valid),
    .o4_icb_rsp_ready  (uart0_icb_rsp_ready),
    .o4_icb_rsp_err    (1'b0  ),
    .o4_icb_rsp_excl_ok(1'b0  ),
    .o4_icb_rsp_rdata  (uart0_icb_rsp_rdata),


  //  * QSPI0     
    .o5_icb_enable     (1'b1),

    .o5_icb_cmd_valid  (qspi0_icb_cmd_valid),
    .o5_icb_cmd_ready  (qspi0_icb_cmd_ready),
    .o5_icb_cmd_addr   (qspi0_icb_cmd_addr ),
    .o5_icb_cmd_read   (qspi0_icb_cmd_read ),
    .o5_icb_cmd_wdata  (qspi0_icb_cmd_wdata),
    .o5_icb_cmd_wmask  (),
    .o5_icb_cmd_lock   (),
    .o5_icb_cmd_excl   (),
    .o5_icb_cmd_size   (),
    .o5_icb_cmd_burst  (),
    .o5_icb_cmd_beat   (),
    
    .o5_icb_rsp_valid  (qspi0_icb_rsp_valid),
    .o5_icb_rsp_ready  (qspi0_icb_rsp_ready),
    .o5_icb_rsp_err    (1'b0  ),
    .o5_icb_rsp_excl_ok(1'b0  ),
    .o5_icb_rsp_rdata  (qspi0_icb_rsp_rdata),


  //  * PWM0      
    .o6_icb_enable     (1'b1),

    .o6_icb_cmd_valid  (pwm0_icb_cmd_valid),
    .o6_icb_cmd_ready  (pwm0_icb_cmd_ready),
    .o6_icb_cmd_addr   (pwm0_icb_cmd_addr ),
    .o6_icb_cmd_read   (pwm0_icb_cmd_read ),
    .o6_icb_cmd_wdata  (pwm0_icb_cmd_wdata),
    .o6_icb_cmd_wmask  (),
    .o6_icb_cmd_lock   (),
    .o6_icb_cmd_excl   (),
    .o6_icb_cmd_size   (),
    .o6_icb_cmd_burst  (),
    .o6_icb_cmd_beat   (),
    
    .o6_icb_rsp_valid  (pwm0_icb_rsp_valid),
    .o6_icb_rsp_ready  (pwm0_icb_rsp_ready),
    .o6_icb_rsp_err    (1'b0  ),
    .o6_icb_rsp_excl_ok(1'b0  ),
    .o6_icb_rsp_rdata  (pwm0_icb_rsp_rdata),


  //  * UNUSED (UART1)
    .o7_icb_enable     (1'b1),

    .o7_icb_cmd_valid  (),
    .o7_icb_cmd_ready  (1'b1),
    .o7_icb_cmd_addr   (),
    .o7_icb_cmd_read   (),
    .o7_icb_cmd_wdata  (),
    .o7_icb_cmd_wmask  (),
    .o7_icb_cmd_lock   (),
    .o7_icb_cmd_excl   (),
    .o7_icb_cmd_size   (),
    .o7_icb_cmd_burst  (),
    .o7_icb_cmd_beat   (),
    
    .o7_icb_rsp_valid  (1'b1),
    .o7_icb_rsp_ready  (),
    .o7_icb_rsp_err    (1'b1  ),
    .o7_icb_rsp_excl_ok(1'b0  ),
    .o7_icb_rsp_rdata  ('0),


  //  * UNUSED (QSPI1)
    .o8_icb_enable     (1'b1),

    .o8_icb_cmd_valid  (),
    .o8_icb_cmd_ready  (1'b1),
    .o8_icb_cmd_addr   ( ),
    .o8_icb_cmd_read   ( ),
    .o8_icb_cmd_wdata  (),
    .o8_icb_cmd_wmask  (),
    .o8_icb_cmd_lock   (),
    .o8_icb_cmd_excl   (),
    .o8_icb_cmd_size   (),
    .o8_icb_cmd_burst  (),
    .o8_icb_cmd_beat   (),
    
    .o8_icb_rsp_valid  (1'b1),
    .o8_icb_rsp_ready  (),
    .o8_icb_rsp_err    (1'b1  ),
    .o8_icb_rsp_excl_ok(1'b0  ),
    .o8_icb_rsp_rdata  ('0),


  //  * UNUSED (PWM1)
    .o9_icb_enable     (1'b1),

    .o9_icb_cmd_valid  (),
    .o9_icb_cmd_ready  (1'b1),
    .o9_icb_cmd_addr   (),
    .o9_icb_cmd_read   (),
    .o9_icb_cmd_wdata  (),
    .o9_icb_cmd_wmask  (),
    .o9_icb_cmd_lock   (),
    .o9_icb_cmd_excl   (),
    .o9_icb_cmd_size   (),
    .o9_icb_cmd_burst  (),
    .o9_icb_cmd_beat   (),
    
    .o9_icb_rsp_valid  (1'b1),
    .o9_icb_rsp_ready  (),
    .o9_icb_rsp_err    (1'b1  ),
    .o9_icb_rsp_excl_ok(1'b0  ),
    .o9_icb_rsp_rdata  ('0),


  //  * UNUSED (QSPI2)
    .o10_icb_enable     (1'b1),

    .o10_icb_cmd_valid  (),
    .o10_icb_cmd_ready  (1'b1),
    .o10_icb_cmd_addr   (),
    .o10_icb_cmd_read   (),
    .o10_icb_cmd_wdata  (),
    .o10_icb_cmd_wmask  (),
    .o10_icb_cmd_lock   (),
    .o10_icb_cmd_excl   (),
    .o10_icb_cmd_size   (),
    .o10_icb_cmd_burst  (),
    .o10_icb_cmd_beat   (),
    
    .o10_icb_rsp_valid  (1'b1),
    .o10_icb_rsp_ready  (),
    .o10_icb_rsp_err    (1'b1  ),
    .o10_icb_rsp_excl_ok(1'b0  ),
    .o10_icb_rsp_rdata  ('0),


  //  * UNUSED (PWM2)
    .o11_icb_enable     (1'b1),

    .o11_icb_cmd_valid  (),
    .o11_icb_cmd_ready  (1'b1),
    .o11_icb_cmd_addr   (),
    .o11_icb_cmd_read   (),
    .o11_icb_cmd_wdata  (),
    .o11_icb_cmd_wmask  (),
    .o11_icb_cmd_lock   (),
    .o11_icb_cmd_excl   (),
    .o11_icb_cmd_size   (),
    .o11_icb_cmd_burst  (),
    .o11_icb_cmd_beat   (),
    
    .o11_icb_rsp_valid  (1'b1),
    .o11_icb_rsp_ready  (),
    .o11_icb_rsp_err    (1'b1  ),
    .o11_icb_rsp_excl_ok(1'b0  ),
    .o11_icb_rsp_rdata  ('0),


  //  * UNUSED (SysPer)
    .o12_icb_enable     (1'b1),

    .o12_icb_cmd_valid  (),
    .o12_icb_cmd_ready  (1'b1),
    .o12_icb_cmd_addr   (),
    .o12_icb_cmd_read   (),
    .o12_icb_cmd_wdata  (),
    .o12_icb_cmd_wmask  (),
    .o12_icb_cmd_lock   (),
    .o12_icb_cmd_excl   (),
    .o12_icb_cmd_size   (),
    .o12_icb_cmd_burst  (),
    .o12_icb_cmd_beat   (),
    
    .o12_icb_rsp_valid  (1'b1),
    .o12_icb_rsp_ready  (),
    .o12_icb_rsp_err    (1'b1),
    .o12_icb_rsp_excl_ok(1'b0),
    .o12_icb_rsp_rdata  ('0),

   //  * UNUSED (Example AXI)
    .o13_icb_enable     (1'b1),

    .o13_icb_cmd_valid  (),
    .o13_icb_cmd_ready  (1'b1),
    .o13_icb_cmd_addr   (),
    .o13_icb_cmd_read   (),
    .o13_icb_cmd_wdata  (),
    .o13_icb_cmd_wmask  (),
    .o13_icb_cmd_lock   (),
    .o13_icb_cmd_excl   (),
    .o13_icb_cmd_size   (),
    .o13_icb_cmd_burst  (),
    .o13_icb_cmd_beat   (),
    
    .o13_icb_rsp_valid  (1'b1),
    .o13_icb_rsp_ready  (),
    .o13_icb_rsp_err    (1'b1),
    .o13_icb_rsp_excl_ok(1'b0  ),
    .o13_icb_rsp_rdata  ('0),

   //  * UNUSED (Example APB)
    .o14_icb_enable     (1'b1),

    .o14_icb_cmd_valid  (),
    .o14_icb_cmd_ready  (1'b1),
    .o14_icb_cmd_addr   (),
    .o14_icb_cmd_read   (),
    .o14_icb_cmd_wdata  (),
    .o14_icb_cmd_wmask  (),
    .o14_icb_cmd_lock   (),
    .o14_icb_cmd_excl   (),
    .o14_icb_cmd_size   (),
    .o14_icb_cmd_burst  (),
    .o14_icb_cmd_beat   (),
    
    .o14_icb_rsp_valid  (1'b1),
    .o14_icb_rsp_ready  (),
    .o14_icb_rsp_err    (1'b1),
    .o14_icb_rsp_excl_ok(1'b0  ),
    .o14_icb_rsp_rdata  ('0),

   //  * UNUSED (I2C WishBone)
    .o15_icb_enable     (1'b1),

    .o15_icb_cmd_valid  (),
    .o15_icb_cmd_ready  (1'b1),
    .o15_icb_cmd_addr   (),
    .o15_icb_cmd_read   (),
    .o15_icb_cmd_wdata  (),
    .o15_icb_cmd_wmask  (),
    .o15_icb_cmd_lock   (),
    .o15_icb_cmd_excl   (),
    .o15_icb_cmd_size   (),
    .o15_icb_cmd_burst  (),
    .o15_icb_cmd_beat   (),
    
    .o15_icb_rsp_valid  (1'b1),
    .o15_icb_rsp_ready  (),
    .o15_icb_rsp_err    (1'b1),
    .o15_icb_rsp_excl_ok(1'b0  ),
    .o15_icb_rsp_rdata  ('0),

    .clk           (clk  ),
    .rst_n         (rst_n) 
  );


  //  * GPIO      
sirv_gpio_top u_sirv_gpio_top(
    .clk           (clk  ),
    .rst_n         (rst_n),

    .i_icb_cmd_valid (gpio_icb_cmd_valid),
    .i_icb_cmd_ready (gpio_icb_cmd_ready),
    .i_icb_cmd_addr  (gpio_icb_cmd_addr ),
    .i_icb_cmd_read  (gpio_icb_cmd_read ),
    .i_icb_cmd_wdata (gpio_icb_cmd_wdata),
    
    .i_icb_rsp_valid (gpio_icb_rsp_valid),
    .i_icb_rsp_ready (gpio_icb_rsp_ready),
    .i_icb_rsp_rdata (gpio_icb_rsp_rdata),

    .gpio_irq                 (gpio_irq),
   
    .io_pads_i_ival           (io_pads_gpio_i_ival),
    .io_pads_o_oval           (io_pads_gpio_o_oval),
    .io_pads_o_oe             (io_pads_gpio_o_oe  ),
    .io_pads_o_ie             (io_pads_gpio_o_ie  ),
    .io_pads_o_pue            (io_pads_gpio_o_pue ),
    .io_pads_o_ds             (io_pads_gpio_o_ds  ),
    .iof_0_i_ival          (gpio_iof_0_i_ival ),
    .iof_0_o_oval          (gpio_iof_0_o_oval ),
    .iof_0_o_oe            (gpio_iof_0_o_oe   ),
    .iof_0_o_ie            (gpio_iof_0_o_ie   ),
    .iof_0_o_valid         (gpio_iof_0_o_valid),
    .iof_1_i_ival          (gpio_iof_1_i_ival ),
    .iof_1_o_oval          (gpio_iof_1_o_oval ),
    .iof_1_o_oe            (gpio_iof_1_o_oe   ),
    .iof_1_o_ie            (gpio_iof_1_o_ie   ),
    .iof_1_o_valid         (gpio_iof_1_o_valid)
);

  //  * UART0     
sirv_uart_top u_sirv_uart0_top (
    .clk           (clk  ),
    .rst_n         (rst_n),

    .i_icb_cmd_valid (uart0_icb_cmd_valid),
    .i_icb_cmd_ready (uart0_icb_cmd_ready),
    .i_icb_cmd_addr  (uart0_icb_cmd_addr ),
    .i_icb_cmd_read  (uart0_icb_cmd_read ),
    .i_icb_cmd_wdata (uart0_icb_cmd_wdata),
    
    .i_icb_rsp_valid (uart0_icb_rsp_valid),
    .i_icb_rsp_ready (uart0_icb_rsp_ready),
    .i_icb_rsp_rdata (uart0_icb_rsp_rdata),

    .io_interrupts_0_0 (uart0_irq),                
    .io_port_txd       (uart0_txd),
    .io_port_rxd       (uart0_rxd)
);


  //  * QSPI0     
sirv_flash_qspi_top u_sirv_qspi0_top(
    .clk           (clk  ),
    .rst_n         (rst_n),

    .i_icb_cmd_valid (qspi0_icb_cmd_valid),
    .i_icb_cmd_ready (qspi0_icb_cmd_ready),
    .i_icb_cmd_addr  (qspi0_icb_cmd_addr ),
    .i_icb_cmd_read  (qspi0_icb_cmd_read ),
    .i_icb_cmd_wdata (qspi0_icb_cmd_wdata),
    
    .i_icb_rsp_valid (qspi0_icb_rsp_valid),
    .i_icb_rsp_ready (qspi0_icb_rsp_ready),
    .i_icb_rsp_rdata (qspi0_icb_rsp_rdata), 

    .f_icb_cmd_valid (qspi0_ro_icb_cmd_valid),
    .f_icb_cmd_ready (qspi0_ro_icb_cmd_ready),
    .f_icb_cmd_addr  (qspi0_ro_icb_cmd_addr ),
    .f_icb_cmd_read  (qspi0_ro_icb_cmd_read ),
    .f_icb_cmd_wdata (qspi0_ro_icb_cmd_wdata),
    
    .f_icb_rsp_valid (qspi0_ro_icb_rsp_valid),
    .f_icb_rsp_ready (qspi0_ro_icb_rsp_ready),
    .f_icb_rsp_rdata (qspi0_ro_icb_rsp_rdata), 

    .io_port_sck     (qspi0_sck    ), 
    .io_port_dq_0_i  (qspi0_dq_0_i ),
    .io_port_dq_0_o  (qspi0_dq_0_o ),
    .io_port_dq_0_oe (qspi0_dq_0_oe),
    .io_port_dq_1_i  (qspi0_dq_1_i ),
    .io_port_dq_1_o  (qspi0_dq_1_o ),
    .io_port_dq_1_oe (qspi0_dq_1_oe),
    .io_port_dq_2_i  (qspi0_dq_2_i ),
    .io_port_dq_2_o  (qspi0_dq_2_o ),
    .io_port_dq_2_oe (qspi0_dq_2_oe),
    .io_port_dq_3_i  (qspi0_dq_3_i ),
    .io_port_dq_3_o  (qspi0_dq_3_o ),
    .io_port_dq_3_oe (qspi0_dq_3_oe),
    .io_port_cs_0    (qspi0_cs_0   ),
    .io_tl_i_0_0     (qspi0_irq    ) 
);

  //  * PWM0      
sirv_pwm8_top u_sirv_pwm0_top(
    .clk           (clk  ),
    .rst_n         (rst_n),

    .i_icb_cmd_valid (pwm0_icb_cmd_valid),
    .i_icb_cmd_ready (pwm0_icb_cmd_ready),
    .i_icb_cmd_addr  (pwm0_icb_cmd_addr ),
    .i_icb_cmd_read  (pwm0_icb_cmd_read ),
    .i_icb_cmd_wdata (pwm0_icb_cmd_wdata),
    
    .i_icb_rsp_valid (pwm0_icb_rsp_valid),
    .i_icb_rsp_ready (pwm0_icb_rsp_ready),
    .i_icb_rsp_rdata (pwm0_icb_rsp_rdata),

    .io_interrupts(pwm0_irqs),

    .io_gpio(pwm0_gpio)
);

  logic [2:0] qspi_dq_0_sync;
  logic [2:0] qspi_dq_1_sync;
  logic [2:0] qspi_dq_2_sync;
  logic [2:0] qspi_dq_3_sync;

  always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      qspi_dq_0_sync <= '0;
      qspi_dq_1_sync <= '0;
      qspi_dq_2_sync <= '0;
      qspi_dq_3_sync <= '0;
    end
    else begin
      qspi_dq_0_sync <= {qspi_dq_0_sync[$high(qspi_dq_0_sync)-1:0], io_pads_qspi_dq_i_ival[0]};
      qspi_dq_1_sync <= {qspi_dq_1_sync[$high(qspi_dq_1_sync)-1:0], io_pads_qspi_dq_i_ival[1]};
      qspi_dq_2_sync <= {qspi_dq_2_sync[$high(qspi_dq_2_sync)-1:0], io_pads_qspi_dq_i_ival[2]};
      qspi_dq_3_sync <= {qspi_dq_3_sync[$high(qspi_dq_3_sync)-1:0], io_pads_qspi_dq_i_ival[3]};
    end
  end

  assign io_pads_qspi_sck_o_oval = qspi0_sck;
  assign io_pads_qspi_sck_o_oe = 1'h1;
  assign io_pads_qspi_sck_o_pue = 1'h0;
  assign qspi0_dq_0_i = qspi_dq_0_sync[$high(qspi_dq_0_sync)]; //T_273;
  assign qspi0_dq_1_i = qspi_dq_1_sync[$high(qspi_dq_1_sync)]; //T_280;
  assign qspi0_dq_2_i = qspi_dq_2_sync[$high(qspi_dq_2_sync)]; //T_287;
  assign qspi0_dq_3_i = qspi_dq_3_sync[$high(qspi_dq_3_sync)]; //T_294;
  assign io_pads_qspi_dq_o_oval[0] = qspi0_dq_0_o; //io_spi_dq_0_o;
  assign io_pads_qspi_dq_o_oe[0] =  qspi0_dq_0_oe; //io_spi_dq_0_oe;
  assign io_pads_qspi_dq_o_ie[0] = ~qspi0_dq_0_oe; //T_267;
  assign io_pads_qspi_dq_o_pue[0] = 1'h1;
  assign io_pads_qspi_dq_o_oval[1] = qspi0_dq_1_o; //io_spi_dq_1_o;
  assign io_pads_qspi_dq_o_oe[1] =  qspi0_dq_1_oe; //io_spi_dq_1_oe;
  assign io_pads_qspi_dq_o_ie[1] = ~qspi0_dq_1_oe; //T_274;
  assign io_pads_qspi_dq_o_pue[1] = 1'h1;
  assign io_pads_qspi_dq_o_oval[2] = qspi0_dq_2_o; //io_spi_dq_2_o;
  assign io_pads_qspi_dq_o_oe[2] =  qspi0_dq_2_oe; //io_spi_dq_2_oe;
  assign io_pads_qspi_dq_o_ie[2] = ~qspi0_dq_2_oe; //T_281;
  assign io_pads_qspi_dq_o_pue[2] = 1'h1;
  assign io_pads_qspi_dq_o_oval[3] = qspi0_dq_3_o; //io_spi_dq_3_o;
  assign io_pads_qspi_dq_o_oe[3] =  qspi0_dq_3_oe; //io_spi_dq_3_oe;
  assign io_pads_qspi_dq_o_ie[3] = ~qspi0_dq_3_oe; //T_288;
  assign io_pads_qspi_dq_o_pue[3] = 1'h1;

  assign io_pads_qspi_cs_0_o_oval = qspi0_cs_0;
  assign io_pads_qspi_cs_0_o_oe = 1'h1;
  assign io_pads_qspi_cs_0_o_pue = 1'h0;

  
//  localparam CMD_PACK_W = 65;
//  localparam RSP_PACK_W = 33;
//
//  wire [CMD_PACK_W-1:0] i_aon_icb_cmd_pack;
//  wire [RSP_PACK_W-1:0] i_aon_icb_rsp_pack;
//  wire [CMD_PACK_W-1:0] aon_icb_cmd_pack;
//  wire [RSP_PACK_W-1:0] aon_icb_rsp_pack;
//  
//  assign i_aon_icb_cmd_pack = {
//          i_aon_icb_cmd_addr, 
//          i_aon_icb_cmd_read, 
//          i_aon_icb_cmd_wdata};
//
//  assign {aon_icb_cmd_addr, 
//          aon_icb_cmd_read, 
//          aon_icb_cmd_wdata} = aon_icb_cmd_pack;
//
//  sirv_gnrl_cdc_tx   
//   # (
//     .DW      (CMD_PACK_W),
//     .SYNC_DP (`E203_ASYNC_FF_LEVELS) 
//   ) u_aon_icb_cdc_tx (
//     .o_vld  (aon_icb_cmd_valid ), 
//     .o_rdy_a(aon_icb_cmd_ready ), 
//     .o_dat  (aon_icb_cmd_pack ),
//     .i_vld  (i_aon_icb_cmd_valid ),
//     .i_rdy  (i_aon_icb_cmd_ready ),
//     .i_dat  (i_aon_icb_cmd_pack ),
//   
//     .clk    (clk),
//     .rst_n  (rst_n)
//   );
//     
//
//  assign aon_icb_rsp_pack = {
//          aon_icb_rsp_err, 
//          aon_icb_rsp_rdata};
//
//  assign {i_aon_icb_rsp_err, 
//          i_aon_icb_rsp_rdata} = i_aon_icb_rsp_pack;
//
//   sirv_gnrl_cdc_rx   
//      # (
//     .DW      (RSP_PACK_W),
//     .SYNC_DP (`E203_ASYNC_FF_LEVELS) 
//   ) u_aon_icb_cdc_rx (
//     .i_vld_a(aon_icb_rsp_valid), 
//     .i_rdy  (aon_icb_rsp_ready), 
//     .i_dat  (aon_icb_rsp_pack),
//     .o_vld  (i_aon_icb_rsp_valid),
//     .o_rdy  (i_aon_icb_rsp_ready),
//     .o_dat  (i_aon_icb_rsp_pack),
//   
//     .clk    (clk),
//     .rst_n  (rst_n)
//   );


  sirv_hclkgen_regs u_sirv_hclkgen_regs(
    .clk  (clk),
    .rst_n(rst_n),

    .pllbypass   (pllbypass   ),
    .pll_RESET(pll_RESET),
    .pll_ASLEEP(pll_ASLEEP),
    .pll_OD(pll_OD),
    .pll_M (pll_M ),
    .pll_N (pll_N ),
    .plloutdivby1(plloutdivby1),
    .plloutdiv   (plloutdiv   ),
                              
    .hfxoscen    (hfxoscen    ),


    .i_icb_cmd_valid(hclkgen_icb_cmd_valid),
    .i_icb_cmd_ready(hclkgen_icb_cmd_ready),
    .i_icb_cmd_addr (hclkgen_icb_cmd_addr[11:0]), 
    .i_icb_cmd_read (hclkgen_icb_cmd_read ), 
    .i_icb_cmd_wdata(hclkgen_icb_cmd_wdata),
                     
    .i_icb_rsp_valid(hclkgen_icb_rsp_valid),
    .i_icb_rsp_ready(hclkgen_icb_rsp_ready),
    .i_icb_rsp_rdata(hclkgen_icb_rsp_rdata)
  );

endmodule
