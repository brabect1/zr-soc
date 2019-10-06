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
                                                                         
                                                                         
                                                                         

module sirv_flash_qspi(
  input   clock,
  input   reset,
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

  // data (read-write) TL interface
  output  io_tl_i_0_0,
  output  tl_dat_a_ready,
  input   tl_dat_a_valid,
  input  [2:0] tl_dat_a_bits_opcode,
  input  [2:0] tl_dat_a_bits_param,
  input  [2:0] tl_dat_a_bits_size,
  input  [4:0] tl_dat_a_bits_source,
  input  [28:0] tl_dat_a_bits_address,
  input  [3:0] tl_dat_a_bits_mask,
  input  [31:0] tl_dat_a_bits_data,
  input   tl_dat_d_ready,
  output  tl_dat_d_valid,
  output [2:0] tl_dat_d_bits_opcode,
  output [1:0] tl_dat_d_bits_param,
  output [2:0] tl_dat_d_bits_size,
  output [4:0] tl_dat_d_bits_source,
  output  tl_dat_d_bits_sink,
  output [1:0] tl_dat_d_bits_addr_lo,
  output [31:0] tl_dat_d_bits_data,
  output  tl_dat_d_bits_error,

  // instruction (read-only) TL interface
  output  tl_ins_a_ready,
  input   tl_ins_a_valid,
  input  [2:0] tl_ins_a_bits_opcode,
  input  [2:0] tl_ins_a_bits_param,
  input  [2:0] tl_ins_a_bits_size,
  input  [6:0] tl_ins_a_bits_source,
  input  [29:0] tl_ins_a_bits_address,
  input   tl_ins_a_bits_mask,
  input  [7:0] tl_ins_a_bits_data, // unused
  input   tl_ins_d_ready,
  output  tl_ins_d_valid,
  output [2:0] tl_ins_d_bits_opcode,
  output [1:0] tl_ins_d_bits_param,
  output [2:0] tl_ins_d_bits_size,
  output [6:0] tl_ins_d_bits_source,
  output  tl_ins_d_bits_sink,
  output  tl_ins_d_bits_addr_lo,
  output [7:0] tl_ins_d_bits_data,
  output  tl_ins_d_bits_error
);
  reg [1:0] ctrl_fmt_proto;
  reg  ctrl_fmt_endian;
  reg  ctrl_fmt_iodir;
  reg [3:0] ctrl_fmt_len;
  reg [11:0] ctrl_sck_div;
  reg  ctrl_sck_pol;
  reg  ctrl_sck_pha;
  reg  ctrl_cs_id;
  reg  ctrl_cs_dflt_0;
  reg [1:0] ctrl_cs_mode;
  reg [7:0] ctrl_dla_cssck;
  reg [7:0] ctrl_dla_sckcs;
  reg [7:0] ctrl_dla_intercs;
  reg [7:0] ctrl_dla_interxfr;
  reg [3:0] ctrl_wm_tx;
  reg [3:0] ctrl_wm_rx;
  wire  fifo_io_link_tx_valid;
  wire [7:0] fifo_io_link_tx_bits;
  wire [7:0] fifo_io_link_cnt;
  wire [1:0] fifo_io_link_fmt_proto;
  wire  fifo_io_link_fmt_endian;
  wire  fifo_io_link_fmt_iodir;
  wire  fifo_io_link_cs_set;
  wire  fifo_io_link_cs_clear;
  wire  fifo_io_link_cs_hold;
  wire  fifo_io_link_lock;
  wire  fifo_io_tx_ready;
  wire  fifo_io_rx_valid;
  wire [7:0] fifo_io_rx_bits;
  wire  fifo_io_ip_txwm;
  wire  fifo_io_ip_rxwm;
  wire  mac_io_port_sck;
  wire  mac_io_port_dq_0_o;
  wire  mac_io_port_dq_0_oe;
  wire  mac_io_port_dq_1_o;
  wire  mac_io_port_dq_1_oe;
  wire  mac_io_port_dq_2_o;
  wire  mac_io_port_dq_2_oe;
  wire  mac_io_port_dq_3_o;
  wire  mac_io_port_dq_3_oe;
  wire  mac_io_port_cs_0;
  wire  mac_io_link_tx_ready;
  wire  mac_io_link_rx_valid;
  wire [7:0] mac_io_link_rx_bits;
  wire  mac_io_link_active;
  reg  ie_txwm;
  reg  ie_rxwm;
  wire  flash_io_addr_ready;
  wire  flash_io_data_valid;
  wire [7:0] flash_io_data_bits;
  wire  flash_io_link_tx_valid;
  wire [7:0] flash_io_link_tx_bits;
  wire [7:0] flash_io_link_cnt;
  wire [1:0] flash_io_link_fmt_proto;
  wire  flash_io_link_fmt_endian;
  wire  flash_io_link_fmt_iodir;
  wire  flash_io_link_cs_set;
  wire  flash_io_link_cs_clear;
  wire  flash_io_link_cs_hold;
  wire  flash_io_link_lock;
  wire  arb_io_inner_0_tx_ready;
  wire  arb_io_inner_0_rx_valid;
  wire [7:0] arb_io_inner_0_rx_bits;
  wire  arb_io_inner_0_active;
  wire  arb_io_inner_1_tx_ready;
  wire  arb_io_inner_1_rx_valid;
  wire [7:0] arb_io_inner_1_rx_bits;
  wire  arb_io_inner_1_active;
  wire  arb_io_outer_tx_valid;
  wire [7:0] arb_io_outer_tx_bits;
  wire [7:0] arb_io_outer_cnt;
  wire [1:0] arb_io_outer_fmt_proto;
  wire  arb_io_outer_fmt_endian;
  wire  arb_io_outer_fmt_iodir;
  wire  arb_io_outer_cs_set;
  wire  arb_io_outer_cs_clear;
  wire  arb_io_outer_cs_hold;
  reg [2:0] a_size;
  reg [6:0] a_source;
  reg [29:0] a_address;
  reg [1:0] insn_cmd_proto;
  reg [7:0] insn_cmd_code;
  reg  insn_cmd_en;
  reg [1:0] insn_addr_proto;
  reg [2:0] insn_addr_len;
  reg [7:0] insn_pad_code;
  reg [3:0] insn_pad_cnt;
  reg [1:0] insn_data_proto;
  reg  flash_en;
  wire  op_rd;
  wire  T_2191;
  wire [4:0] addr_bits;
  wire [31:0] addr_sel_onehot;
  wire  wr_en;
  wire  T_4926;
  wire  T_5106;
  wire  T_5126;
  wire  T_5226;
  wire  T_5406;
  wire  T_5466;
  assign fifo_io_link_fmt_endian = ctrl_fmt_endian;
  assign fifo_io_link_fmt_proto = ctrl_fmt_proto;
  assign fifo_io_link_fmt_iodir = ctrl_fmt_iodir;
  sirv_qspi_fifo fifo (
    .clock(clock),
    .reset(reset),
    .ctrl_fmt_proto(ctrl_fmt_proto),
//    .ctrl_fmt_endian(ctrl_fmt_endian),
    .ctrl_fmt_iodir(ctrl_fmt_iodir),
    .ctrl_fmt_len(ctrl_fmt_len),
    .ctrl_cs_mode(ctrl_cs_mode),
    .ctrl_wm_tx(ctrl_wm_tx),
    .ctrl_wm_rx(ctrl_wm_rx),
    .link_tx_ready(arb_io_inner_1_tx_ready),
    .link_tx_valid(fifo_io_link_tx_valid),
    .link_tx_bits(fifo_io_link_tx_bits),
    .link_rx_valid(arb_io_inner_1_rx_valid),
    .link_rx_bits(arb_io_inner_1_rx_bits),
    .link_cnt(fifo_io_link_cnt),
//    .link_fmt_proto(fifo_io_link_fmt_proto),
//    .link_fmt_endian(fifo_io_link_fmt_endian),
//    .link_fmt_iodir(fifo_io_link_fmt_iodir),
    .link_cs_set(fifo_io_link_cs_set),
    .link_cs_clear(fifo_io_link_cs_clear),
    .link_cs_hold(fifo_io_link_cs_hold),
//    .link_active(arb_io_inner_1_active),
    .link_lock(fifo_io_link_lock),
    .io_tx_ready(fifo_io_tx_ready),
    .io_tx_valid(wr_en & addr_sel_onehot[18] & tl_dat_a_bits_mask[0]),
    .io_tx_bits(tl_dat_a_bits_data[7:0]),
    .io_rx_ready(tl_dat_a_valid & tl_dat_d_ready & op_rd & addr_sel_onehot[19] & tl_dat_a_bits_mask[0]),
    .io_rx_valid(fifo_io_rx_valid),
    .io_rx_bits(fifo_io_rx_bits),
    .ip_txwm(fifo_io_ip_txwm),
    .ip_rxwm(fifo_io_ip_rxwm)
  );
  sirv_qspi_media mac (
    .clock(clock),
    .reset(reset),
    .io_port_sck(mac_io_port_sck),
    .io_port_dq_0_i(io_port_dq_0_i),
    .io_port_dq_0_o(mac_io_port_dq_0_o),
    .io_port_dq_0_oe(mac_io_port_dq_0_oe),
    .io_port_dq_1_i(io_port_dq_1_i),
    .io_port_dq_1_o(mac_io_port_dq_1_o),
    .io_port_dq_1_oe(mac_io_port_dq_1_oe),
    .io_port_dq_2_i(io_port_dq_2_i),
    .io_port_dq_2_o(mac_io_port_dq_2_o),
    .io_port_dq_2_oe(mac_io_port_dq_2_oe),
    .io_port_dq_3_i(io_port_dq_3_i),
    .io_port_dq_3_o(mac_io_port_dq_3_o),
    .io_port_dq_3_oe(mac_io_port_dq_3_oe),
    .io_port_cs_0(mac_io_port_cs_0),
    .io_ctrl_sck_div(ctrl_sck_div),
    .io_ctrl_sck_pol(ctrl_sck_pol),
    .io_ctrl_sck_pha(ctrl_sck_pha),
    .io_ctrl_dla_cssck(ctrl_dla_cssck),
    .io_ctrl_dla_sckcs(ctrl_dla_sckcs),
    .io_ctrl_dla_intercs(ctrl_dla_intercs),
    .io_ctrl_dla_interxfr(ctrl_dla_interxfr),
    .io_ctrl_cs_id(ctrl_cs_id),
    .io_ctrl_cs_dflt_0(ctrl_cs_dflt_0),
    .io_link_tx_ready(mac_io_link_tx_ready),
    .io_link_tx_valid(arb_io_outer_tx_valid),
    .io_link_tx_bits(arb_io_outer_tx_bits),
    .io_link_rx_valid(mac_io_link_rx_valid),
    .io_link_rx_bits(mac_io_link_rx_bits),
    .io_link_cnt(arb_io_outer_cnt),
    .io_link_fmt_proto(arb_io_outer_fmt_proto),
    .io_link_fmt_endian(arb_io_outer_fmt_endian),
    .io_link_fmt_iodir(arb_io_outer_fmt_iodir),
    .io_link_cs_set(arb_io_outer_cs_set),
    .io_link_cs_clear(arb_io_outer_cs_clear),
    .io_link_cs_hold(arb_io_outer_cs_hold),
    .io_link_active(mac_io_link_active)
  );
  sirv_qspi_flashmap flash (
    .clock(clock),
    .reset(reset),
    .io_en(flash_en),
    .io_ctrl_insn_cmd_proto(insn_cmd_proto),
    .io_ctrl_insn_cmd_code(insn_cmd_code),
    .io_ctrl_insn_cmd_en(insn_cmd_en),
    .io_ctrl_insn_addr_proto(insn_addr_proto),
    .io_ctrl_insn_addr_len(insn_addr_len),
    .io_ctrl_insn_pad_code(insn_pad_code),
    .io_ctrl_insn_pad_cnt(insn_pad_cnt),
    .io_ctrl_insn_data_proto(insn_data_proto),
    .io_ctrl_fmt_endian(ctrl_fmt_endian),
    .io_addr_ready(flash_io_addr_ready),
    .io_addr_valid(tl_ins_a_valid),
    .io_addr_bits_next({3'd0, tl_ins_a_bits_address[28:0]}),
    .io_addr_bits_hold({3'd0, a_address[28:0]}),
    .io_data_ready(tl_ins_d_ready),
    .io_data_valid(flash_io_data_valid),
    .io_data_bits(flash_io_data_bits),
    .io_link_tx_ready(arb_io_inner_0_tx_ready),
    .io_link_tx_valid(flash_io_link_tx_valid),
    .io_link_tx_bits(flash_io_link_tx_bits),
    .io_link_rx_valid(arb_io_inner_0_rx_valid),
    .io_link_rx_bits(arb_io_inner_0_rx_bits),
    .io_link_cnt(flash_io_link_cnt),
    .io_link_fmt_proto(flash_io_link_fmt_proto),
    .io_link_fmt_endian(flash_io_link_fmt_endian),
    .io_link_fmt_iodir(flash_io_link_fmt_iodir),
    .io_link_cs_set(flash_io_link_cs_set),
    .io_link_cs_clear(flash_io_link_cs_clear),
    .io_link_cs_hold(flash_io_link_cs_hold),
    .io_link_active(arb_io_inner_0_active),
    .io_link_lock(flash_io_link_lock)
  );
  sirv_qspi_arbiter arb (
    .clock(clock),
    .reset(reset),
    .io_inner_0_tx_ready(arb_io_inner_0_tx_ready),
    .io_inner_0_tx_valid(flash_io_link_tx_valid),
    .io_inner_0_tx_bits(flash_io_link_tx_bits),
    .io_inner_0_rx_valid(arb_io_inner_0_rx_valid),
    .io_inner_0_rx_bits(arb_io_inner_0_rx_bits),
    .io_inner_0_cnt(flash_io_link_cnt),
    .io_inner_0_fmt_proto(flash_io_link_fmt_proto),
    .io_inner_0_fmt_endian(flash_io_link_fmt_endian),
    .io_inner_0_fmt_iodir(flash_io_link_fmt_iodir),
    .io_inner_0_cs_set(flash_io_link_cs_set),
    .io_inner_0_cs_clear(flash_io_link_cs_clear),
    .io_inner_0_cs_hold(flash_io_link_cs_hold),
    .io_inner_0_active(arb_io_inner_0_active),
    .io_inner_0_lock(flash_io_link_lock),
    .io_inner_1_tx_ready(arb_io_inner_1_tx_ready),
    .io_inner_1_tx_valid(fifo_io_link_tx_valid),
    .io_inner_1_tx_bits(fifo_io_link_tx_bits),
    .io_inner_1_rx_valid(arb_io_inner_1_rx_valid),
    .io_inner_1_rx_bits(arb_io_inner_1_rx_bits),
    .io_inner_1_cnt(fifo_io_link_cnt),
    .io_inner_1_fmt_proto(fifo_io_link_fmt_proto),
    .io_inner_1_fmt_endian(fifo_io_link_fmt_endian),
    .io_inner_1_fmt_iodir(fifo_io_link_fmt_iodir),
    .io_inner_1_cs_set(fifo_io_link_cs_set),
    .io_inner_1_cs_clear(fifo_io_link_cs_clear),
    .io_inner_1_cs_hold(fifo_io_link_cs_hold),
    .io_inner_1_active(arb_io_inner_1_active),
    .io_inner_1_lock(fifo_io_link_lock),
    .io_outer_tx_ready(mac_io_link_tx_ready),
    .io_outer_tx_valid(arb_io_outer_tx_valid),
    .io_outer_tx_bits(arb_io_outer_tx_bits),
    .io_outer_rx_valid(mac_io_link_rx_valid),
    .io_outer_rx_bits(mac_io_link_rx_bits),
    .io_outer_cnt(arb_io_outer_cnt),
    .io_outer_fmt_proto(arb_io_outer_fmt_proto),
    .io_outer_fmt_endian(arb_io_outer_fmt_endian),
    .io_outer_fmt_iodir(arb_io_outer_fmt_iodir),
    .io_outer_cs_set(arb_io_outer_cs_set),
    .io_outer_cs_clear(arb_io_outer_cs_clear),
    .io_outer_cs_hold(arb_io_outer_cs_hold),
    .io_outer_active(mac_io_link_active),
    .io_sel((flash_en == 1'h0))
  );
  assign io_port_sck = mac_io_port_sck;
  assign io_port_dq_0_o = mac_io_port_dq_0_o;
  assign io_port_dq_0_oe = mac_io_port_dq_0_oe;
  assign io_port_dq_1_o = mac_io_port_dq_1_o;
  assign io_port_dq_1_oe = mac_io_port_dq_1_oe;
  assign io_port_dq_2_o = mac_io_port_dq_2_o;
  assign io_port_dq_2_oe = mac_io_port_dq_2_oe;
  assign io_port_dq_3_o = mac_io_port_dq_3_o;
  assign io_port_dq_3_oe = mac_io_port_dq_3_oe;
  assign io_port_cs_0 = mac_io_port_cs_0;
  assign io_tl_i_0_0 = ((fifo_io_ip_txwm & ie_txwm) | (fifo_io_ip_rxwm & ie_rxwm));
  assign tl_dat_a_ready = tl_dat_d_ready;
  assign tl_dat_d_valid = tl_dat_a_valid;
  assign tl_dat_d_bits_opcode = {{2'd0}, op_rd};
  assign tl_dat_d_bits_param = 2'h0;
  assign tl_dat_d_bits_size = tl_dat_a_bits_size;
  assign tl_dat_d_bits_source = tl_dat_a_bits_source;
  assign tl_dat_d_bits_sink = 1'h0;
  assign tl_dat_d_bits_addr_lo = tl_dat_a_bits_address[1:0];
  assign tl_dat_d_bits_data = T_2191 ? (5'h1f == addr_bits ? 32'h0 : (5'h1e == addr_bits ? 32'h0 : (5'h1d == addr_bits ? ({{30'd0}, (({{1'd0}, fifo_io_ip_txwm}) | (({{1'd0}, fifo_io_ip_rxwm}) << 1))}) : (5'h1c == addr_bits ? ({{30'd0}, (({{1'd0}, ie_txwm}) | (({{1'd0}, ie_rxwm}) << 1))}) : (5'h1b == addr_bits ? 32'h0 : (5'h1a == addr_bits ? 32'h0 : (5'h19 == addr_bits ? (({{8'd0}, (({{10'd0}, (({{2'd0}, (({{2'd0}, (({{2'd0}, (({{4'd0}, (({{3'd0}, insn_cmd_en}) | (({{1'd0}, insn_addr_len}) << 1))}) | (({{4'd0}, insn_pad_cnt}) << 4))}) | (({{8'd0}, insn_cmd_proto}) << 8))}) | (({{10'd0}, insn_addr_proto}) << 10))}) | (({{12'd0}, insn_data_proto}) << 12))}) | (({{16'd0}, insn_cmd_code}) << 16))}) | (({{24'd0}, insn_pad_code}) << 24)) : (5'h18 == addr_bits ? ({{31'd0}, flash_en}) : (5'h17 == addr_bits ? 32'h0 : (5'h16 == addr_bits ? 32'h0 : (5'h15 == addr_bits ? ({{28'd0}, ctrl_wm_rx}) : (5'h14 == addr_bits ? ({{28'd0}, ctrl_wm_tx}) : (5'h13 == addr_bits ? (({{1'd0}, ({{23'd0}, fifo_io_rx_bits})}) | (({{31'd0}, (fifo_io_rx_valid == 1'h0)}) << 31)) : (5'h12 == addr_bits ? (({{31'd0}, (fifo_io_tx_ready == 1'h0)}) << 31) : (5'h11 == addr_bits ? 32'h0 : (5'h10 == addr_bits ? ({{12'd0}, (({{16'd0}, (({{1'd0}, (({{1'd0}, ctrl_fmt_proto}) | (({{2'd0}, ctrl_fmt_endian}) << 2))}) | (({{3'd0}, ctrl_fmt_iodir}) << 3))}) | (({{16'd0}, ctrl_fmt_len}) << 16))}) : (5'hf == addr_bits ? 32'h0 : (5'he == addr_bits ? 32'h0 : (5'hd == addr_bits ? 32'h0 : (5'hc == addr_bits ? 32'h0 : (5'hb == addr_bits ? ({{8'd0}, (({{16'd0}, ctrl_dla_intercs}) | (({{16'd0}, ctrl_dla_interxfr}) << 16))}) : (5'ha == addr_bits ? ({{8'd0}, (({{16'd0}, ctrl_dla_cssck}) | (({{16'd0}, ctrl_dla_sckcs}) << 16))}) : (5'h9 == addr_bits ? 32'h0 : (5'h8 == addr_bits ? 32'h0 : (5'h7 == addr_bits ? 32'h0 : (5'h6 == addr_bits ? ({{30'd0}, ctrl_cs_mode}) : (5'h5 == addr_bits ? ({{31'd0}, ctrl_cs_dflt_0}) : (5'h4 == addr_bits ? ({{31'd0}, ctrl_cs_id}) : (5'h3 == addr_bits ? 32'h0 : (5'h2 == addr_bits ? 32'h0 : (5'h1 == addr_bits ? ({{30'd0}, (({{1'd0}, ctrl_sck_pha}) | (({{1'd0}, ctrl_sck_pol}) << 1))}) : ({{20'd0}, ctrl_sck_div})))))))))))))))))))))))))))))))) : 32'h0;
  assign tl_dat_d_bits_error = 1'h0;
  assign tl_ins_a_ready = flash_io_addr_ready;
  assign tl_ins_d_valid = flash_io_data_valid;
  assign tl_ins_d_bits_opcode = 3'h1;
  assign tl_ins_d_bits_param = 2'h0;
  assign tl_ins_d_bits_size = a_size;
  assign tl_ins_d_bits_source = a_source;
  assign tl_ins_d_bits_sink = 1'h0;
  assign tl_ins_d_bits_addr_lo = 1'h0;
  assign tl_ins_d_bits_data = flash_io_data_bits;
  assign tl_ins_d_bits_error = 1'h0;
  assign op_rd = tl_dat_a_bits_opcode == 3'h4;
  assign T_2191 = tl_dat_a_bits_address[11:7] == 5'h0;
  assign addr_bits = tl_dat_a_bits_address[6:2];
  assign addr_sel_onehot = (32'h1 << addr_bits);
  assign wr_en = tl_dat_a_valid & tl_dat_d_ready & ~op_rd;
  assign T_4926 = wr_en & addr_sel_onehot[1];
  assign T_5106 = wr_en & addr_sel_onehot[10];
  assign T_5126 = wr_en & addr_sel_onehot[11];
  assign T_5226 = wr_en & addr_sel_onehot[16];
  assign T_5406 = wr_en & addr_sel_onehot[25];
  assign T_5466 = wr_en & addr_sel_onehot[28];

  always @(posedge clock or posedge reset)
    if (reset) begin
      ctrl_fmt_proto <= 2'h0;
      ctrl_fmt_endian <= 1'h0;
      ctrl_fmt_iodir <= 1'h0;
    end else begin
      if (T_5226 & tl_dat_a_bits_mask[0]) begin
        ctrl_fmt_proto <= tl_dat_a_bits_data[1:0];
        ctrl_fmt_endian <= tl_dat_a_bits_data[2];
        ctrl_fmt_iodir <= tl_dat_a_bits_data[3];
      end
    end

  always @(posedge clock or posedge reset)
    if (reset) begin
      ctrl_fmt_len <= 4'h8;
    end else begin
      if (T_5226 & tl_dat_a_bits_mask[2]) begin
        ctrl_fmt_len <= tl_dat_a_bits_data[19:16];
      end
    end

  always @(posedge clock or posedge reset)
    if (reset) begin
      ctrl_sck_div <= 12'h3;
    end else begin
      if (wr_en & addr_sel_onehot[0] & &tl_dat_a_bits_mask[1:0]) begin
        ctrl_sck_div <= tl_dat_a_bits_data[11:0];
      end
    end

  always @(posedge clock or posedge reset)
    if (reset) begin
      ctrl_sck_pha <= 1'h0;
      ctrl_sck_pol <= 1'h0;
    end else begin
      if (T_4926 & tl_dat_a_bits_mask[0]) begin
        ctrl_sck_pha <= tl_dat_a_bits_data[0];
        ctrl_sck_pol <= tl_dat_a_bits_data[1];
      end
    end

  always @(posedge clock or posedge reset)
    if (reset) begin
      ctrl_cs_id <= 1'h0;
    end else begin
      if (wr_en & addr_sel_onehot[4] & tl_dat_a_bits_mask[0]) begin
        ctrl_cs_id <= tl_dat_a_bits_data[0];
      end
    end

  always @(posedge clock or posedge reset)
    if (reset) begin
      ctrl_cs_dflt_0 <= 1'h1;
    end else begin
      if (wr_en & addr_sel_onehot[5] & tl_dat_a_bits_mask[0]) begin
        ctrl_cs_dflt_0 <= tl_dat_a_bits_data[0];
      end
    end

  always @(posedge clock or posedge reset)
    if (reset) begin
      ctrl_cs_mode <= 2'h0;
    end else begin
      if (wr_en & addr_sel_onehot[6] & tl_dat_a_bits_mask[0]) begin
        ctrl_cs_mode <= tl_dat_a_bits_data[1:0];
      end
    end

  always @(posedge clock or posedge reset)
    if (reset) begin
      ctrl_dla_cssck <= 8'h1;
    end else begin
      if (T_5106 & tl_dat_a_bits_mask[0]) begin
        ctrl_dla_cssck <= tl_dat_a_bits_data[7:0];
      end
    end

  always @(posedge clock or posedge reset)
    if (reset) begin
      ctrl_dla_sckcs <= 8'h1;
    end else begin
      if (T_5106 & tl_dat_a_bits_mask[2]) begin
        ctrl_dla_sckcs <= tl_dat_a_bits_data[23:16];
      end
    end

  always @(posedge clock or posedge reset)
    if (reset) begin
      ctrl_dla_intercs <= 8'h1;
    end else begin
      if (T_5126 & tl_dat_a_bits_mask[0]) begin
        ctrl_dla_intercs <= tl_dat_a_bits_data[7:0];
      end
    end

  always @(posedge clock or posedge reset)
    if (reset) begin
      ctrl_dla_interxfr <= 8'h0;
    end else begin
      if (T_5126 & tl_dat_a_bits_mask[2]) begin
        ctrl_dla_interxfr <= tl_dat_a_bits_data[23:16];
      end
    end

  always @(posedge clock or posedge reset)
    if (reset) begin
      ctrl_wm_tx <= 4'h0;
    end else begin
      if (wr_en & addr_sel_onehot[20] & tl_dat_a_bits_mask[0]) begin
        ctrl_wm_tx <= tl_dat_a_bits_data[3:0];
      end
    end

  always @(posedge clock or posedge reset)
    if (reset) begin
      ctrl_wm_rx <= 4'h0;
    end else begin
      if (wr_en & addr_sel_onehot[21] & tl_dat_a_bits_mask[0]) begin
        ctrl_wm_rx <= tl_dat_a_bits_data[3:0];
      end
    end

  always @(posedge clock or posedge reset)
    if (reset) begin
      ie_txwm <= 1'h0;
      ie_rxwm <= 1'h0;
    end else begin
      if (T_5466 & tl_dat_a_bits_mask[0]) begin
        ie_txwm <= tl_dat_a_bits_data[0];
        ie_rxwm <= tl_dat_a_bits_data[1];
      end
    end

  always @(posedge clock or posedge reset)
    if (reset) begin
      insn_pad_code <= 8'h0;
    end else begin
      if (T_5406 & tl_dat_a_bits_mask[3]) begin
        insn_pad_code <= tl_dat_a_bits_data[31:24];
      end
    end

  always @(posedge clock or posedge reset)
    if (reset) begin
      insn_cmd_code <= 8'h3;
    end else begin
      if (T_5406 & tl_dat_a_bits_mask[2]) begin
        insn_cmd_code <= tl_dat_a_bits_data[23:16];
      end
    end

  always @(posedge clock or posedge reset)
    if (reset) begin
      insn_cmd_proto <= 2'h0;
      insn_addr_proto <= 2'h0;
      insn_data_proto <= 2'h0;
    end else begin
      if (T_5406 & tl_dat_a_bits_mask[1]) begin
        insn_cmd_proto <= tl_dat_a_bits_data[9:8];
        insn_addr_proto <= tl_dat_a_bits_data[11:10];
        insn_data_proto <= tl_dat_a_bits_data[13:12];
      end
    end

  always @(posedge clock or posedge reset)
    if (reset) begin
      insn_cmd_en <= 1'h1;
      insn_addr_len <= 3'h3;
      insn_pad_cnt <= 4'h0;
    end else begin
      if (T_5406 & tl_dat_a_bits_mask[0]) begin
        insn_cmd_en <= tl_dat_a_bits_data[0];
        insn_addr_len <= tl_dat_a_bits_data[3:1];
        insn_pad_cnt <= tl_dat_a_bits_data[7:4];
      end
    end

  always @(posedge clock or posedge reset)
    if (reset) begin
      flash_en <= 1'h1;
    end else begin
      if (wr_en & addr_sel_onehot[24] & tl_dat_a_bits_mask[0]) begin
        flash_en <= tl_dat_a_bits_data[0];
      end
    end

  always @(posedge clock or posedge reset) begin
    if(reset) begin
      a_size <= 3'b0;
      a_source <= 7'b0;
      a_address <= 30'b0;
    end
    else if (tl_ins_a_ready & tl_ins_a_valid) begin
      a_size <= tl_ins_a_bits_size;
      a_source <= tl_ins_a_bits_source;
      a_address <= tl_ins_a_bits_address;
    end
  end

endmodule
