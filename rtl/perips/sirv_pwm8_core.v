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
                                                                         
                                                                         
                                                                         

module sirv_pwm8_core(
  input   clock,
  input   reset,
  input   io_regs_cfg_write_valid,
  input  [31:0] io_regs_cfg_write_bits,
  output [31:0] io_regs_cfg_read,
  input   io_regs_countLo_write_valid,
  input  [31:0] io_regs_countLo_write_bits,
  output [31:0] io_regs_countLo_read,
  input   io_regs_countHi_write_valid,
  input  [31:0] io_regs_countHi_write_bits,
  output [31:0] io_regs_countHi_read,
  input   io_regs_s_write_valid,
  input  [7:0] io_regs_s_write_bits,
  output [7:0] io_regs_s_read,
  input   io_regs_cmp_0_write_valid,
  input  [7:0] io_regs_cmp_0_write_bits,
  output [7:0] io_regs_cmp_0_read,
  input   io_regs_cmp_1_write_valid,
  input  [7:0] io_regs_cmp_1_write_bits,
  output [7:0] io_regs_cmp_1_read,
  input   io_regs_cmp_2_write_valid,
  input  [7:0] io_regs_cmp_2_write_bits,
  output [7:0] io_regs_cmp_2_read,
  input   io_regs_cmp_3_write_valid,
  input  [7:0] io_regs_cmp_3_write_bits,
  output [7:0] io_regs_cmp_3_read,
  input   io_regs_feed_write_valid,
  input  [31:0] io_regs_feed_write_bits,
  output [31:0] io_regs_feed_read,
  input   io_regs_key_write_valid,
  input  [31:0] io_regs_key_write_bits,
  output [31:0] io_regs_key_read,
  output  [3:0] io_ip,
  output  [3:0] io_gpio
);
  reg [3:0] scale;
  reg [7:0] cmp_0;
  reg [7:0] cmp_1;
  reg [7:0] cmp_2;
  reg [7:0] cmp_3;
//  reg [4:0] T_196;
//  wire [5:0] T_197;
//  reg [17:0] T_199;
//  wire [18:0] T_202;
  localparam PWMCOUNT_WIDTH = PWMS_WIDTH+15;
  reg [PWMCOUNT_WIDTH-1:0] pwmcount;
  wire [PWMCOUNT_WIDTH:0] pwmcount_inc;
//  wire [32:0] T_207;
  localparam PWMS_WIDTH = 8;
  wire [PWMS_WIDTH-1:0] pwms;
  reg [3:0] center;
  wire [3:0] elapsed;
  wire [3:0] pwms_center;
//  wire [7:0] T_217;
//  wire  elapsed_0;
  reg  zerocmp;
  wire  countReset;
  reg  deglitch;
  reg  sticky;
  reg  ip_clr;
  reg [3:0] ip;
  reg [3:0] gang;
  reg  oneShot;
  reg  countAlways;
//  wire [3:0] T_361;
  assign io_regs_cfg_read = {ip,gang,4'h0,center,2'h0,oneShot,countAlways,1'h0,deglitch,zerocmp,sticky,4'h0,scale};
  assign io_regs_countLo_read = {9'd0, pwmcount};
  assign io_regs_countHi_read = 32'h0;
  assign io_regs_s_read = pwms;
  assign io_regs_cmp_0_read = cmp_0;
  assign io_regs_cmp_1_read = cmp_1;
  assign io_regs_cmp_2_read = cmp_2;
  assign io_regs_cmp_3_read = cmp_3;
  assign io_regs_feed_read = 32'h0;
  assign io_regs_key_read = 32'h1;
  assign io_ip = ip;
//  assign io_gpio_0 = T_361[0];
//  assign io_gpio_1 = T_361[1];
//  assign io_gpio_2 = T_361[2];
//  assign io_gpio_3 = T_361[3];
//  assign T_197 = T_196 + {4'd0, (countAlways | oneShot)};
//  assign T_202 = T_199 + 18'h1;
//  assign pwmcount = {T_199,T_196};
  assign pwmcount_inc = pwmcount + {{PWMCOUNT_WIDTH-1{1'b0}},(countAlways | oneShot)};
//  assign T_207 = {1'h0,io_regs_countLo_write_bits};
  assign pwms = pwmcount >> scale;
  assign pwms_center[0] = pwms[PWMS_WIDTH-1] & center[0];
  assign pwms_center[1] = pwms[PWMS_WIDTH-1] & center[1];
  assign pwms_center[2] = pwms[PWMS_WIDTH-1] & center[2];
  assign pwms_center[3] = pwms[PWMS_WIDTH-1] & center[3];
//  assign T_217 = ~ T_209[7:0];
  assign elapsed[0] = ({PWMS_WIDTH{pwms_center[0]}} ^ pwms) >= cmp_0;
  assign elapsed[1] = ({PWMS_WIDTH{pwms_center[1]}} ^ pwms) >= cmp_1;
  assign elapsed[2] = ({PWMS_WIDTH{pwms_center[2]}} ^ pwms) >= cmp_2;
  assign elapsed[3] = ({PWMS_WIDTH{pwms_center[3]}} ^ pwms) >= cmp_3;
  // Carry out bit from the "scale window" part of the 
//  wire scale_co = ({(T_197[5] ? ({1'd0,T_199[17:1]} ^ T_202[18:1]) : 18'h0), (({1'd0,T_196[4:1]}) ^ T_197[5:1])} >> {~scale[3],scale[2:0]}/*(scale + 4'h8)[3:0]*/);
  wire scale_co = ({1'd0,pwmcount[PWMCOUNT_WIDTH-1:8]} ^ pwmcount_inc[PWMCOUNT_WIDTH:8]) >> scale;
  assign countReset = scale_co | (zerocmp & elapsed[0]);
  assign io_gpio = ip & ~(gang & {ip[0],ip[3:1]});
  
  always @(posedge clock or posedge reset)
  if(reset) begin
      scale <= 4'b0;
      cmp_0 <= 8'b0;
      cmp_1 <= 8'b0;
      cmp_2 <= 8'b0;
      cmp_3 <= 8'b0;
//      T_196 <= 5'b0;
//      T_199 <= 18'b0;
      pwmcount <= {PWMCOUNT_WIDTH{1'b0}};
      center <= 4'b0;
      zerocmp <= 1'b0;
      deglitch <= 1'b0;
      sticky <= 1'b0;
      ip_clr <= 1'b0;
      ip <= 4'b0;
      gang <= 4'b0;
  end
  else begin
    if (io_regs_cfg_write_valid) begin
      scale <= io_regs_cfg_write_bits[3:0];
    end
    if (io_regs_cmp_0_write_valid) begin
      cmp_0 <= io_regs_cmp_0_write_bits;
    end
    if (io_regs_cmp_1_write_valid) begin
      cmp_1 <= io_regs_cmp_1_write_bits;
    end
    if (io_regs_cmp_2_write_valid) begin
      cmp_2 <= io_regs_cmp_2_write_bits;
    end
    if (io_regs_cmp_3_write_valid) begin
      cmp_3 <= io_regs_cmp_3_write_bits;
    end
//    T_196 <= (countReset ?  5'h0 : (io_regs_countLo_write_valid ? T_207[4:0] : T_197[4:0]));
//    T_199 <= (countReset ? 18'h0 : (io_regs_countLo_write_valid ? T_207[23:5] : (T_197[5] ? T_202[17:0] : T_199)));
    pwmcount <= (countReset ?  {PWMCOUNT_WIDTH{1'b0}} : (io_regs_countLo_write_valid ? io_regs_countLo_write_bits[PWMCOUNT_WIDTH-1:0] : pwmcount_inc[PWMCOUNT_WIDTH-1:0]));
    if (io_regs_cfg_write_valid) begin
      center <= io_regs_cfg_write_bits[19:16];
    end
    if (io_regs_cfg_write_valid) begin
      zerocmp <= io_regs_cfg_write_bits[9];
    end
    if (io_regs_cfg_write_valid) begin
      deglitch <= io_regs_cfg_write_bits[10];
    end
    if (io_regs_cfg_write_valid) begin
      sticky <= io_regs_cfg_write_bits[8];
    end
    ip_clr <= ((deglitch & ~countReset) | sticky);
    if (io_regs_cfg_write_valid) begin
      ip <= io_regs_cfg_write_bits[31:28];
    end else begin
//      ip <= (
//          ( {({3{T_209[7]}} & center[3:1]),T_216} &  {(T_217 >= cmp_3),(T_217 >= cmp_2),(T_217 >= cmp_1),elapsed[0]}) |
//          (~{({3{T_209[7]}} & center[3:1]),T_216} & ({(T_209[7:0] >= cmp_3),(T_209[7:0] >= cmp_2),(T_209[7:0] >= cmp_1),elapsed[0]} | ({4{ip_clr}} & ip)))
//      );
      ip <= elapsed | ({4{ip_clr}} & ip);
    end
    if (io_regs_cfg_write_valid) begin
      gang <= io_regs_cfg_write_bits[27:24];
    end
  end

  always @(posedge clock or posedge reset)
    if (reset) begin
      oneShot <= 1'h0;
    end else begin
      if ((io_regs_cfg_write_valid | countReset)) begin
        oneShot <= (io_regs_cfg_write_bits[13] & ~countReset);
      end
    end

  always @(posedge clock or posedge reset)
    if (reset) begin
      countAlways <= 1'h0;
    end else begin
      if (io_regs_cfg_write_valid) begin
        countAlways <= io_regs_cfg_write_bits[12];
      end
    end

endmodule
