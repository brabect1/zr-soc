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
                                                                         
                                                                         
                                                                         
//=====================================================================
//--        _______   ___
//--       (   ____/ /__/
//--        \ \     __
//--     ____\ \   / /
//--    /_______\ /_/   MICROELECTRONICS
//--
//=====================================================================
//
// Designer   : Bob Hu
//
// Description:
//  The top level module of gpio
//
// ====================================================================

module sirv_gpio_top(
  input   clk,
  input   rst_n,

  input         i_icb_cmd_valid,
  output        i_icb_cmd_ready,
  input  [31:0] i_icb_cmd_addr, 
  input         i_icb_cmd_read, 
  input  [31:0] i_icb_cmd_wdata,
  
  output        i_icb_rsp_valid,
  input         i_icb_rsp_ready,
  output [31:0] i_icb_rsp_rdata,

  output [31:0] gpio_irq,

  input  [31:0] io_pads_i_ival,
  output [31:0] io_pads_o_oval,
  output [31:0] io_pads_o_oe,
  output [31:0] io_pads_o_ie,
  output [31:0] io_pads_o_pue,
  output [31:0] io_pads_o_ds,

  output [31:0] iof_0_i_ival,
  input  [31:0] iof_0_o_oval,
  input  [31:0] iof_0_o_oe,
  input  [31:0] iof_0_o_ie,
  input  [31:0] iof_0_o_valid,

  output [31:0] iof_1_i_ival,
  input  [31:0] iof_1_o_oval,
  input  [31:0] iof_1_o_oe,
  input  [31:0] iof_1_o_ie,
  input  [31:0] iof_1_o_valid
);


  wire  tl_a_ready;
  assign  i_icb_cmd_ready  = tl_a_ready;
  wire  tl_a_valid  = i_icb_cmd_valid;
  wire  [2:0] tl_a_bits_opcode  = i_icb_cmd_read ? 3'h4 : 3'h0;
  wire  [2:0] tl_a_bits_param  = 3'b0;
  wire  [2:0] tl_a_bits_size = 3'd2;
  wire  [4:0] tl_a_bits_source  = 5'b0;
  wire  [28:0] tl_a_bits_address  = i_icb_cmd_addr[28:0];
  wire  [3:0] tl_a_bits_mask  = 4'b1111;
  wire  [31:0] tl_a_bits_data  = i_icb_cmd_wdata;

  
  wire  tl_d_ready = i_icb_rsp_ready;

  wire  [2:0] tl_d_bits_opcode;
  wire  [1:0] tl_d_bits_param;
  wire  [2:0] tl_d_bits_size;
  wire  [4:0] tl_d_bits_source;
  wire  tl_d_bits_sink;
  wire  [1:0] tl_d_bits_addr_lo;
  wire  [31:0] tl_d_bits_data;
  wire  tl_d_bits_error;
  wire  tl_d_valid;

  assign  i_icb_rsp_valid = tl_d_valid;
  assign  i_icb_rsp_rdata = tl_d_bits_data;

sirv_gpio u_sirv_gpio(
  .clock                            (clk                              ),
  .reset                            (~rst_n                           ),

  .tl_a_ready                  (tl_a_ready                  ),
  .tl_a_valid                  (tl_a_valid                  ),
  .tl_a_bits_opcode            (tl_a_bits_opcode            ),
  .tl_a_bits_param             (tl_a_bits_param             ),
  .tl_a_bits_size              (tl_a_bits_size              ),
  .tl_a_bits_source            (tl_a_bits_source            ),
  .tl_a_bits_address           (tl_a_bits_address           ),
  .tl_a_bits_mask              (tl_a_bits_mask              ),
  .tl_a_bits_data              (tl_a_bits_data              ),
  .tl_d_ready                  (tl_d_ready                  ),
  .tl_d_valid                  (tl_d_valid                  ),
  .tl_d_bits_opcode            (tl_d_bits_opcode            ),
  .tl_d_bits_param             (tl_d_bits_param             ),
  .tl_d_bits_size              (tl_d_bits_size              ),
  .tl_d_bits_source            (tl_d_bits_source            ),
  .tl_d_bits_sink              (tl_d_bits_sink              ),
  .tl_d_bits_addr_lo           (tl_d_bits_addr_lo           ),
  .tl_d_bits_data              (tl_d_bits_data              ),
  .tl_d_bits_error             (tl_d_bits_error             ),

  .gpio_irq               (gpio_irq),
 
  .io_pads_i_ival           (io_pads_i_ival),
  .io_pads_o_oval           (io_pads_o_oval),
  .io_pads_o_oe             (io_pads_o_oe),
  .io_pads_o_ie             (io_pads_o_ie),
  .io_pads_o_pue            (io_pads_o_pue),
  .io_pads_o_ds             (io_pads_o_ds),

  .iof_0_i_ival          (iof_0_i_ival),
  .iof_0_o_oval          (iof_0_o_oval),
  .iof_0_o_oe            (iof_0_o_oe),
  .iof_0_o_ie            (iof_0_o_ie),
  .iof_0_o_valid         (iof_0_o_valid),
  .iof_1_i_ival          (iof_1_i_ival),
  .iof_1_o_oval          (iof_1_o_oval),
  .iof_1_o_oe            (iof_1_o_oe),
  .iof_1_o_ie            (iof_1_o_ie),
  .iof_1_o_valid         (iof_1_o_valid)
);

endmodule
