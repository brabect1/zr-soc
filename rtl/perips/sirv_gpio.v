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
  output  [31:0] gpio_irq,
  output  tl_a_ready,
  input   tl_a_valid,
  input  [2:0] tl_a_bits_opcode,
  input  [2:0] tl_a_bits_param,
  input  [2:0] tl_a_bits_size,
  input  [4:0] tl_a_bits_source,
  input  [28:0] tl_a_bits_address,
  input  [3:0] tl_a_bits_mask,
  input  [31:0] tl_a_bits_data,
  input   tl_d_ready,
  output  tl_d_valid,
  output [2:0] tl_d_bits_opcode,
  output [1:0] tl_d_bits_param,
  output [2:0] tl_d_bits_size,
  output [4:0] tl_d_bits_source,
  output  tl_d_bits_sink,
  output [1:0] tl_d_bits_addr_lo,
  output [31:0] tl_d_bits_data,
  output  tl_d_bits_error,

  input   [31:0] io_pads_i_ival,
  output  [31:0] io_pads_o_oval,
  output  [31:0] io_pads_o_oe,
  output  [31:0] io_pads_o_ie,
  output  [31:0] io_pads_o_pue,
  output  [31:0] io_pads_o_ds,

  output  [31:0] iof_0_i_ival,
  input   [31:0] iof_0_o_oval,
  input   [31:0] iof_0_o_oe,
  input   [31:0] iof_0_o_ie,
  input   [31:0] iof_0_o_valid,
  output  [31:0] iof_1_i_ival,
  input   [31:0] iof_1_o_oval,
  input   [31:0] iof_1_o_oe,
  input   [31:0] iof_1_o_ie,
  input   [31:0] iof_1_o_valid

);
  reg [31:0] portReg;
  reg [31:0] oeReg_io_q;
  reg [31:0] pueReg_io_q;
  reg [31:0] dsReg;
  reg [31:0] ieReg_io_q;
  reg [31:0] sync_pads_d0;
  reg [31:0] sync_pads_d1;
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
  wire  op_rd;
//  wire  T_3457;
  wire  mask_valid;
  wire [4:0] addr_bits;
//  wire [31:0] T_5359;
  wire  wr_en;
  always @(posedge clock or posedge reset) begin
    if (reset) begin
      oeReg_io_q <= 32'd0;
    end else if (wr_en & (addr_bits==5'h02) & mask_valid) begin
      oeReg_io_q <= tl_a_bits_data;
    end
  end

  always @(posedge clock or posedge reset) begin
    if (reset) begin
      pueReg_io_q <= 32'd0;
    end else if (wr_en & (addr_bits==5'h04) & mask_valid) begin
      pueReg_io_q <= tl_a_bits_data;
    end
  end

  always @(posedge clock or posedge reset) begin
    if (reset) begin
      ieReg_io_q <= 32'd0;
    end else if (wr_en & (addr_bits==5'h01) & mask_valid) begin
      ieReg_io_q <= tl_a_bits_data;
    end
  end

  always @(posedge clock or posedge reset) begin
    if (reset) begin
      iofEnReg_io_q <= 32'd0;
    end else if (wr_en & (addr_bits == 5'h0e) & mask_valid) begin
      iofEnReg_io_q <= tl_a_bits_data;
    end
  end

  genvar i;
  for (i=0; i<32; i=i+1) begin
    assign gpio_irq[i] = ((riseIpReg[i] & riseIeReg[i]) | (fallIpReg[i] & fallIeReg[i]) | (highIpReg[i] & highIeReg[i]) | (lowIpReg[i] & lowIeReg[i]));
  end

  assign tl_a_ready = tl_d_ready;
  assign tl_d_valid = tl_a_valid;
  assign tl_d_bits_opcode = {2'd0, op_rd};
  assign tl_d_bits_param = 2'h0;
  assign tl_d_bits_size = tl_a_bits_size;
  assign tl_d_bits_source = tl_a_bits_source;
  assign tl_d_bits_sink = 1'h0;
  assign tl_d_bits_addr_lo = tl_a_bits_address[1:0];
//  assign T_3457 = tl_a_bits_address[11:7] == 5'h0;
//  assign tl_d_bits_data = (T_3457 ? (5'h10 == addr_bits ? xorReg : (5'hf == addr_bits ? iofSelReg : (5'he == addr_bits ? iofEnReg_io_q : (5'hd == addr_bits ? lowIpReg : (5'hc == addr_bits ? lowIeReg : (5'hb == addr_bits ? highIpReg : (5'ha == addr_bits ? highIeReg : (5'h9 == addr_bits ? fallIpReg : (5'h8 == addr_bits ? fallIeReg : (5'h7 == addr_bits ? riseIpReg : (5'h6 == addr_bits ? riseIeReg : (5'h5 == addr_bits ? dsReg : (5'h4 == addr_bits ? pueReg_io_q : (5'h3 == addr_bits ? portReg : (5'h2 == addr_bits ? oeReg_io_q : (5'h1 == addr_bits ? ieReg_io_q : (5'h0 == addr_bits ? valueReg : 32'h0))))))))))))))))) : 32'h0);
  assign tl_d_bits_error = 1'h0;

  for (i=0; i<32; i=i+1) begin
    assign io_pads_o_oval[i] = ((iofEnReg_io_q[i] ? (iofSelReg[i] ? (iof_1_o_valid[i] ? iof_1_o_oval[i] : portReg[i]) : (iof_0_o_valid[i] ? iof_0_o_oval[i] : portReg[i])) : portReg[i]) ^ xorReg[i]);
    assign io_pads_o_oe[i] = (iofEnReg_io_q[i] ? (iofSelReg[i] ? (iof_1_o_valid[i] ? iof_1_o_oe[i] : oeReg_io_q[i]) : (iof_0_o_valid[i] ? iof_0_o_oe[i] : oeReg_io_q[i])) : oeReg_io_q[i]);
    assign io_pads_o_ie[i] = (iofEnReg_io_q[i] ? (iofSelReg[i] ? (iof_1_o_valid[i] ? iof_1_o_ie[i] : ieReg_io_q[i]) : (iof_0_o_valid[i] ? iof_0_o_ie[i] : ieReg_io_q[i])) : ieReg_io_q[i]);
  end

  assign io_pads_o_pue = pueReg_io_q;
  assign io_pads_o_ds =  dsReg;

  assign iof_0_i_ival = inSyncReg;
  assign iof_1_i_ival = inSyncReg;
  assign op_rd = tl_a_bits_opcode == 3'h4;
  assign mask_valid = &tl_a_bits_mask;
  assign addr_bits = tl_a_bits_address[6:2];
//  assign T_5359 = (32'h1 << addr_bits);
  assign wr_en = tl_a_valid & tl_d_ready & ~op_rd;

  always @(*)
    if (tl_a_bits_address[11:7] == 5'h0) begin
      case (addr_bits)
        5'h10:   tl_d_bits_data = xorReg;
        5'h0f:   tl_d_bits_data = iofSelReg;
        5'h0e:   tl_d_bits_data = iofEnReg_io_q;
        5'h0d:   tl_d_bits_data = lowIpReg;
        5'h0c:   tl_d_bits_data = lowIeReg;
        5'h0b:   tl_d_bits_data = highIpReg;
        5'h0a:   tl_d_bits_data = highIeReg;
        5'h09:   tl_d_bits_data = fallIpReg;
        5'h08:   tl_d_bits_data = fallIeReg;
        5'h07:   tl_d_bits_data = riseIpReg;
        5'h06:   tl_d_bits_data = riseIeReg;
        5'h05:   tl_d_bits_data = dsReg;
        5'h04:   tl_d_bits_data = pueReg_io_q;
        5'h03:   tl_d_bits_data = portReg;
        5'h02:   tl_d_bits_data = oeReg_io_q;
        5'h01:   tl_d_bits_data = ieReg_io_q;
        5'h00:   tl_d_bits_data = valueReg;
        default: tl_d_bits_data = 32'h0;
      endcase
    end
    else begin
      tl_d_bits_data = 32'h0;
    end

  always @(posedge clock or posedge reset)
    if(reset) begin
      sync_pads_d0 <= 32'b0;
      sync_pads_d1 <= 32'b0;
      inSyncReg <= 32'b0;
    end
    else begin
      sync_pads_d0 <= io_pads_i_ival;
      sync_pads_d1 <= sync_pads_d0;
      inSyncReg <= sync_pads_d1;
    end

  always @(posedge clock or posedge reset) 
    if (reset) begin
      portReg <= 32'h0;
    end else if (wr_en & (addr_bits==5'h03) & mask_valid) begin
      portReg <= tl_a_bits_data;
    end

  always @(posedge clock or posedge reset)
    if (reset) begin
      dsReg <= 32'h0;
    end else if (wr_en & (addr_bits==5'h05) & mask_valid) begin
      dsReg <= tl_a_bits_data;
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
    end else if (wr_en & (addr_bits==5'h0a) & mask_valid) begin
      highIeReg <= tl_a_bits_data;
    end

  always @(posedge clock or posedge reset)
    if (reset) begin
      lowIeReg <= 32'h0;
    end else if (wr_en & (addr_bits==5'h0c) & mask_valid) begin
      lowIeReg <= tl_a_bits_data;
    end

  always @(posedge clock or posedge reset)
    if (reset) begin
      riseIeReg <= 32'h0;
    end else if (wr_en & (addr_bits==5'h06) & mask_valid) begin
      riseIeReg <= tl_a_bits_data;
    end

  always @(posedge clock or posedge reset)
    if (reset) begin
      fallIeReg <= 32'h0;
    end else if (wr_en & (addr_bits==5'h08) & mask_valid) begin
      fallIeReg <= tl_a_bits_data;
    end

  always @(posedge clock or posedge reset)
    if (reset) begin
      highIpReg <= 32'h0;
    end else begin
      highIpReg <= ((~ (~highIpReg | ((wr_en & (addr_bits==5'h0b) & mask_valid) ? tl_a_bits_data : 32'h0))) | valueReg);
    end

  always @(posedge clock or posedge reset)
    if (reset) begin
      lowIpReg <= 32'h0;
    end else begin
      lowIpReg <= ((~ (~lowIpReg | ((wr_en & (addr_bits==5'h0d) & mask_valid) ? tl_a_bits_data : 32'h0))) | ~valueReg);
    end

  always @(posedge clock or posedge reset)
    if (reset) begin
      riseIpReg <= 32'h0;
    end else begin
      riseIpReg <= ((~ (~riseIpReg | ((wr_en & (addr_bits==5'h07) & mask_valid) ? tl_a_bits_data : 32'h0))) | (~valueReg & inSyncReg));
    end

  always @(posedge clock or posedge reset)
    if (reset) begin
      fallIpReg <= 32'h0;
    end else begin
      fallIpReg <= ((~ (~fallIpReg | ((wr_en & (addr_bits==5'h09) & mask_valid) ? tl_a_bits_data : 32'h0))) | (valueReg & ~inSyncReg));
    end

  always @(posedge clock or posedge reset)
    if (reset) begin
      iofSelReg <= 32'h0;
    end else if (wr_en & (addr_bits == 5'h0f) & mask_valid) begin
      iofSelReg <= tl_a_bits_data;
    end

  always @(posedge clock or posedge reset)
    if (reset) begin
      xorReg <= 32'h0;
    end else if (wr_en & (addr_bits == 5'h10) & mask_valid) begin
      xorReg <= tl_a_bits_data;
    end

endmodule
