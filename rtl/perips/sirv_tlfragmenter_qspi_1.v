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
                                                                         
                                                                         
                                                                         

module sirv_tlfragmenter_qspi_1(
  input   clock,
  input   reset,
  output  in_tl_a_ready,
  input   in_tl_a_valid,
  input  [2:0] in_tl_a_bits_opcode,
  input  [2:0] in_tl_a_bits_param,
  input  [2:0] in_tl_a_bits_size,
  input  [1:0] in_tl_a_bits_source,
  input  [29:0] in_tl_a_bits_address,
  input   in_tl_a_bits_mask,
  input  [7:0] in_tl_a_bits_data,
  input   in_tl_d_ready,
  output  in_tl_d_valid,
  output [2:0] in_tl_d_bits_opcode,
  output [1:0] in_tl_d_bits_param,
  output [2:0] in_tl_d_bits_size,
  output [1:0] in_tl_d_bits_source,
  output  in_tl_d_bits_sink,
  output  in_tl_d_bits_addr_lo,
  output [7:0] in_tl_d_bits_data,
  output  in_tl_d_bits_error,
  input   out_tl_a_ready,
  output  out_tl_a_valid,
  output [2:0] out_tl_a_bits_opcode,
  output [2:0] out_tl_a_bits_param,
  output [2:0] out_tl_a_bits_size,
  output [6:0] out_tl_a_bits_source,
  output [29:0] out_tl_a_bits_address,
  output  out_tl_a_bits_mask,
  output [7:0] out_tl_a_bits_data,
  output  out_tl_d_ready,
  input   out_tl_d_valid,
  input  [2:0] out_tl_d_bits_opcode,
  input  [1:0] out_tl_d_bits_param,
  input  [2:0] out_tl_d_bits_size,
  input  [6:0] out_tl_d_bits_source,
  input   out_tl_d_bits_sink,
  input   out_tl_d_bits_addr_lo,
  input  [7:0] out_tl_d_bits_data,
  input   out_tl_d_bits_error
);
  reg [4:0] acknum;
  reg [2:0] dSaved_size;
  wire  dFirst;
  wire [7:0] T_1410;
  wire  dsizeOH1;
  wire [4:0] GEN_5;
  wire [4:0] dFirst_acknum;
  wire [5:0] T_1434;
  wire  T_1438;
  wire [3:0] GEN_9;
  wire [3:0] T_1439;
  wire  T_1443;
  wire [1:0] T_1444;
  wire [1:0] T_1446;
  wire [2:0] dFirst_size;
  wire  repeater_full;
  wire  repeater_enq_ready;
  wire  repeater_deq_valid;
  wire [2:0] repeater_deq_bits_opcode;
  wire [2:0] repeater_deq_bits_param;
  wire [2:0] repeater_deq_bits_size;
  wire [1:0] repeater_deq_bits_source;
  wire [29:0] repeater_deq_bits_address;
  wire  repeater_deq_bits_mask;
//  wire [7:0] repeater_deq_bits_data;
  wire [4:0] a_bits_addr_lo_mask; // masks which bits of `a_bits_addr_lo` are used; derives from `in_tl_a_bits_size` (indirectly through `repeater_deq_bits_size`)
  reg [4:0] gennum;
  wire  aFirst;
  wire [4:0] new_gennum;
  wire  repeater_repeat;
  wire [4:0] a_bits_addr_lo;
  sirv_repeater_6 u_repeater (
    .clock(clock),
    .reset(reset),
    .repeat_en(         repeater_repeat),
    .full(              repeater_full),
    .enq_ready(         repeater_enq_ready),
    .enq_valid(         in_tl_a_valid),
    .enq_bits_opcode(   in_tl_a_bits_opcode),
    .enq_bits_param(    in_tl_a_bits_param),
    .enq_bits_size(     in_tl_a_bits_size),
    .enq_bits_source(   in_tl_a_bits_source),
    .enq_bits_address(  in_tl_a_bits_address),
    .enq_bits_mask(     in_tl_a_bits_mask),
    .enq_bits_data(     in_tl_a_bits_data),
    .deq_ready(         out_tl_a_ready),
    .deq_valid(         repeater_deq_valid),
    .deq_bits_opcode(   repeater_deq_bits_opcode),
    .deq_bits_param(    repeater_deq_bits_param),
    .deq_bits_size(     repeater_deq_bits_size),
    .deq_bits_source(   repeater_deq_bits_source),
    .deq_bits_address(  repeater_deq_bits_address),
    .deq_bits_mask(     repeater_deq_bits_mask),
    .deq_bits_data(     /*repeater_deq_bits_data*/ ) // data unused
  );
  assign in_tl_a_ready = repeater_enq_ready;
  assign in_tl_d_valid = out_tl_d_valid;
  assign in_tl_d_bits_opcode = out_tl_d_bits_opcode;
  assign in_tl_d_bits_param = out_tl_d_bits_param;
  assign in_tl_d_bits_size = (dFirst ? dFirst_size : dSaved_size);
  assign in_tl_d_bits_source = out_tl_d_bits_source[6:5];
  assign in_tl_d_bits_sink = out_tl_d_bits_sink;
  assign in_tl_d_bits_addr_lo = out_tl_d_bits_addr_lo & ~dsizeOH1;
  assign in_tl_d_bits_data = out_tl_d_bits_data;
  assign in_tl_d_bits_error = out_tl_d_bits_error;
  assign out_tl_a_valid = repeater_deq_valid;
  assign out_tl_a_bits_opcode = repeater_deq_bits_opcode;
  assign out_tl_a_bits_param = repeater_deq_bits_param;
  assign out_tl_a_bits_size = 3'h0;
  assign out_tl_a_bits_source = {repeater_deq_bits_source,new_gennum};
  assign out_tl_a_bits_address = repeater_deq_bits_address | {25'd0, a_bits_addr_lo};
  assign out_tl_a_bits_mask = repeater_full | in_tl_a_bits_mask;
  assign out_tl_a_bits_data = in_tl_a_bits_data;
  assign out_tl_d_ready = in_tl_d_ready;
  assign dFirst = acknum == 5'h0;
  assign dsizeOH1 = out_tl_d_bits_size != 3'h0; // maps 0->0, other->1
  assign GEN_5 = {4'd0, dsizeOH1};
  assign dFirst_acknum = out_tl_d_bits_source[4:0] | GEN_5;
  assign T_1434 = {dFirst_acknum,1'b1} & {1'h1,~dFirst_acknum};
  assign T_1438 = T_1434[5:4] != 2'h0;
  assign GEN_9 = {2'd0, T_1434[5:4]};
  assign T_1439 = GEN_9 | T_1434[3:0];
  assign T_1443 = T_1439[3:2] != 2'h0;
  assign T_1444 = T_1439[3:2] | T_1439[1:0];
  assign T_1446 = {T_1443,T_1444[1]};
  assign dFirst_size = {T_1438,T_1446};
  assign a_bits_addr_lo_mask = ~(5'h1f << repeater_deq_bits_size); // maps 0->5'b00000, 1->5'b00001, 2->5'b00011, 3->5'b00111,
                                                        //      4->5'b01111, other->5'b11111
  assign aFirst = gennum == 5'h0;
  assign new_gennum = aFirst ? a_bits_addr_lo_mask : (gennum - 1'h1);
  assign repeater_repeat = new_gennum != 5'h0;
  assign a_bits_addr_lo = ~new_gennum & a_bits_addr_lo_mask;

  always @(posedge clock or posedge reset) 
    if (reset) begin
      acknum <= 5'h0;
      dSaved_size <= 3'b0;
    end else if (out_tl_d_ready & out_tl_d_valid) begin
        if (dFirst) begin
          acknum <= dFirst_acknum;
          dSaved_size <= dFirst_size;
        end else begin
          acknum <= acknum - 5'h1;
        end
    end

  // Counts down the number of bytes to "fragment". The inverted value
  // is used as lowest address bits.
  always @(posedge clock or posedge reset) 
    if (reset) begin
      gennum <= 5'h0;
    end else if ((out_tl_a_ready & out_tl_a_valid)) begin
      gennum <= new_gennum;
    end

   // `ifndef SYNTHESIS
   // `ifdef PRINTF_COND
   //   if (`PRINTF_COND) begin
   // `endif
   //     if (~T_1419) begin
   //       $fwrite(32'h80000002,"Assertion failed\n    at Fragmenter.scala:149 assert (!out.d.valid || (acknum_fragment & acknum_size) === UInt(0))\n");
   //     end
   // `ifdef PRINTF_COND
   //   end
   // `endif
   // `endif
   // `ifndef SYNTHESIS
   // `ifdef STOP_COND
   //   if (`STOP_COND) begin
   // `endif
   //     if (~T_1419) begin
   //       $fatal;
   //     end
   // `ifdef STOP_COND
   //   end
   // `endif
   // `endif
   // `ifndef SYNTHESIS
   // `ifdef PRINTF_COND
   //   if (`PRINTF_COND) begin
   // `endif
   //     if (1'h0) begin
   //       $fwrite(32'h80000002,"Assertion failed\n    at Fragmenter.scala:237 assert (!repeater.io.full || !aHasData)\n");
   //     end
   // `ifdef PRINTF_COND
   //   end
   // `endif
   // `endif
   // `ifndef SYNTHESIS
   // `ifdef STOP_COND
   //   if (`STOP_COND) begin
   // `endif
   //     if (1'h0) begin
   //       $fatal;
   //     end
   // `ifdef STOP_COND
   //   end
   // `endif
   // `endif
   // `ifndef SYNTHESIS
   // `ifdef PRINTF_COND
   //   if (`PRINTF_COND) begin
   // `endif
   //     if (~T_1543) begin
   //       $fwrite(32'h80000002,"Assertion failed\n    at Fragmenter.scala:240 assert (!repeater.io.full || in_a.bits.mask === fullMask)\n");
   //     end
   // `ifdef PRINTF_COND
   //   end
   // `endif
   // `endif
   // `ifndef SYNTHESIS
   // `ifdef STOP_COND
   //   if (`STOP_COND) begin
   // `endif
   //     if (~T_1543) begin
   //       $fatal;
   //     end
   // `ifdef STOP_COND
   //   end
   // `endif
   // `endif
    //synopsys translate_off
  wire  T_1543;
  wire  T_1542;
  wire  T_1419;
  wire  T_1418;
  wire  T_1417;
  wire [4:0] T_1415;
  assign T_1415 = out_tl_d_bits_source[4:0] & GEN_5;
  assign T_1417 = T_1415 == 5'h0;
  assign T_1418 = ~out_tl_d_valid | T_1417;
  assign T_1419 = T_1418 | reset;
  assign T_1542 = ~repeater_full | repeater_deq_bits_mask;
  assign T_1543 = T_1542 | reset;
  always @(posedge clock or posedge reset) begin
        if (~T_1419) begin
          $fwrite(32'h80000002,"Assertion failed\n    at Fragmenter.scala:149 assert (!out.d.valid || (acknum_fragment & acknum_size) === UInt(0))\n");
        end
        if (~T_1543) begin
          $fwrite(32'h80000002,"Assertion failed\n    at Fragmenter.scala:240 assert (!repeater.io.full || in_a.bits.mask === fullMask)\n");
        end
        if (1'h0) begin
          $fwrite(32'h80000002,"Assertion failed\n    at Fragmenter.scala:237 assert (!repeater.io.full || !aHasData)\n");
        end
  end
    //synopsys translate_on
endmodule
