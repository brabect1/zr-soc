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
   - Groupped individual bits into buses.
   - Remove unused TileLink channels.
   - Replaced async register modules with RTL equivalent code.

 */                                                                      
                                                                         
                                                                         
                                                                         
module sirv_gpio(
  input   clock,
  input   reset,
  output  [31:0] io_interrupts,
  output  io_in_0_a_ready,
  input   io_in_0_a_valid,
  input  [2:0] io_in_0_a_bits_opcode,
  input  [2:0] io_in_0_a_bits_param,
  input  [2:0] io_in_0_a_bits_size,
  input  [4:0] io_in_0_a_bits_source,
  input  [28:0] io_in_0_a_bits_address,
  input  [3:0] io_in_0_a_bits_mask,
  input  [31:0] io_in_0_a_bits_data,
  input   io_in_0_d_ready,
  output  io_in_0_d_valid,
  output [2:0] io_in_0_d_bits_opcode,
  output [1:0] io_in_0_d_bits_param,
  output [2:0] io_in_0_d_bits_size,
  output [4:0] io_in_0_d_bits_source,
  output  io_in_0_d_bits_sink,
  output [1:0] io_in_0_d_bits_addr_lo,
  output [31:0] io_in_0_d_bits_data,
  output  io_in_0_d_bits_error,

  input   [31:0] io_port_pins_i_ival,
  output  [31:0] io_port_pins_o_oval,
  output  [31:0] io_port_pins_o_oe,
  output  [31:0] io_port_pins_o_ie,
  output  [31:0] io_port_pins_o_pue,
  output  [31:0] io_port_pins_o_ds,

  output  [31:0] io_port_iof_0_i_ival,
  input   [31:0] io_port_iof_0_o_oval,
  input   [31:0] io_port_iof_0_o_oe,
  input   [31:0] io_port_iof_0_o_ie,
  input   [31:0] io_port_iof_0_o_valid,
  output  [31:0] io_port_iof_1_i_ival,
  input   [31:0] io_port_iof_1_o_oval,
  input   [31:0] io_port_iof_1_o_oe,
  input   [31:0] io_port_iof_1_o_ie,
  input   [31:0] io_port_iof_1_o_valid

);
  reg [31:0] portReg;
  reg [31:0] oeReg_io_q;
  reg [31:0] pueReg_io_q;
  reg [31:0] dsReg;
  reg [31:0] ieReg_io_q;
  reg [31:0] T_3256;
  reg [31:0] T_3257;
  reg [31:0] inSyncReg;
  reg [31:0] valueReg;
  reg [31:0] highIeReg;
  reg [31:0] lowIeReg;
  reg [31:0] riseIeReg;
  reg [31:0] fallIeReg;
  reg [31:0] highIpReg;
  reg [31:0] lowIpReg;
  reg [31:0] riseIpReg;
  reg [31:0] fallIpReg;
  reg [31:0] iofEnReg_io_q;
  reg [31:0] iofSelReg;
  reg [31:0] xorReg;
  wire [31:0] T_3269;
  wire  T_3312;
  wire [9:0] T_3316;
  wire  T_3457;
  wire  T_3858;
  wire [4:0] T_5301;
  wire  T_5318;
  wire  T_5321;
  wire  T_5323;
  wire [31:0] T_5359;
  wire  T_5411;
  always @(posedge clock or posedge reset) begin
    if (reset) begin
      oeReg_io_q <= 32'd0;
    end else if (T_5411 & T_5359[2] & T_3858) begin
      oeReg_io_q <= io_in_0_a_bits_data;
    end
  end

  always @(posedge clock or posedge reset) begin
    if (reset) begin
      pueReg_io_q <= 32'd0;
    end else if (T_5411 & T_5359[4] & T_3858) begin
      pueReg_io_q <= io_in_0_a_bits_data;
    end
  end

  always @(posedge clock or posedge reset) begin
    if (reset) begin
      ieReg_io_q <= 32'd0;
    end else if (T_5411 & T_5359[1] & T_3858) begin
      ieReg_io_q <= io_in_0_a_bits_data;
    end
  end

  always @(posedge clock or posedge reset) begin
    if (reset) begin
      iofEnReg_io_q <= 32'd0;
    end else if (T_5411 & T_5359[14] & T_3858) begin
      iofEnReg_io_q <= io_in_0_a_bits_data;
    end
  end

  genvar i;
  for (i=0; i<32; i=i+1) begin
    assign io_interrupts[i] = ((riseIpReg[i] & riseIeReg[i]) | (fallIpReg[i] & fallIeReg[i]) | (highIpReg[i] & highIeReg[i]) | (lowIpReg[i] & lowIeReg[i]));
  end

  assign io_in_0_a_ready = ((io_in_0_d_ready & T_5321) & T_5318);
  assign io_in_0_d_valid = (T_5323 & T_5321);
  assign io_in_0_d_bits_opcode = {2'd0, T_3312};
  assign io_in_0_d_bits_param = 2'h0;
  assign io_in_0_d_bits_size = T_3316[2:0];
  assign io_in_0_d_bits_source = T_3316[7:3];
  assign io_in_0_d_bits_sink = 1'h0;
  assign io_in_0_d_bits_addr_lo = T_3316[9:8];
  assign io_in_0_d_bits_data = (T_3457 ? (5'h10 == T_5301 ? xorReg : (5'hf == T_5301 ? iofSelReg : (5'he == T_5301 ? iofEnReg_io_q : (5'hd == T_5301 ? lowIpReg : (5'hc == T_5301 ? lowIeReg : (5'hb == T_5301 ? highIpReg : (5'ha == T_5301 ? highIeReg : (5'h9 == T_5301 ? fallIpReg : (5'h8 == T_5301 ? fallIeReg : (5'h7 == T_5301 ? riseIpReg : (5'h6 == T_5301 ? riseIeReg : (5'h5 == T_5301 ? dsReg : (5'h4 == T_5301 ? pueReg_io_q : (5'h3 == T_5301 ? portReg : (5'h2 == T_5301 ? oeReg_io_q : (5'h1 == T_5301 ? ieReg_io_q : (5'h0 == T_5301 ? valueReg : 32'h0))))))))))))))))) : 32'h0);
  assign io_in_0_d_bits_error = 1'h0;

  for (i=0; i<32; i=i+1) begin
    assign io_port_pins_o_oval[i] = ((iofEnReg_io_q[i] ? (iofSelReg[i] ? (io_port_iof_1_o_valid[i] ? io_port_iof_1_o_oval[i] : portReg[i]) : (io_port_iof_0_o_valid[i] ? io_port_iof_0_o_oval[i] : portReg[i])) : portReg[i]) ^ xorReg[i]);
    assign io_port_pins_o_oe[i] = (iofEnReg_io_q[i] ? (iofSelReg[i] ? (io_port_iof_1_o_valid[i] ? io_port_iof_1_o_oe[i] : oeReg_io_q[i]) : (io_port_iof_0_o_valid[i] ? io_port_iof_0_o_oe[i] : oeReg_io_q[i])) : oeReg_io_q[i]);
    assign io_port_pins_o_ie[i] = (iofEnReg_io_q[i] ? (iofSelReg[i] ? (io_port_iof_1_o_valid[i] ? io_port_iof_1_o_ie[i] : ieReg_io_q[i]) : (io_port_iof_0_o_valid[i] ? io_port_iof_0_o_ie[i] : ieReg_io_q[i])) : ieReg_io_q[i]);
  end

  assign io_port_pins_o_pue = pueReg_io_q;
  assign io_port_pins_o_ds =  dsReg;

  assign io_port_iof_0_i_ival = inSyncReg;
  assign io_port_iof_1_i_ival = inSyncReg;
  assign T_3269 = ~ valueReg;
  assign T_3312 = io_in_0_a_bits_opcode == 3'h4;
  assign T_3316 = {io_in_0_a_bits_address[1:0],io_in_0_a_bits_source,io_in_0_a_bits_size};
  assign T_3457 = io_in_0_a_bits_address[11:7] == 5'h0;
  assign T_3858 = { {8{io_in_0_a_bits_mask[3]}}, {8{io_in_0_a_bits_mask[2]}}, {8{io_in_0_a_bits_mask[1]}}, {8{io_in_0_a_bits_mask[0]}} } == 32'hffffffff;
  assign T_5301 = io_in_0_a_bits_address[6:2];
  assign T_5318 = 1'b1;
  assign T_5321 = 1'b1;
  assign T_5323 = io_in_0_a_valid & T_5318;
  assign T_5359 = (32'h1 << T_5301);
  assign T_5411 = T_5323 & io_in_0_d_ready & ~T_3312;

  always @(posedge clock or posedge reset)
    if(reset) begin
      T_3256 <= 32'b0;
      T_3257 <= 32'b0;
      inSyncReg <= 32'b0;
    end
    else begin
      T_3256 <= io_port_pins_i_ival;
      T_3257 <= T_3256;
      inSyncReg <= T_3257;
    end

  always @(posedge clock or posedge reset) 
    if (reset) begin
      portReg <= 32'h0;
    end else if (T_5411 & T_5359[3] & T_3858) begin
      portReg <= io_in_0_a_bits_data;
    end

  always @(posedge clock or posedge reset)
    if (reset) begin
      dsReg <= 32'h0;
    end else if (T_5411 & T_5359[5] & T_3858) begin
      dsReg <= io_in_0_a_bits_data;
    end


  always @(posedge clock or posedge reset)
    if (reset) begin
      valueReg <= 32'h0;
    end else begin
      valueReg <= inSyncReg;
    end

  always @(posedge clock or posedge reset)
    if (reset) begin
      highIeReg <= 32'h0;
    end else if (T_5411 & T_5359[10] & T_3858) begin
      highIeReg <= io_in_0_a_bits_data;
    end

  always @(posedge clock or posedge reset)
    if (reset) begin
      lowIeReg <= 32'h0;
    end else if (T_5411 & T_5359[12] & T_3858) begin
      lowIeReg <= io_in_0_a_bits_data;
    end

  always @(posedge clock or posedge reset)
    if (reset) begin
      riseIeReg <= 32'h0;
    end else if (T_5411 & T_5359[6] & T_3858) begin
      riseIeReg <= io_in_0_a_bits_data;
    end

  always @(posedge clock or posedge reset)
    if (reset) begin
      fallIeReg <= 32'h0;
    end else if (T_5411 & T_5359[8] & T_3858) begin
      fallIeReg <= io_in_0_a_bits_data;
    end

  always @(posedge clock or posedge reset)
    if (reset) begin
      highIpReg <= 32'h0;
    end else begin
      highIpReg <= ((~ ((~ highIpReg) | (((T_5411 & T_5359[11]) & T_3858) ? io_in_0_a_bits_data : 32'h0))) | valueReg);
    end

  always @(posedge clock or posedge reset)
    if (reset) begin
      lowIpReg <= 32'h0;
    end else begin
      lowIpReg <= ((~ ((~ lowIpReg) | (((T_5411 & T_5359[13]) & T_3858) ? io_in_0_a_bits_data : 32'h0))) | T_3269);
    end

  always @(posedge clock or posedge reset)
    if (reset) begin
      riseIpReg <= 32'h0;
    end else begin
      riseIpReg <= ((~ ((~ riseIpReg) | (((T_5411 & T_5359[7]) & T_3858) ? io_in_0_a_bits_data : 32'h0))) | (T_3269 & inSyncReg));
    end

  always @(posedge clock or posedge reset)
    if (reset) begin
      fallIpReg <= 32'h0;
    end else begin
      fallIpReg <= ((~ ((~ fallIpReg) | (((T_5411 & T_5359[9]) & T_3858) ? io_in_0_a_bits_data : 32'h0))) | (valueReg & (~ inSyncReg)));
    end

  always @(posedge clock or posedge reset)
    if (reset) begin
      iofSelReg <= 32'h0;
    end else if (T_5411 & T_5359[15] & T_3858) begin
      iofSelReg <= io_in_0_a_bits_data;
    end

  always @(posedge clock or posedge reset)
    if (reset) begin
      xorReg <= 32'h0;
    end else if (T_5411 & T_5359[16] & T_3858) begin
      xorReg <= io_in_0_a_bits_data;
    end

endmodule
