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

Changelog:

  2018, Aug, Tomas Brabec
  - Modified the testbench to work with Verilator (i.e. used only synthesis
    like syntax. This also included using the same clock for `hfextclk` and
    `lfextclk`.
  - Commented out error injection.
  - Simple SPI flash model along with option (`BOOTROM=1`) to execute code from
    there. As RAM and Flash have base addresses different in the most significant
    byte, that byte is ignored in PC (program counter) for detecting an ISA test
    binary reaching certain point in the test program.

*/

module tb_verilator(

  input wire  clk,
  input wire  rst_n
);

`define CPU_TOP u_cpu.u_core
`define EXU `CPU_TOP.u_e203_cpu.u_e203_core.u_e203_exu
`define ITCM u_cpu.u_tcm_ram

`define PC_WRITE_TOHOST       32'h0000010e
`define PC_EXT_IRQ_BEFOR_MRET 32'h000000a6
`define PC_SFT_IRQ_BEFOR_MRET 32'h000000be
`define PC_TMR_IRQ_BEFOR_MRET 32'h000000d6
`define PC_AFTER_SETMTVEC     32'h0000015C

wire [31:0] x3 = `CPU_TOP.id_stage_i.registers_i.rf_reg[3];
wire [31:0] pc = `CPU_TOP.pc_id;
wire [31:0] pc_vld = `CPU_TOP.instr_valid_id;

reg [31:0] pc_write_to_host_cnt;
reg [31:0] pc_write_to_host_cycle;
reg [31:0] valid_ir_cycle;
reg [31:0] cycle_count;
reg pc_write_to_host_flag;

always @(posedge clk or negedge rst_n)
begin 
  if(rst_n == 1'b0) begin
      pc_write_to_host_cnt <= 32'b0;
      pc_write_to_host_flag <= 1'b0;
      pc_write_to_host_cycle <= 32'b0;
  end
  else if (pc_vld & (pc[27:0] == `PC_WRITE_TOHOST)) begin
      pc_write_to_host_cnt <= pc_write_to_host_cnt + 1'b1;
      pc_write_to_host_flag <= 1'b1;
      if (pc_write_to_host_flag == 1'b0) begin
          pc_write_to_host_cycle <= cycle_count;
      end
  end
end

always @(posedge clk or negedge rst_n)
begin 
  if(rst_n == 1'b0) begin
      cycle_count <= 32'b0;
  end
  else begin
      cycle_count <= cycle_count + 1'b1;
  end
end

//wire i_valid = `EXU.i_valid;
//wire i_ready = `EXU.i_ready;
//
//always @(posedge clk or negedge rst_n)
//begin 
//  if(rst_n == 1'b0) begin
//      valid_ir_cycle <= 32'b0;
//  end
//  else if(i_valid & i_ready & (pc_write_to_host_flag == 1'b0)) begin
//      valid_ir_cycle <= valid_ir_cycle + 1'b1;
//  end
//end


string testcase;

integer bootrom_n;

always  @(pc_write_to_host_cnt) begin
    if (pc_write_to_host_cnt == 32'd8) begin

      $display("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
      $display("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
      $display("~~~~~~~~~~~~~ Test Result Summary ~~~~~~~~~~~~~~~~~~~~~~");
      $display("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
      $display("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
      $display("~TESTCASE: %s ~~~~~~~~~~~~~", testcase);
      $display("~BOOT: %0s ~~~~~~~~~~~~~", bootrom_n ? "Flash" : "RAM" );
      $display("~~~~~~~~~~~~~~Total cycle_count value: %d ~~~~~~~~~~~~~", cycle_count);
      $display("~~~~~~~~~~The valid Instruction Count: %d ~~~~~~~~~~~~~", valid_ir_cycle);
      $display("~~~~~The test ending reached at cycle: %d ~~~~~~~~~~~~~", pc_write_to_host_cycle);
      $display("~~~~~~~~~~~~~~~The final x3 Reg value: %d ~~~~~~~~~~~~~", x3);
      $display("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
  if (x3 == 1) begin
      $display("~~~~~~~~~~~~~~~~ TEST_PASS ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
      $display("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
      $display("~~~~~~~~~ #####     ##     ####    #### ~~~~~~~~~~~~~~~~");
      $display("~~~~~~~~~ #    #   #  #   #       #     ~~~~~~~~~~~~~~~~");
      $display("~~~~~~~~~ #    #  #    #   ####    #### ~~~~~~~~~~~~~~~~");
      $display("~~~~~~~~~ #####   ######       #       #~~~~~~~~~~~~~~~~");
      $display("~~~~~~~~~ #       #    #  #    #  #    #~~~~~~~~~~~~~~~~");
      $display("~~~~~~~~~ #       #    #   ####    #### ~~~~~~~~~~~~~~~~");
      $display("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
  end
  else begin
      $display("~~~~~~~~~~~~~~~~ TEST_FAIL ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
      $display("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
      $display("~~~~~~~~~~######    ##       #    #     ~~~~~~~~~~~~~~~~");
      $display("~~~~~~~~~~#        #  #      #    #     ~~~~~~~~~~~~~~~~");
      $display("~~~~~~~~~~#####   #    #     #    #     ~~~~~~~~~~~~~~~~");
      $display("~~~~~~~~~~#       ######     #    #     ~~~~~~~~~~~~~~~~");
      $display("~~~~~~~~~~#       #    #     #    #     ~~~~~~~~~~~~~~~~");
      $display("~~~~~~~~~~#       #    #     #    ######~~~~~~~~~~~~~~~~");
      $display("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
  end
  $finish;
  end
end

// watchdog
always @(posedge clk) begin
  if (cycle_count[20] == 1'b1) begin
    $error("Time Out !!!");
    $finish;
  end
end


logic [7:0] itcm_mem [0:2**14-1];

initial begin
  $display("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");  
  if($value$plusargs("TESTCASE=%s",testcase))begin
    $display("TESTCASE=%s",testcase);
  end
  else begin
      $fatal(1,"No TESTCASE defined!");
      $finish;
  end

  if(!$value$plusargs("BOOTROM=%d",bootrom_n))
    bootrom_n = 0;
  $display("BOOTROM=%b", bootrom_n != 0);

  if (bootrom_n != 0) begin
//    u_spi_dev.load_file({testcase,".verilog"});
  end
  else begin
//    u_spi_dev.mem_set(0,8'haa);
//    u_spi_dev.mem_set(1,8'h55);
//    u_spi_dev.mem_set(2,8'h81);
//    u_spi_dev.mem_set(3,8'h0f);

      $readmemh({testcase, ".verilog"}, itcm_mem);

      for (int i=0;i < $size(itcm_mem)/4;i=i+1) begin
          `ITCM.mem[i][00+7:00] = itcm_mem[i*4+0];
          `ITCM.mem[i][08+7:08] = itcm_mem[i*4+1];
          `ITCM.mem[i][16+7:16] = itcm_mem[i*4+2];
          `ITCM.mem[i][24+7:24] = itcm_mem[i*4+3];
      end

        $display("ITCM 0x00: %h", `ITCM.mem[8'h00]);
        $display("ITCM 0x01: %h", `ITCM.mem[8'h01]);
        $display("ITCM 0x02: %h", `ITCM.mem[8'h02]);
        $display("ITCM 0x03: %h", `ITCM.mem[8'h03]);
        $display("ITCM 0x04: %h", `ITCM.mem[8'h04]);
        $display("ITCM 0x05: %h", `ITCM.mem[8'h05]);
        $display("ITCM 0x06: %h", `ITCM.mem[8'h06]);
        $display("ITCM 0x07: %h", `ITCM.mem[8'h07]);
        $display("ITCM 0x16: %h", `ITCM.mem[8'h16]);
        $display("ITCM 0x20: %h", `ITCM.mem[8'h20]);
  end
end 

wire jtag_TDI = 1'b0;
wire jtag_TDO;
wire jtag_TCK = 1'b0;
wire jtag_TMS = 1'b0;
wire jtag_TRST = 1'b0;
wire jtag_DRV_TDO = 1'b0;

logic irq_i;
logic irq_ack_o;

zr_coreplex #(
    .RV32E(0),
    .RV32M(1),
    .TCM_ADDR_BASE(32'h8000_0000),
    .TCM_ADDR_MASK(32'h0000_3fff),
    .BOOT_ADDR(32'h8000_0000)
) u_cpu (
    .irq_i(irq_i),
    .irq_id_i('0),
    .irq_ack_o(irq_ack_o),
    .irq_id_o(),
    .*
);


logic irq_serviced;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        irq_i <= 1'b0;
        irq_serviced <= 1'b0;
    end
    else if (!irq_serviced) begin
        if (irq_i & irq_ack_o) begin
            irq_serviced <= 1'b1;
            irq_i <= 1'b0;
        end
        else if (cycle_count[11]) begin
            irq_i <= 1'b1;
        end
    end
end

endmodule
