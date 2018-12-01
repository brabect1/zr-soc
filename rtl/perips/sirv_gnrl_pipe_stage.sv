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

module sirv_gnrl_pipe_stage # (
  // When the depth is 1, the ready signal may relevant to next stage's ready, hence become logic
  // chains. Use CUT_READY to control it
  parameter CUT_READY = 0,
  parameter DP = 1,
  parameter DW = 32
) (
  input           i_vld, 
  output          i_rdy, 
  input  [DW-1:0] i_dat,
  output          o_vld, 
  input           o_rdy, 
  output reg [DW-1:0] o_dat,

  input           clk,
  input           rst_n
);

  genvar i;
  generate //{

  if(DP == 0) begin: dp_eq_0//{ pass through

      assign o_vld = i_vld;
      assign i_rdy = o_rdy;
      always @(i_dat)
          o_dat = i_dat;
      //assign o_dat = i_dat;

  end//}
  else begin: dp_gt_0//{

      wire vld_set;
      wire vld_clr;
      wire vld_ena;
      reg vld_r;
      wire vld_nxt;

      // The valid will be set when input handshaked
      assign vld_set = i_vld & i_rdy;
      // The valid will be clr when output handshaked
      assign vld_clr = o_vld & o_rdy;

      assign vld_ena = vld_set | vld_clr;
      assign vld_nxt = vld_set | (~vld_clr);

      //sirv_gnrl_dfflr #(1) vld_dfflr (vld_ena, vld_nxt, vld_r, clk, rst_n);
      always @(posedge clk or negedge rst_n) begin : p_vld_r
        if (!rst_n)
          vld_r <= 1'b0;
        else if (vld_ena)
          vld_r <= vld_nxt;
      end: p_vld_r

      assign o_vld = vld_r;

      //sirv_gnrl_dffl #(DW) dat_dfflr (vld_set, i_dat, o_dat, clk);
      always @(posedge clk) begin : p_o_dat
        if (vld_set)
          o_dat <= i_dat;
      end: p_o_dat

      if(CUT_READY == 1) begin:cut_ready//{
          // If cut ready, then only accept when stage is not full
          assign i_rdy = (~vld_r);
      end//}
      else begin:no_cut_ready//{
          // If not cut ready, then can accept when stage is not full or it is popping 
          assign i_rdy = (~vld_r) | vld_clr;
      end//}
  end//}
  endgenerate//}


endmodule 

