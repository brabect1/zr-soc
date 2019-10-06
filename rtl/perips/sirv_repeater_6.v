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

 */                                                                      
                                                                         
                                                                         
                                                                         
module sirv_repeater_6(
  input   clock,
  input   reset,
  input   repeat_en,
  output  full,
  output  enq_ready,
  input   enq_valid,
  input  [2:0] enq_bits_opcode,
  input  [2:0] enq_bits_param,
  input  [2:0] enq_bits_size,
  input  [1:0] enq_bits_source,
  input  [29:0] enq_bits_address,
  input   enq_bits_mask,
  input  [7:0] enq_bits_data,
  input   deq_ready,
  output  deq_valid,
  output [2:0] deq_bits_opcode,
  output [2:0] deq_bits_param,
  output [2:0] deq_bits_size,
  output [1:0] deq_bits_source,
  output [29:0] deq_bits_address,
  output  deq_bits_mask,
  output [7:0] deq_bits_data
);
  reg  full;
  wire save;
  reg [2:0] saved_opcode;
  reg [2:0] saved_param;
  reg [2:0] saved_size;
  reg [1:0] saved_source;
  reg [29:0] saved_address;
  reg  saved_mask;
  reg [7:0] saved_data;
  // using `full` to gate indicating "ready for new data" once full
  assign enq_ready = deq_ready & ~full;
  // output data valid when either input data ready or there are
  // saved data (i.e. full)
  assign deq_valid = enq_valid | full;
  assign deq_bits_opcode = (full ? saved_opcode : enq_bits_opcode);
  assign deq_bits_param = (full ? saved_param : enq_bits_param);
  assign deq_bits_size = (full ? saved_size : enq_bits_size);
  assign deq_bits_source = (full ? saved_source : enq_bits_source);
  assign deq_bits_address = (full ? saved_address : enq_bits_address);
  assign deq_bits_mask = (full ? saved_mask : enq_bits_mask);
  assign deq_bits_data = (full ? saved_data : enq_bits_data);

  assign save = enq_ready & enq_valid & repeat_en;

  always @(posedge clock or posedge reset)
    if (reset) begin
      full <= 1'h0;
    end else begin
      if (deq_ready & deq_valid & ~repeat_en) begin
        full <= 1'h0;
      end else if (save) begin
        full <= 1'h1;
      end
    end


  always @(posedge clock or posedge reset)
  if (reset) begin
    saved_opcode  <= 3'b0;
    saved_param   <= 3'b0;
    saved_size    <= 3'b0;
    saved_source  <= 2'b0;
    saved_address <= 30'b0;
    saved_mask <= 1'b0;
    saved_data <= 8'b0;
  end
  else if (save) begin
    saved_opcode <= enq_bits_opcode;
    saved_param <= enq_bits_param;
    saved_size <= enq_bits_size;
    saved_source <= enq_bits_source;
    saved_address <= enq_bits_address;
    saved_mask <= enq_bits_mask;
    saved_data <= enq_bits_data;
  end

endmodule
