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
  input  [31:0] in_tl_a_bits_data,
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
  output [7:0] out_tl_a_bits_data,
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
  wire  Repeater_5_1_io_deq_valid;
  wire [2:0] Repeater_5_1_io_deq_bits_opcode;
  wire [2:0] Repeater_5_1_io_deq_bits_param;
  wire [2:0] Repeater_5_1_io_deq_bits_size;
  wire [1:0] Repeater_5_1_io_deq_bits_source;
  wire [29:0] Repeater_5_1_io_deq_bits_address;
  wire [3:0] Repeater_5_1_io_deq_bits_mask;
  wire [31:0] Repeater_5_1_io_deq_bits_data;
  reg [3:0] T_1447;
  reg [23:0] T_1512;
  wire [31:0] T_1515;
  reg [1:0] T_1527;
  wire [1:0] T_1534;
  wire [1:0] T_1535;
  wire  T_1536;
  wire  T_1540;
  wire [3:0]  T_1541;
//---->>>> Tomas B.: As long as `io_repeat==0`, the repeater merely passes through
//         and hence has no real function.
//  wire  Repeater_5_1_io_full;
//  sirv_tl_repeater_5 Repeater_5_1 (
//    .clock(clock),
//    .reset(reset),
//    .io_repeat(1'h0),
//    .io_full(Repeater_5_1_io_full),
//    .io_enq_ready(in_tl_a_ready),
//    .io_enq_valid(in_tl_a_valid),
//    .io_enq_bits_opcode(in_tl_a_bits_opcode),
//    .io_enq_bits_param(in_tl_a_bits_param),
//    .io_enq_bits_size(in_tl_a_bits_size),
//    .io_enq_bits_source(in_tl_a_bits_source),
//    .io_enq_bits_address(in_tl_a_bits_address),
//    .io_enq_bits_mask(in_tl_a_bits_mask),
//    .io_enq_bits_data(in_tl_a_bits_data),
//    .io_deq_ready(out_tl_a_ready),
//    .io_deq_valid(Repeater_5_1_io_deq_valid),
//    .io_deq_bits_opcode(Repeater_5_1_io_deq_bits_opcode),
//    .io_deq_bits_param(Repeater_5_1_io_deq_bits_param),
//    .io_deq_bits_size(Repeater_5_1_io_deq_bits_size),
//    .io_deq_bits_source(Repeater_5_1_io_deq_bits_source),
//    .io_deq_bits_address(Repeater_5_1_io_deq_bits_address),
//    .io_deq_bits_mask(Repeater_5_1_io_deq_bits_mask),
//    .io_deq_bits_data(Repeater_5_1_io_deq_bits_data)
//  );
  assign in_tl_a_ready = out_tl_a_ready;
  assign Repeater_5_1_io_deq_valid = in_tl_a_valid;
  assign Repeater_5_1_io_deq_bits_opcode = in_tl_a_bits_opcode;
  assign Repeater_5_1_io_deq_bits_param = in_tl_a_bits_param;
  assign Repeater_5_1_io_deq_bits_size = in_tl_a_bits_size;
  assign Repeater_5_1_io_deq_bits_source = in_tl_a_bits_source;
  assign Repeater_5_1_io_deq_bits_address = in_tl_a_bits_address;
  assign Repeater_5_1_io_deq_bits_mask = in_tl_a_bits_mask;
  assign Repeater_5_1_io_deq_bits_data = in_tl_a_bits_data;
//<<<<----
  assign in_tl_d_valid = (out_tl_d_valid & T_1536);
  assign in_tl_d_bits_opcode = out_tl_d_bits_opcode;
  assign in_tl_d_bits_param = out_tl_d_bits_param;
  assign in_tl_d_bits_size = out_tl_d_bits_size;
  assign in_tl_d_bits_source = out_tl_d_bits_source;
  assign in_tl_d_bits_sink = out_tl_d_bits_sink;
  assign in_tl_d_bits_addr_lo = {{1'd0}, out_tl_d_bits_addr_lo};
  assign in_tl_d_bits_data = 
      (3'h0 == out_tl_d_bits_size) ? {4{T_1515[31:24]}} :
      (3'h1 == out_tl_d_bits_size) ? {2{T_1515[31:16],T_1515[31:16]}} : T_1515;
  assign in_tl_d_bits_error = out_tl_d_bits_error;
  assign out_tl_a_valid = Repeater_5_1_io_deq_valid;
  assign out_tl_a_bits_opcode = Repeater_5_1_io_deq_bits_opcode;
  assign out_tl_a_bits_param = Repeater_5_1_io_deq_bits_param;
  assign out_tl_a_bits_size = Repeater_5_1_io_deq_bits_size;
  assign out_tl_a_bits_source = Repeater_5_1_io_deq_bits_source;
  assign out_tl_a_bits_address = Repeater_5_1_io_deq_bits_address;
  assign out_tl_a_bits_mask =
      (T_1541[0] & Repeater_5_1_io_deq_bits_mask[0]) | 
      (T_1541[1] & Repeater_5_1_io_deq_bits_mask[1]) |
      (T_1541[2] & Repeater_5_1_io_deq_bits_mask[2]) |
      (T_1541[3] & Repeater_5_1_io_deq_bits_mask[3]);
  assign out_tl_a_bits_data = 8'h0;
  assign out_tl_d_ready = in_tl_d_ready | ~T_1536;
  assign T_1515 = {out_tl_d_bits_data,T_1512};
  assign T_1534 = ~(2'h3 << out_tl_d_bits_size);
  assign T_1535 = ~(2'h3 << Repeater_5_1_io_deq_bits_size);
  assign T_1536 = T_1527 == T_1534;
  assign T_1540 = out_tl_d_ready & out_tl_d_valid;
  assign T_1541 = ~{T_1535[0],T_1535[1],T_1535[0],1'h0};


  always @(posedge clock or posedge reset) 
  if (reset) begin
    T_1512 <= 24'b0;
  end
  else if (T_1540) begin
    T_1512 <= T_1515[31:8];
  end


  always @(posedge clock or posedge reset) 
    if (reset) begin
      T_1527 <= 2'h0;
    end else if (T_1540) begin
      if (T_1536) begin
        T_1527 <= 2'h0;
      end else begin
        T_1527 <= T_1527 + 2'h1;
      end
    end

endmodule
