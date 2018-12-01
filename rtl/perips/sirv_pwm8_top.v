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
                                                                         
                                                                         
                                                                         
module sirv_pwm8_top(
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

  output  [3:0] io_interrupts,

  output  [3:0] io_gpio
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

sirv_pwm8 u_sirv_pwm8(
  .clock                       (clk                              ),
  .reset                       (~rst_n                           ),

  .io_interrupts               (io_interrupts                    ),
                                                                 
  .io_gpio                     (io_gpio                          ),

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
  .tl_d_bits_error             (tl_d_bits_error             )
);

endmodule
