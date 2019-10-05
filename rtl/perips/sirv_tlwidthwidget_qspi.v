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
   - Code cleanup (unused nets, transitive assignments, constant assignments).
   - Removed unused TileLink channels (B,C,E).

 */                                                                      
                                                                         
                                                                         
                                                                         
/*
* Translates from a 32-bit TL to 8-bit TL. The data path is used only in
* the reverse direction (i.e. D channel) and so the translation works only
* for "reads".
*/
module sirv_tlwidthwidget_qspi(
  input   clock,
  input   reset,

  // Input 32-bit TL interface
  // -------------------------
  output  in_tl_a_ready,
  input   in_tl_a_valid,
  input  [2:0] in_tl_a_bits_opcode,
  input  [2:0] in_tl_a_bits_param,
  input  [2:0] in_tl_a_bits_size,
  input  [1:0] in_tl_a_bits_source,
  input  [29:0] in_tl_a_bits_address,
  input  [3:0] in_tl_a_bits_mask,
  input  [31:0] in_tl_a_bits_data, // unused!!!
  input   in_tl_d_ready,
  output  in_tl_d_valid,
  output [2:0] in_tl_d_bits_opcode,
  output [1:0] in_tl_d_bits_param,
  output [2:0] in_tl_d_bits_size,
  output [1:0] in_tl_d_bits_source,
  output  in_tl_d_bits_sink,
  output [1:0] in_tl_d_bits_addr_lo,
  output [31:0] in_tl_d_bits_data,
  output  in_tl_d_bits_error,

  // Output 8-bit TL interface
  // -------------------------
  input   out_tl_a_ready,
  output  out_tl_a_valid,
  output [2:0] out_tl_a_bits_opcode,
  output [2:0] out_tl_a_bits_param,
  output [2:0] out_tl_a_bits_size,
  output [1:0] out_tl_a_bits_source,
  output [29:0] out_tl_a_bits_address,
  output  out_tl_a_bits_mask,
  output [7:0] out_tl_a_bits_data, // always 0!!!
  output  out_tl_d_ready,
  input   out_tl_d_valid,
  input  [2:0] out_tl_d_bits_opcode,
  input  [1:0] out_tl_d_bits_param,
  input  [2:0] out_tl_d_bits_size,
  input  [1:0] out_tl_d_bits_source,
  input   out_tl_d_bits_sink,
  input   out_tl_d_bits_addr_lo,
  input  [7:0] out_tl_d_bits_data,
  input   out_tl_d_bits_error
);
  reg [3:0] T_1447;
  reg [23:0] d_bits_data_lo;
  wire [31:0] d_bits_data;
  reg [1:0] d_bits_cnt;
  wire [1:0] d_bits_size; // number of bytes to put load into `d_bits_data`
  wire [1:0] a_bits_size;
  wire  d_bits_rdy;
  wire  d_bits_shift;
  wire [3:0]  a_bits_mask_vld;
  assign in_tl_a_ready = out_tl_a_ready;
  assign in_tl_d_valid = (out_tl_d_valid & d_bits_rdy);
  assign in_tl_d_bits_opcode = out_tl_d_bits_opcode;
  assign in_tl_d_bits_param = out_tl_d_bits_param;
  assign in_tl_d_bits_size = out_tl_d_bits_size;
  assign in_tl_d_bits_source = out_tl_d_bits_source;
  assign in_tl_d_bits_sink = out_tl_d_bits_sink;
  assign in_tl_d_bits_addr_lo = {{1'd0}, out_tl_d_bits_addr_lo};
  assign in_tl_d_bits_data = 
      (3'h0 == out_tl_d_bits_size) ? {4{d_bits_data[31:24]}} :
      (3'h1 == out_tl_d_bits_size) ? {2{d_bits_data[31:16],d_bits_data[31:16]}} : d_bits_data;
  assign in_tl_d_bits_error = out_tl_d_bits_error;
  assign out_tl_a_valid = in_tl_a_valid;
  assign out_tl_a_bits_opcode = in_tl_a_bits_opcode;
  assign out_tl_a_bits_param = in_tl_a_bits_param;
  assign out_tl_a_bits_size = in_tl_a_bits_size;
  assign out_tl_a_bits_source = in_tl_a_bits_source;
  assign out_tl_a_bits_address = in_tl_a_bits_address;
  // The mask can really be ignored as long as the associated data
  // remains unused.
  assign out_tl_a_bits_mask =
      (a_bits_mask_vld[0] & in_tl_a_bits_mask[0]) | 
      (a_bits_mask_vld[1] & in_tl_a_bits_mask[1]) |
      (a_bits_mask_vld[2] & in_tl_a_bits_mask[2]) |
      (a_bits_mask_vld[3] & in_tl_a_bits_mask[3]);
  assign out_tl_a_bits_data = 8'h0;
  assign out_tl_d_ready = in_tl_d_ready | ~d_bits_rdy;
  assign d_bits_data = {out_tl_d_bits_data,d_bits_data_lo};
  assign d_bits_size = ~(2'h3 << out_tl_d_bits_size); // maps 0->0, 1->1, 2->3, 3->3
  assign a_bits_size = ~(2'h3 << in_tl_a_bits_size); // maps 0->0, 1->1, 2->3, 3->3
  assign d_bits_rdy = d_bits_cnt == d_bits_size;
  assign d_bits_shift = out_tl_d_ready & out_tl_d_valid;
  assign a_bits_mask_vld = ~{a_bits_size[0],a_bits_size[1],a_bits_size[0],1'h0}; // maps 0->F, 1->5, 2->B, 3->1


  always @(posedge clock or posedge reset) 
  if (reset) begin
    d_bits_data_lo <= 24'b0;
  end
  else if (d_bits_shift) begin
    d_bits_data_lo <= d_bits_data[31:8];
  end


  always @(posedge clock or posedge reset) 
    if (reset) begin
      d_bits_cnt <= 2'h0;
    end else if (d_bits_shift) begin
      if (d_bits_rdy) begin
        d_bits_cnt <= 2'h0;
      end else begin
        d_bits_cnt <= d_bits_cnt + 2'h1;
      end
    end

endmodule
