 /*                                                                      
 Copyright 2018 Tomas Brabec
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

 Change log:

   2018, Aug, Tomas Brabec
   - Removed unused TileLink channels (B,C,E).

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
//  The top level module of flash-qspi
//
// ====================================================================

module sirv_flash_qspi_top(
  input   clk,
  input   rst_n,

  input                      i_icb_cmd_valid,
  output                     i_icb_cmd_ready,
  input  [32-1:0]            i_icb_cmd_addr, 
  input                      i_icb_cmd_read, 
  input  [32-1:0]            i_icb_cmd_wdata,
  
  output                     i_icb_rsp_valid,
  input                      i_icb_rsp_ready,
  output [32-1:0]            i_icb_rsp_rdata,

  input                      f_icb_cmd_valid,
  output                     f_icb_cmd_ready,
  input  [32-1:0]            f_icb_cmd_addr, 
  input                      f_icb_cmd_read, 
  input  [32-1:0]            f_icb_cmd_wdata,
  
  output                     f_icb_rsp_valid,
  input                      f_icb_rsp_ready,
  output [32-1:0]            f_icb_rsp_rdata,

  output  io_port_sck,
  input   io_port_dq_0_i,
  output  io_port_dq_0_o,
  output  io_port_dq_0_oe,
  input   io_port_dq_1_i,
  output  io_port_dq_1_o,
  output  io_port_dq_1_oe,
  input   io_port_dq_2_i,
  output  io_port_dq_2_o,
  output  io_port_dq_2_oe,
  input   io_port_dq_3_i,
  output  io_port_dq_3_o,
  output  io_port_dq_3_oe,
  output  io_port_cs_0,
  output  io_tl_i_0_0 
);


  wire  tl_dat_a_ready;
  assign  i_icb_cmd_ready  = tl_dat_a_ready;
  wire  tl_dat_a_valid  = i_icb_cmd_valid;
  wire  [2:0] tl_dat_a_bits_opcode  = i_icb_cmd_read ? 3'h4 : 3'h0;
  wire  [2:0] tl_dat_a_bits_param  = 3'b0;
  wire  [2:0] tl_dat_a_bits_size = 3'd2;
  wire  [4:0] tl_dat_a_bits_source  = 5'b0;
  wire  [28:0] tl_dat_a_bits_address  = i_icb_cmd_addr[28:0];
  wire  [3:0] tl_dat_a_bits_mask  = 4'b1111;
  wire  [31:0] tl_dat_a_bits_data  = i_icb_cmd_wdata;

  
  wire  tl_dat_d_ready = i_icb_rsp_ready;

  wire  [2:0] tl_dat_d_bits_opcode;
  wire  [1:0] tl_dat_d_bits_param;
  wire  [2:0] tl_dat_d_bits_size;
  wire  [4:0] tl_dat_d_bits_source;
  wire  tl_dat_d_bits_sink;
  wire  [1:0] tl_dat_d_bits_addr_lo;
  wire  [31:0] tl_dat_d_bits_data;
  wire  tl_dat_d_bits_error;
  wire  tl_dat_d_valid;

  assign  i_icb_rsp_valid = tl_dat_d_valid;
  assign  i_icb_rsp_rdata = tl_dat_d_bits_data;

  /////////////////////////////////////////////////////////////////////////////
  /////////////////////////////////////////////////////////////////////////////

  wire  tl_ins_a_ready;
  assign  f_icb_cmd_ready  = tl_ins_a_ready;
  wire  tl_ins_a_valid  = f_icb_cmd_valid;
  wire  [2:0] tl_ins_a_bits_opcode  = f_icb_cmd_read ? 3'h4 : 3'h0;
  wire  [2:0] tl_ins_a_bits_param  = 3'b0;
  wire  [2:0] tl_ins_a_bits_size = 3'd2;
  wire  [1:0] tl_ins_a_bits_source  = 2'b0;
  // We must force the address to be aligned to 32bits
  wire  [29:0] tl_ins_a_bits_address  = {f_icb_cmd_addr[29:2],2'b0};
  wire  [3:0] tl_ins_a_bits_mask  = 4'b1111;
  wire  [31:0] tl_ins_a_bits_data  = f_icb_cmd_wdata;

  
  wire  tl_ins_d_ready = f_icb_rsp_ready;

  wire  [2:0] tl_ins_d_bits_opcode;
  wire  [1:0] tl_ins_d_bits_param;
  wire  [2:0] tl_ins_d_bits_size;
  wire  [1:0] tl_ins_d_bits_source;
  wire  tl_ins_d_bits_sink;
  wire  [1:0] tl_ins_d_bits_addr_lo;
  wire  [31:0] tl_ins_d_bits_data;
  wire  tl_ins_d_bits_error;
  wire  tl_ins_d_valid;

  assign  f_icb_rsp_valid = tl_ins_d_valid;
  assign  f_icb_rsp_rdata = tl_ins_d_bits_data;

  /////////////////////////////////////////////////////////////////////////////
  /////////////////////////////////////////////////////////////////////////////

  wire  tl_f_0_a_ready;
  wire  tl_f_0_a_valid;
  wire  [2:0] tl_f_0_a_bits_opcode;
  wire  [2:0] tl_f_0_a_bits_param;
  wire  [2:0] tl_f_0_a_bits_size;
  wire  [6:0] tl_f_0_a_bits_source;
  wire  [29:0] tl_f_0_a_bits_address;
  wire  tl_f_0_a_bits_mask;
  wire  [7:0] tl_f_0_a_bits_data;

  
  wire  io_in_0_a_ready;
  wire  io_in_0_a_valid;
  wire [2:0] io_in_0_a_bits_opcode;
  wire [2:0] io_in_0_a_bits_param;
  wire [2:0] io_in_0_a_bits_size;
  wire [1:0] io_in_0_a_bits_source;
  wire [29:0] io_in_0_a_bits_address;
  wire  io_in_0_a_bits_mask;
  wire [7:0] io_in_0_a_bits_data;
  wire  io_in_0_d_ready;
  wire  io_in_0_d_valid;
  wire [2:0] io_in_0_d_bits_opcode;
  wire [1:0] io_in_0_d_bits_param;
  wire [2:0] io_in_0_d_bits_size;
  wire [1:0] io_in_0_d_bits_source;
  wire  io_in_0_d_bits_sink;
  wire  io_in_0_d_bits_addr_lo;
  wire [7:0] io_in_0_d_bits_data;
  wire  io_in_0_d_bits_error;

  wire  io_out_0_a_ready;
  wire  io_out_0_a_valid;
  wire [2:0] io_out_0_a_bits_opcode;
  wire [2:0] io_out_0_a_bits_param;
  wire [2:0] io_out_0_a_bits_size;
  wire [6:0] io_out_0_a_bits_source;
  wire [29:0] io_out_0_a_bits_address;
  wire  io_out_0_a_bits_mask;
  wire [7:0] io_out_0_a_bits_data;
  wire  io_out_0_d_ready;
  wire  io_out_0_d_valid;
  wire [2:0] io_out_0_d_bits_opcode;
  wire [1:0] io_out_0_d_bits_param;
  wire [2:0] io_out_0_d_bits_size;
  wire [6:0] io_out_0_d_bits_source;
  wire  io_out_0_d_bits_sink;
  wire  io_out_0_d_bits_addr_lo;
  wire [7:0] io_out_0_d_bits_data;
  wire  io_out_0_d_bits_error;


  sirv_tlwidthwidget_qspi qspi_TLWidthWidget (
    .clock(clk),
    .reset(~rst_n),
    .in_tl_a_ready(         tl_ins_a_ready),
    .in_tl_a_valid(         tl_ins_a_valid),
    .in_tl_a_bits_opcode(   tl_ins_a_bits_opcode),
    .in_tl_a_bits_param(    tl_ins_a_bits_param), // const 0
    .in_tl_a_bits_size(     tl_ins_a_bits_size), // const 2
    .in_tl_a_bits_source(   tl_ins_a_bits_source), // const 0
    .in_tl_a_bits_address(  tl_ins_a_bits_address),
    .in_tl_a_bits_mask(     tl_ins_a_bits_mask), // const 4'hF
    .in_tl_a_bits_data(     tl_ins_a_bits_data),
    .in_tl_d_ready(         tl_ins_d_ready),
    .in_tl_d_valid(         tl_ins_d_valid),
    .in_tl_d_bits_opcode(   tl_ins_d_bits_opcode), // unused
    .in_tl_d_bits_param(    tl_ins_d_bits_param), // unused
    .in_tl_d_bits_size(     tl_ins_d_bits_size), // unused
    .in_tl_d_bits_source(   tl_ins_d_bits_source), // unused
    .in_tl_d_bits_sink(     tl_ins_d_bits_sink), // unused
    .in_tl_d_bits_addr_lo(  tl_ins_d_bits_addr_lo), // unused
    .in_tl_d_bits_data(     tl_ins_d_bits_data),
    .in_tl_d_bits_error(    tl_ins_d_bits_error), // unused

    .out_tl_a_ready(        io_in_0_a_ready),
    .out_tl_a_valid(        io_in_0_a_valid),
    .out_tl_a_bits_opcode(  io_in_0_a_bits_opcode),
    .out_tl_a_bits_param(   io_in_0_a_bits_param),
    .out_tl_a_bits_size(    io_in_0_a_bits_size),
    .out_tl_a_bits_source(  io_in_0_a_bits_source),
    .out_tl_a_bits_address( io_in_0_a_bits_address),
    .out_tl_a_bits_mask(    io_in_0_a_bits_mask),
    .out_tl_a_bits_data(    io_in_0_a_bits_data), // const 8'h00
    .out_tl_d_ready(        io_in_0_d_ready),
    .out_tl_d_valid(        io_in_0_d_valid),
    .out_tl_d_bits_opcode(  io_in_0_d_bits_opcode),
    .out_tl_d_bits_param(   io_in_0_d_bits_param),
    .out_tl_d_bits_size(    io_in_0_d_bits_size),
    .out_tl_d_bits_source(  io_in_0_d_bits_source),
    .out_tl_d_bits_sink(    io_in_0_d_bits_sink),
    .out_tl_d_bits_addr_lo( io_in_0_d_bits_addr_lo),
    .out_tl_d_bits_data(    io_in_0_d_bits_data),
    .out_tl_d_bits_error(   io_in_0_d_bits_error)
  );

  sirv_tlfragmenter_qspi_1 qspi_TLFragmenter_1 (
    .clock (clk   ),
    .reset (~rst_n),
    .in_tl_a_ready(       io_in_0_a_ready),
    .in_tl_a_valid(       io_in_0_a_valid),
    .in_tl_a_bits_opcode( io_in_0_a_bits_opcode),
    .in_tl_a_bits_param(  io_in_0_a_bits_param),
    .in_tl_a_bits_size(   io_in_0_a_bits_size),
    .in_tl_a_bits_source( io_in_0_a_bits_source),
    .in_tl_a_bits_address(io_in_0_a_bits_address),
    .in_tl_a_bits_mask(   io_in_0_a_bits_mask),
    .in_tl_a_bits_data(   io_in_0_a_bits_data),
    .in_tl_d_ready(       io_in_0_d_ready),
    .in_tl_d_valid(       io_in_0_d_valid),
    .in_tl_d_bits_opcode( io_in_0_d_bits_opcode),
    .in_tl_d_bits_param(  io_in_0_d_bits_param),
    .in_tl_d_bits_size(   io_in_0_d_bits_size),
    .in_tl_d_bits_source( io_in_0_d_bits_source),
    .in_tl_d_bits_sink(   io_in_0_d_bits_sink),
    .in_tl_d_bits_addr_lo(io_in_0_d_bits_addr_lo),
    .in_tl_d_bits_data(   io_in_0_d_bits_data),
    .in_tl_d_bits_error(  io_in_0_d_bits_error),
    .out_tl_a_ready(          io_out_0_a_ready),
    .out_tl_a_valid(          io_out_0_a_valid),
    .out_tl_a_bits_opcode(    io_out_0_a_bits_opcode),
    .out_tl_a_bits_param(     io_out_0_a_bits_param),
    .out_tl_a_bits_size(      io_out_0_a_bits_size),
    .out_tl_a_bits_source(    io_out_0_a_bits_source),
    .out_tl_a_bits_address(   io_out_0_a_bits_address),
    .out_tl_a_bits_mask(      io_out_0_a_bits_mask),
    .out_tl_a_bits_data(      io_out_0_a_bits_data),
    .out_tl_d_ready(          io_out_0_d_ready),
    .out_tl_d_valid(          io_out_0_d_valid),
    .out_tl_d_bits_opcode(    io_out_0_d_bits_opcode),
    .out_tl_d_bits_param(     io_out_0_d_bits_param),
    .out_tl_d_bits_size(      io_out_0_d_bits_size),
    .out_tl_d_bits_source(    io_out_0_d_bits_source),
    .out_tl_d_bits_sink(      io_out_0_d_bits_sink),
    .out_tl_d_bits_addr_lo(   io_out_0_d_bits_addr_lo),
    .out_tl_d_bits_data(      io_out_0_d_bits_data),
    .out_tl_d_bits_error(     io_out_0_d_bits_error)
  );
sirv_flash_qspi u_sirv_flash_qspi(
  .clock                            (clk                              ),
  .reset                            (~rst_n                           ),

  .tl_dat_a_ready                  (tl_dat_a_ready                  ),
  .tl_dat_a_valid                  (tl_dat_a_valid                  ),
  .tl_dat_a_bits_opcode            (tl_dat_a_bits_opcode            ),
  .tl_dat_a_bits_param             (tl_dat_a_bits_param             ),
  .tl_dat_a_bits_size              (tl_dat_a_bits_size              ),
  .tl_dat_a_bits_source            (tl_dat_a_bits_source            ),
  .tl_dat_a_bits_address           (tl_dat_a_bits_address           ),
  .tl_dat_a_bits_mask              (tl_dat_a_bits_mask              ),
  .tl_dat_a_bits_data              (tl_dat_a_bits_data              ),
  .tl_dat_d_ready                  (tl_dat_d_ready                  ),
  .tl_dat_d_valid                  (tl_dat_d_valid                  ),
  .tl_dat_d_bits_opcode            (tl_dat_d_bits_opcode            ),
  .tl_dat_d_bits_param             (tl_dat_d_bits_param             ),
  .tl_dat_d_bits_size              (tl_dat_d_bits_size              ),
  .tl_dat_d_bits_source            (tl_dat_d_bits_source            ),
  .tl_dat_d_bits_sink              (tl_dat_d_bits_sink              ),
  .tl_dat_d_bits_addr_lo           (tl_dat_d_bits_addr_lo           ),
  .tl_dat_d_bits_data              (tl_dat_d_bits_data              ),
  .tl_dat_d_bits_error             (tl_dat_d_bits_error             ),

  .tl_ins_a_ready                  (io_out_0_a_ready                  ),
  .tl_ins_a_valid                  (io_out_0_a_valid                  ),
  .tl_ins_a_bits_opcode            (io_out_0_a_bits_opcode            ),
  .tl_ins_a_bits_param             (io_out_0_a_bits_param             ),
  .tl_ins_a_bits_size              (io_out_0_a_bits_size              ),
  .tl_ins_a_bits_source            (io_out_0_a_bits_source            ),
  .tl_ins_a_bits_address           (io_out_0_a_bits_address           ),
  .tl_ins_a_bits_mask              (io_out_0_a_bits_mask              ),
  .tl_ins_a_bits_data              (io_out_0_a_bits_data              ),
  .tl_ins_d_ready                  (io_out_0_d_ready                  ),
  .tl_ins_d_valid                  (io_out_0_d_valid                  ),
  .tl_ins_d_bits_opcode            (io_out_0_d_bits_opcode            ),
  .tl_ins_d_bits_param             (io_out_0_d_bits_param             ),
  .tl_ins_d_bits_size              (io_out_0_d_bits_size              ),
  .tl_ins_d_bits_source            (io_out_0_d_bits_source            ),
  .tl_ins_d_bits_sink              (io_out_0_d_bits_sink              ),
  .tl_ins_d_bits_addr_lo           (io_out_0_d_bits_addr_lo           ),
  .tl_ins_d_bits_data              (io_out_0_d_bits_data              ),
  .tl_ins_d_bits_error             (io_out_0_d_bits_error             ),


  .io_port_sck       (io_port_sck    ),
  .io_port_dq_0_i    (io_port_dq_0_i ),
  .io_port_dq_0_o    (io_port_dq_0_o ),
  .io_port_dq_0_oe   (io_port_dq_0_oe),
  .io_port_dq_1_i    (io_port_dq_1_i ),
  .io_port_dq_1_o    (io_port_dq_1_o ),
  .io_port_dq_1_oe   (io_port_dq_1_oe),
  .io_port_dq_2_i    (io_port_dq_2_i ),
  .io_port_dq_2_o    (io_port_dq_2_o ),
  .io_port_dq_2_oe   (io_port_dq_2_oe),
  .io_port_dq_3_i    (io_port_dq_3_i ),
  .io_port_dq_3_o    (io_port_dq_3_o ),
  .io_port_dq_3_oe   (io_port_dq_3_oe), 
  .io_port_cs_0      (io_port_cs_0   ),
  .io_tl_i_0_0       (io_tl_i_0_0    ) 

);

endmodule
