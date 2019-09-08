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
   - Replaced receiver module as the original one did not work with loopback
     to the transmitter module.

 */                                                                      
                                                                         
                                                                         
                                                                         

module sirv_uart(
  input   clock,
  input   reset,
  output  irq,
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
  output  io_port_txd,
  input   io_port_rxd
);
  wire  txm_io_in_ready;
  wire  txq_io_enq_ready;
  wire  txq_io_deq_valid;
  wire [7:0] txq_io_deq_bits;
  wire [3:0] txq_io_count;
  wire  rxm_io_out_valid;
  wire [7:0] rxm_io_out_bits;
  wire  rxq_io_enq_ready;
  wire  rxq_io_deq_valid;
  wire [7:0] rxq_io_deq_bits;
  wire [3:0] rxq_io_count;
  reg [15:0] div;
  reg  txen;
  reg  rxen;
  reg [3:0] txwm;
  reg [3:0] rxwm;
  reg  nstop;
  reg  ie_rxwm;
  reg  ie_txwm;
  wire  irq_txwm;
  wire  irq_rxwm;
  wire  op_rd;
  wire  T_1065;
  wire [2:0] addr_bits;
  wire [7:0] T_2181;
  wire  op_rdy;
  wire  wr_en;
  sirv_uarttx u_txm (
    .clock(clock),
    .reset(reset),
    .io_en(txen),
    .io_in_ready(txm_io_in_ready),
    .io_in_valid(txq_io_deq_valid),
    .io_in_bits(txq_io_deq_bits),
    .io_out(io_port_txd),
    .io_div(div),
    .io_nstop(nstop)
  );
  sirv_queue_1 u_txq (
    .clock(clock),
    .reset(reset),
    .io_enq_ready(txq_io_enq_ready),
    .io_enq_valid(wr_en & T_2181[0] & tl_a_bits_mask[0]),
    .io_enq_bits(tl_a_bits_data[7:0]),
    .io_deq_ready(txm_io_in_ready),
    .io_deq_valid(txq_io_deq_valid),
    .io_deq_bits(txq_io_deq_bits),
    .io_count(txq_io_count)
  );
//  sirv_uartrx u_rxm (
//    .clock(clock),
//    .reset(reset),
//    .io_en(rxen),
//    .io_in(io_port_rxd),
//    .io_out_valid(rxm_io_out_valid),
//    .io_out_bits(rxm_io_out_bits),
//    .io_div(div)
//  );
  uart_rx u_rxm(
    .clock(clock),
    .reset(reset),
    .io_en(rxen),
    .io_in(io_port_rxd),
    .io_out_valid(rxm_io_out_valid),
    .io_out_bits(rxm_io_out_bits),
    .io_div(div),
    .LCR({5'd0,nstop,2'b11}),
    .rx_idle(),
    .parity_error(),
    .framing_error(),
    .break_error()
  );
  sirv_queue_1 u_rxq (
    .clock(clock),
    .reset(reset),
    .io_enq_ready(rxq_io_enq_ready),
    .io_enq_valid(rxm_io_out_valid),
    .io_enq_bits(rxm_io_out_bits),
    .io_deq_ready(op_rdy & op_rd & T_2181[1] & tl_a_bits_mask[0]),
    .io_deq_valid(rxq_io_deq_valid),
    .io_deq_bits(rxq_io_deq_bits),
    .io_count(rxq_io_count)
  );
  assign irq = ((irq_txwm & ie_txwm) | (irq_rxwm & ie_rxwm));
  assign tl_a_ready = tl_d_ready;
  assign tl_d_valid = tl_a_valid;
  assign tl_d_bits_opcode = {{2'd0}, op_rd};
  assign tl_d_bits_param = 2'h0;
  assign tl_d_bits_size = tl_a_bits_size;
  assign tl_d_bits_source = tl_a_bits_source;
  assign tl_d_bits_sink = 1'h0;
  assign tl_d_bits_addr_lo = tl_a_bits_address[1:0];
//  assign tl_d_bits_data = T_1065 ? (3'h7 == addr_bits ? 32'h0 : (3'h6 == addr_bits ? ({16'd0, div}) : (3'h5 == addr_bits ? {30'd0,irq_rxwm,irq_txwm} : (3'h4 == addr_bits ? {30'd0,ie_rxwm,ie_txwm} : (3'h3 == addr_bits ? {16'd0,rxwm,15'd0,rxen} : (3'h2 == addr_bits ? {12'd0,txwm,14'd0,nstop,txen} : (3'h1 == addr_bits ? {~rxq_io_deq_valid,23'd0,rxq_io_deq_bits} : {~txq_io_enq_ready,31'd0} ))))))) : 32'h0;
  assign tl_d_bits_error = 1'h0;
  assign irq_txwm = txq_io_count < txwm;
  assign irq_rxwm = rxq_io_count > rxwm;
  assign op_rd = tl_a_bits_opcode == 3'h4;
  assign T_1065 = tl_a_bits_address[11:5] == 10'h0;
  assign addr_bits = tl_a_bits_address[4:2];
  assign T_2181 = (8'h1 << addr_bits);
  assign op_rdy = tl_a_valid & tl_d_ready;
  assign wr_en = op_rdy & ~op_rd;

  always @(*)
    if (T_1065) begin
      case (addr_bits)
        3'h0: tl_d_bits_data = {~txq_io_enq_ready,31'd0};
        3'h1: tl_d_bits_data = {~rxq_io_deq_valid,23'd0,rxq_io_deq_bits};
        3'h2: tl_d_bits_data = {12'd0,txwm,14'd0,nstop,txen};
        3'h3: tl_d_bits_data = {16'd0,rxwm,15'd0,rxen};
        3'h4: tl_d_bits_data = {30'd0,ie_rxwm,ie_txwm};
        3'h5: tl_d_bits_data = {30'd0,irq_rxwm,irq_txwm};
        3'h6: tl_d_bits_data = {16'd0, div};
        default: tl_d_bits_data = 32'h0;
      endcase
    end
    else begin
      tl_d_bits_data = 32'h0;
    end

  always @(posedge clock or posedge reset)
    if (reset) begin
      div <= 16'h21e;
    end else if (wr_en & T_2181[6] & (tl_a_bits_mask[1:0] == 2'h3)) begin
      div <= tl_a_bits_data[15:0];
    end

  always @(posedge clock or posedge reset)
    if (reset) begin
      txen <= 1'h0;
      nstop <= 1'h0;
      txwm <= 4'h0;
    end else if (wr_en & T_2181[2]) begin
      if (tl_a_bits_mask[0]) begin
        txen <= tl_a_bits_data[0];
        nstop <= tl_a_bits_data[1];
      end
      if (tl_a_bits_mask[2]) begin
        txwm <= tl_a_bits_data[19:16];
      end
    end

  always @(posedge clock or posedge reset)
    if (reset) begin
      rxen <= 1'h0;
      rxwm <= 4'h0;
    end else if (wr_en & T_2181[3]) begin
      if (tl_a_bits_mask[0]) begin
        rxen <= tl_a_bits_data[0];
      end
      if (tl_a_bits_mask[2]) begin
        rxwm <= tl_a_bits_data[19:16];
      end
    end

  always @(posedge clock or posedge reset)
    if (reset) begin
      ie_rxwm <= 1'h0;
      ie_txwm <= 1'h0;
    end else if (wr_en & T_2181[4] & tl_a_bits_mask[0]) begin
      ie_rxwm <= tl_a_bits_data[1];
      ie_txwm <= tl_a_bits_data[0];
    end

endmodule
