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

// The general sync FIFO module.
//
// This FIFO implementation supports arbitrary depth, but for a large depth or
// a depth of a power of two would yield a less optimal implementation.
module sirv_gnrl_fifo # (
  // When the depth is 1, the ready signal may relevant to next stage's ready, hence become logic
  // chains. Use CUT_READY to control it
  // When fifo depth is 1, the fifo is a signle stage
       // if CUT_READY is set, then the back-pressure ready signal will be cut
       //      off, and it can only pass 1 data every 2 cycles
  // When fifo depth is > 1, then it is actually a really fifo
       //      The CUT_READY parameter have no impact to any logics
  parameter CUT_READY = 0,
  parameter MSKO = 0,// Mask out the data with valid or not
  parameter DP   = 8,// FIFO depth
  parameter DW   = 32// FIFO width
) (

  input           i_vld, 
  output          i_rdy, 
  input  [DW-1:0] i_dat,
  output          o_vld, 
  input           o_rdy, 
  output [DW-1:0] o_dat,

  input           clk,
  input           rst_n
);

genvar i;
generate

  if(DP == 0) begin: dp_eq1// pass through when it is 0 entries

     assign o_vld = i_vld;
     assign i_rdy = o_rdy;
     assign o_dat = i_dat;

  end
  else begin: dp_gt0

    // FIFO registers
//    wire [DW-1:0] fifo_rf_r [DP-1:0];
    reg [DW-1:0] fifo_rf_r [DP-1:0];
    wire [DP-1:0] fifo_rf_en;

    // read/write enable
    wire wen = i_vld & i_rdy;
    wire ren = o_vld & o_rdy;
    
    // Read-Pointer and Write-Pointer
    // (Both pointers are implemented as circular shift registers with one hot
    // encoding. The hot one moves on each read in the read pointer and on each
    // write in the write pointer.)
    wire [DP-1:0] rptr_vec_nxt; 
    reg [DP-1:0] rptr_vec_r;
    wire [DP-1:0] wptr_vec_nxt; 
    reg [DP-1:0] wptr_vec_r;

    if(DP == 1) begin:rptr_dp_1
      assign rptr_vec_nxt = 1'b1; 
    end
    else begin:rptr_dp_not_1
      assign rptr_vec_nxt = 
          rptr_vec_r[DP-1] ? {{DP-1{1'b0}}, 1'b1} :
                          (rptr_vec_r << 1);
    end

    if(DP == 1) begin:wptr_dp_1
      assign wptr_vec_nxt = 1'b1; 
    end
    else begin:wptr_dp_not_1
      assign wptr_vec_nxt =
          wptr_vec_r[DP-1] ? {{DP-1{1'b0}}, 1'b1} :
                          (wptr_vec_r << 1);
    end

    //sirv_gnrl_dfflrs #(1)    rptr_vec_0_dfflrs  (ren, rptr_vec_nxt[0]     , rptr_vec_r[0]     , clk, rst_n);
    always @(posedge clk or negedge rst_n) begin: p_rptr_vec
      if (!rst_n)
        rptr_vec_r[0] <= 1'b1;
      else if (ren)
        rptr_vec_r[0] <= rptr_vec_nxt[0];
    end: p_rptr_vec
    //sirv_gnrl_dfflrs #(1)    wptr_vec_0_dfflrs  (wen, wptr_vec_nxt[0]     , wptr_vec_r[0]     , clk, rst_n);
    always @(posedge clk or negedge rst_n) begin: p_wptr_vec
      if (!rst_n)
        wptr_vec_r[0] <= 1'b1;
      else if (wen)
        wptr_vec_r[0] <= wptr_vec_nxt[0];
    end: p_wptr_vec
    if(DP > 1) begin:dp_gt1
      //sirv_gnrl_dfflr  #(DP-1) rptr_vec_31_dfflr  (ren, rptr_vec_nxt[DP-1:1], rptr_vec_r[DP-1:1], clk, rst_n);
      always @(posedge clk or negedge rst_n) begin: p_rptr_vec_other
        if (!rst_n)
          rptr_vec_r[DP-1:1] <= {DP-1{1'b0}};
        else if (ren)
          rptr_vec_r[DP-1:1] <= rptr_vec_nxt[DP-1:1];
      end: p_rptr_vec_other
      //sirv_gnrl_dfflr  #(DP-1) wptr_vec_31_dfflr  (wen, wptr_vec_nxt[DP-1:1], wptr_vec_r[DP-1:1], clk, rst_n);
      always @(posedge clk or negedge rst_n) begin: p_wptr_vec_other
        if (!rst_n)
          wptr_vec_r[DP-1:1] <= {DP-1{1'b0}};
        else if (wen)
          wptr_vec_r[DP-1:1] <= wptr_vec_nxt[DP-1:1];
      end: p_wptr_vec_other
    end

    // Vec register to easy full and empty and the o_vld generation with flop-clean
    // (`vec_r` maintains the fullness of the FIFO. For each enqueu, the register shifts
    // in a one, and for each dequeue it shofts out a one.
    // The MSB then acts as a FIFO full flag. And the 2nd LSB, `vec_r[0]`, acts as
    // a "not empty" flag.)
    // Note: Implementation wide, the same information (full/empty) could be easily
    // derived from the equivalence of the write and read pointers and the last operation.
    // Such an implementation would take less flops to implement.
    wire [DP:0] vec_nxt; 
    reg [DP:0] vec_r;

    wire vec_en = (ren ^ wen );
    assign vec_nxt = wen ? {vec_r[DP-1:0], 1'b1} : (vec_r >> 1);  
    
    //sirv_gnrl_dfflrs #(1)  vec_0_dfflrs     (vec_en, vec_nxt[0]     , vec_r[0]     ,     clk, rst_n);
    //sirv_gnrl_dfflr  #(DP) vec_31_dfflr     (vec_en, vec_nxt[DP:1], vec_r[DP:1],     clk, rst_n);
    always @(posedge clk or negedge rst_n) begin: p_vec
        if (!rst_n) begin
            vec_r[0] <= 1'b1;
            vec_r[DP:1] <= {DP{1'b0}};
        end
        else if (vec_en) begin
            vec_r <= vec_nxt;
        end
    end: p_vec

    if(DP == 1) begin:cut_dp_eq1
        if(CUT_READY == 1) begin:cut_ready
          // If cut ready, then only accept when fifo is not full
          assign i_rdy = (~vec_r[DP]);
        end
        else begin:no_cut_ready
          // If not cut ready, then can accept when fifo is not full or it is popping 
          assign i_rdy = (~vec_r[DP]) | ren;
        end
    end
    else begin : no_cut_dp_gt1
      assign i_rdy = (~vec_r[DP]);
    end


    // FIFO registers
    for (i=0; i<DP; i=i+1) begin:fifo_rf
      //sirv_gnrl_dffl  #(DW) fifo_rf_dffl (fifo_rf_en[i], i_dat, fifo_rf_r[i], clk);
      always @(posedge clk) begin: p_fifo_rf
        if (wen & wptr_vec_r[i])
          fifo_rf_r[i] <= i_dat;
      end: p_fifo_rf
    end

    // One-Hot Mux as the read path
    integer j;
    reg [DW-1:0] mux_rdat;
    always @*
    begin : rd_port_PROC
      mux_rdat = {DW{1'b0}};
      for(j=0; j<DP; j=j+1) begin
        mux_rdat = mux_rdat | ({DW{rptr_vec_r[j]}} & fifo_rf_r[j]);
      end
    end
    
    if(MSKO == 1) begin:mask_output
        // Mask the data with valid since the FIFO register is not reset and as X 
        assign o_dat = {DW{o_vld}} & mux_rdat;
    end
    else begin:no_mask_output
        // Not Mask the data with valid since no care with X for datapth
        assign o_dat = mux_rdat;
    end
    
    // o_vld as flop-clean
    assign o_vld = (vec_r[1]);
    
  end
endgenerate

endmodule 
