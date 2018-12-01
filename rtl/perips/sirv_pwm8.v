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
                                                                         
                                                                         
                                                                         

module sirv_pwm8(
  input   clock,
  input   reset,
  output  [3:0] io_interrupts,
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
  output [3:0] io_gpio
);
  wire [31:0] pwm_io_regs_cfg_read;
  wire [31:0] pwm_io_regs_countLo_read;
  wire [31:0] pwm_io_regs_countHi_read;
  wire [7:0] pwm_io_regs_s_read;
  wire [7:0] pwm_io_regs_cmp_0_read;
  wire [7:0] pwm_io_regs_cmp_1_read;
  wire [7:0] pwm_io_regs_cmp_2_read;
  wire [7:0] pwm_io_regs_cmp_3_read;
  wire [31:0] pwm_io_regs_feed_read;
  wire [31:0] pwm_io_regs_key_read;
  wire  T_929;
  wire [9:0] T_933;
  wire  T_1042;
//  wire  T_1051;
//  wire  T_1060;
//  wire  T_1069;
//  wire  T_1078;
//  wire  T_1087;
//  wire  T_1096;
//  wire  T_1105;
//  wire  T_1114;
//  wire  T_1123;
  wire [31:0] T_1270;
  wire  T_1300;
  wire  T_1340;
//  wire  T_1695;
//  wire  T_1702;
//  wire  T_1706;
//  wire  T_1710;
//  wire  T_1717;
//  wire  T_1721;
//  wire  T_1725;
//  wire  T_1729;
//  wire  T_1733;
//  wire  T_1737;
  wire [3:0] T_2090;
  wire  T_2106;
  wire  T_2109;
  wire  T_2111;
  wire [15:0] T_2131;
  wire  T_2167;
  reg [31:0] GEN_103;
  reg [31:0] GEN_104;
  reg [31:0] GEN_105;
  reg [31:0] GEN_106;
  reg [31:0] GEN_107;
  reg [31:0] GEN_108;
  reg [31:0] GEN_109;
  sirv_pwm8_core pwm (
    .clock(clock),
    .reset(reset),
    .io_regs_cfg_write_valid(((T_2167 & T_2131[0]) & T_1300)),
    .io_regs_cfg_write_bits(tl_a_bits_data),
    .io_regs_cfg_read(pwm_io_regs_cfg_read),
    .io_regs_countLo_write_valid(((T_2167 & T_2131[2]) & T_1300)),
    .io_regs_countLo_write_bits(tl_a_bits_data),
    .io_regs_countLo_read(pwm_io_regs_countLo_read),
    .io_regs_countHi_write_valid(((T_2167 & T_2131[3]) & T_1300)),
    .io_regs_countHi_write_bits(tl_a_bits_data),
    .io_regs_countHi_read(pwm_io_regs_countHi_read),
    .io_regs_s_write_valid(((T_2167 & T_2131[4]) & T_1340)),
    .io_regs_s_write_bits(tl_a_bits_data[7:0]),
    .io_regs_s_read(pwm_io_regs_s_read),
    .io_regs_cmp_0_write_valid(((T_2167 & T_2131[8]) & T_1340)),
    .io_regs_cmp_0_write_bits(tl_a_bits_data[7:0]),
    .io_regs_cmp_0_read(pwm_io_regs_cmp_0_read),
    .io_regs_cmp_1_write_valid(((T_2167 & T_2131[9]) & T_1340)),
    .io_regs_cmp_1_write_bits(tl_a_bits_data[7:0]),
    .io_regs_cmp_1_read(pwm_io_regs_cmp_1_read),
    .io_regs_cmp_2_write_valid(((T_2167 & T_2131[10]) & T_1340)),
    .io_regs_cmp_2_write_bits(tl_a_bits_data[7:0]),
    .io_regs_cmp_2_read(pwm_io_regs_cmp_2_read),
    .io_regs_cmp_3_write_valid(((T_2167 & T_2131[11]) & T_1340)),
    .io_regs_cmp_3_write_bits(tl_a_bits_data[7:0]),
    .io_regs_cmp_3_read(pwm_io_regs_cmp_3_read),
    .io_regs_feed_write_valid(((T_2167 & T_2131[6]) & T_1300)),
    .io_regs_feed_write_bits(tl_a_bits_data),
    .io_regs_feed_read(pwm_io_regs_feed_read),
    .io_regs_key_write_valid(((T_2167 & T_2131[7]) & T_1300)),
    .io_regs_key_write_bits(tl_a_bits_data),
    .io_regs_key_read(pwm_io_regs_key_read),
    .io_ip(io_interrupts),
    .io_gpio(io_gpio)
  );
  assign tl_a_ready = ((tl_d_ready & T_2109) & T_2106);
  assign tl_d_valid = (T_2111 & T_2109);
  assign tl_d_bits_opcode = {{2'd0}, T_929};
  assign tl_d_bits_param = 2'h0;
  assign tl_d_bits_size = T_933[2:0];
  assign tl_d_bits_source = T_933[7:3];
  assign tl_d_bits_sink = 1'h0;
  assign tl_d_bits_addr_lo = T_933[9:8];
  assign tl_d_bits_data = 4'hb == T_2090 ? {24'd0,pwm_io_regs_cmp_3_read} : (4'ha == T_2090 ? {24'd0,pwm_io_regs_cmp_2_read} : (4'h9 == T_2090 ? {24'd0,pwm_io_regs_cmp_1_read} : (4'h8 == T_2090 ? {24'd0,pwm_io_regs_cmp_0_read} : (4'h7 == T_2090 ? pwm_io_regs_key_read : (4'h6 == T_2090 ? pwm_io_regs_feed_read : (4'h4 == T_2090 ? {24'd0, pwm_io_regs_s_read} : (4'h3 == T_2090 ? pwm_io_regs_countHi_read : (4'h2 == T_2090 ? pwm_io_regs_countLo_read : (4'h0 == T_2090 ? pwm_io_regs_cfg_read : 32'h0)))))))));
//  assign tl_d_bits_data = ((4'hf == T_2090 ? 1'h1 : (4'he == T_2090 ? 1'h1 : (4'hd == T_2090 ? 1'h1 : (4'hc == T_2090 ? 1'h1 : (4'hb == T_2090 ? T_1105 : (4'ha == T_2090 ? T_1051 : (4'h9 == T_2090 ? T_1069 : (4'h8 == T_2090 ? T_1114 : (4'h7 == T_2090 ? T_1087 : (4'h6 == T_2090 ? T_1060 : (4'h5 == T_2090 ? 1'h1 : (4'h4 == T_2090 ? T_1123 : (4'h3 == T_2090 ? T_1096 : (4'h2 == T_2090 ? T_1078 : (4'h1 == T_2090 ? 1'h1 : T_1042))))))))))))))) ? (4'hf == T_2090 ? 32'h0 : (4'he == T_2090 ? 32'h0 : (4'hd == T_2090 ? 32'h0 : (4'hc == T_2090 ? 32'h0 : (4'hb == T_2090 ? ({{24'd0}, pwm_io_regs_cmp_3_read}) : (4'ha == T_2090 ? ({{24'd0}, pwm_io_regs_cmp_2_read}) : (4'h9 == T_2090 ? ({{24'd0}, pwm_io_regs_cmp_1_read}) : (4'h8 == T_2090 ? ({{24'd0}, pwm_io_regs_cmp_0_read}) : (4'h7 == T_2090 ? pwm_io_regs_key_read : (4'h6 == T_2090 ? pwm_io_regs_feed_read : (4'h5 == T_2090 ? 32'h0 : (4'h4 == T_2090 ? ({{24'd0}, pwm_io_regs_s_read}) : (4'h3 == T_2090 ? pwm_io_regs_countHi_read : (4'h2 == T_2090 ? pwm_io_regs_countLo_read : (4'h1 == T_2090 ? 32'h0 : pwm_io_regs_cfg_read))))))))))))))) : 32'h0);
  assign tl_d_bits_error = 1'h0;
  assign T_929 = tl_a_bits_opcode == 3'h4;
  assign T_933 = {({tl_a_bits_address[1:0],tl_a_bits_source}),tl_a_bits_size};
  assign T_1042 = tl_a_bits_address[11:6] == 6'h0;
//  assign T_1042 = (tl_a_bits_address[11:2] & 10'h3f0) == 10'h0;
//  assign T_1051 = ((tl_a_bits_address[11:2] ^ 10'ha) & 10'h3f0) == 10'h0;
//  assign T_1060 = ((tl_a_bits_address[11:2] ^ 10'h6) & 10'h3f0) == 10'h0;
//  assign T_1069 = ((tl_a_bits_address[11:2] ^ 10'h9) & 10'h3f0) == 10'h0;
//  assign T_1078 = ((tl_a_bits_address[11:2] ^ 10'h2) & 10'h3f0) == 10'h0;
//  assign T_1087 = ((tl_a_bits_address[11:2] ^ 10'h7) & 10'h3f0) == 10'h0;
//  assign T_1096 = ((tl_a_bits_address[11:2] ^ 10'h3) & 10'h3f0) == 10'h0;
//  assign T_1105 = ((tl_a_bits_address[11:2] ^ 10'hb) & 10'h3f0) == 10'h0;
//  assign T_1114 = ((tl_a_bits_address[11:2] ^ 10'h8) & 10'h3f0) == 10'h0;
//  assign T_1123 = ((tl_a_bits_address[11:2] ^ 10'h4) & 10'h3f0) == 10'h0;
  assign T_1270 = { {8{tl_a_bits_mask[3]}}, {8{tl_a_bits_mask[2]}}, {8{tl_a_bits_mask[1]}}, {8{tl_a_bits_mask[0]}} };
  assign T_1300 = &T_1270;
  assign T_1340 = &T_1270[7:0];
//  assign T_1695 = T_1042 == 1'h0;
//  assign T_1702 = T_1078 == 1'h0;
//  assign T_1706 = T_1096 == 1'h0;
//  assign T_1710 = T_1123 == 1'h0;
//  assign T_1717 = T_1060 == 1'h0;
//  assign T_1721 = T_1087 == 1'h0;
//  assign T_1725 = T_1114 == 1'h0;
//  assign T_1729 = T_1069 == 1'h0;
//  assign T_1733 = T_1051 == 1'h0;
//  assign T_1737 = T_1105 == 1'h0;
  assign T_2090 = tl_a_bits_address[5:2];
  assign T_2106 = 1'b1;
//  assign T_2106 = T_929 ? (4'hf == T_2090 ? 1'h1 : (4'he == T_2090 ? 1'h1 : (4'hd == T_2090 ? 1'h1 : (4'hc == T_2090 ? 1'h1 : (4'hb == T_2090 ? (T_1737 | 1'h1) : (4'ha == T_2090 ? (T_1733 | 1'h1) : (4'h9 == T_2090 ? (T_1729 | 1'h1) : (4'h8 == T_2090 ? (T_1725 | 1'h1) : (4'h7 == T_2090 ? (T_1721 | 1'h1) : (4'h6 == T_2090 ? (T_1717 | 1'h1) : (4'h5 == T_2090 ? 1'h1 : (4'h4 == T_2090 ? (T_1710 | 1'h1) : (4'h3 == T_2090 ? (T_1706 | 1'h1) : (4'h2 == T_2090 ? (T_1702 | 1'h1) : (4'h1 == T_2090 ? 1'h1 : (T_1695 | 1'h1)))))))))))))))) : (4'hf == T_2090 ? 1'h1 : (4'he == T_2090 ? 1'h1 : (4'hd == T_2090 ? 1'h1 : (4'hc == T_2090 ? 1'h1 : (4'hb == T_2090 ? (T_1737 | 1'h1) : (4'ha == T_2090 ? (T_1733 | 1'h1) : (4'h9 == T_2090 ? (T_1729 | 1'h1) : (4'h8 == T_2090 ? (T_1725 | 1'h1) : (4'h7 == T_2090 ? (T_1721 | 1'h1) : (4'h6 == T_2090 ? (T_1717 | 1'h1) : (4'h5 == T_2090 ? 1'h1 : (4'h4 == T_2090 ? (T_1710 | 1'h1) : (4'h3 == T_2090 ? (T_1706 | 1'h1) : (4'h2 == T_2090 ? (T_1702 | 1'h1) : (4'h1 == T_2090 ? 1'h1 : (T_1695 | 1'h1))))))))))))))));
  assign T_2109 = 1'b1;
//  assign T_2109 = T_929 ? (4'hf == T_2090 ? 1'h1 : (4'he == T_2090 ? 1'h1 : (4'hd == T_2090 ? 1'h1 : (4'hc == T_2090 ? 1'h1 : (4'hb == T_2090 ? (T_1737 | 1'h1) : (4'ha == T_2090 ? (T_1733 | 1'h1) : (4'h9 == T_2090 ? (T_1729 | 1'h1) : (4'h8 == T_2090 ? (T_1725 | 1'h1) : (4'h7 == T_2090 ? (T_1721 | 1'h1) : (4'h6 == T_2090 ? (T_1717 | 1'h1) : (4'h5 == T_2090 ? 1'h1 : (4'h4 == T_2090 ? (T_1710 | 1'h1) : (4'h3 == T_2090 ? (T_1706 | 1'h1) : (4'h2 == T_2090 ? (T_1702 | 1'h1) : (4'h1 == T_2090 ? 1'h1 : (T_1695 | 1'h1)))))))))))))))) : (4'hf == T_2090 ? 1'h1 : (4'he == T_2090 ? 1'h1 : (4'hd == T_2090 ? 1'h1 : (4'hc == T_2090 ? 1'h1 : (4'hb == T_2090 ? (T_1737 | 1'h1) : (4'ha == T_2090 ? (T_1733 | 1'h1) : (4'h9 == T_2090 ? (T_1729 | 1'h1) : (4'h8 == T_2090 ? (T_1725 | 1'h1) : (4'h7 == T_2090 ? (T_1721 | 1'h1) : (4'h6 == T_2090 ? (T_1717 | 1'h1) : (4'h5 == T_2090 ? 1'h1 : (4'h4 == T_2090 ? (T_1710 | 1'h1) : (4'h3 == T_2090 ? (T_1706 | 1'h1) : (4'h2 == T_2090 ? (T_1702 | 1'h1) : (4'h1 == T_2090 ? 1'h1 : (T_1695 | 1'h1))))))))))))))));
  assign T_2111 = tl_a_valid & T_2106;
  assign T_2131 = (16'h1 << T_2090);
//  assign T_2131 = (16'h1 << T_2090) & ({({4'hf,({({T_1105,T_1051}),({T_1069,T_1114})})}),({({({T_1087,T_1060}),({1'h1,T_1123})}),({({T_1096,T_1078}),({1'h1,T_1042})})})});
  assign T_2167 = (T_2111 & tl_d_ready) & (T_929 == 1'h0);
endmodule
