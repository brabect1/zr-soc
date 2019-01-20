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

  2018, Nov, Tomas Brabec
  - Created from the testbench file in
    https://github.com/brabect1/e200_opensource/tree/master/verilator
  - Simple SPI flash model along with option (`BOOTROM=1`) to execute code from
    there. As RAM and Flash have base addresses different in the most significant
    byte, that byte is ignored in PC (program counter) for detecting an ISA test
    binary reaching certain point in the test program.

*/

module tb_verilator(
    output logic uart_rx_rdy,
    output logic uart_rx_err,
    output int   uart_rx_data,
    input  wire  clk,
    input  wire  rst_n
);

`ifndef TCM_AWIDTH
`define TCM_AWIDTH 16
`endif

//`define TCM_INIT_FILE "/tmp/github/zr/bram_init.txt"
`define CPU_TOP u_soc.u_cpu.u_core
`define EXU `CPU_TOP.u_e203_cpu.u_e203_core.u_e203_exu
`define ITCM u_soc.u_cpu.u_tcm_ram

`define PC_WRITE_TOHOST       32'h0000010e
`define PC_EXT_IRQ_BEFOR_MRET 32'h000000a6
`define PC_SFT_IRQ_BEFOR_MRET 32'h000000be
`define PC_TMR_IRQ_BEFOR_MRET 32'h000000d6
`define PC_AFTER_SETMTVEC     32'h0000015C

`ifndef UART_BAUD_CLOCKS
`define UART_BAUD_CLOCKS 2
`endif

`ifndef UART_BITS
`define UART_BITS 8
`endif

`ifndef UART_STOPS
`define UART_STOPS 1
`endif

wire [31:0] x3 = `CPU_TOP.id_stage_i.registers_i.rf_reg[3];
wire [31:0] pc = `CPU_TOP.pc_id;
wire [31:0] pc_vld = `CPU_TOP.instr_valid_id;

reg [31:0] pc_write_to_host_cnt;
reg [31:0] pc_write_to_host_cycle;
reg [31:0] valid_ir_cycle;
reg [31:0] cycle_count;
reg pc_write_to_host_flag;

always @(posedge clk or negedge rst_n) begin 
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

always @(posedge clk or negedge rst_n) begin 
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


logic [7:0] itcm_mem [0:2**`TCM_AWIDTH-1];

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
        u_spi_dev.mem_set(0,8'haa);
        u_spi_dev.mem_set(1,8'h55);
        u_spi_dev.mem_set(2,8'h81);
        u_spi_dev.mem_set(3,8'h0f);
`ifndef TCM_INIT_FILE
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
`endif
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

logic[31:0] io_gpio_i;
logic[31:0] io_gpio_o;
logic[31:0] io_gpio_oe;
logic[31:0] io_gpio_pue;
logic[31:0] io_gpio_ds;
logic[31:0] io_gpio_i_default;

logic sck;
logic spi_cs_n;
wire  [3:0] spi_dq;
logic [3:0] spi_dut_dq_o;
logic [3:0] spi_dut_dq_oe;
logic [3:0] spi_dev_dq_o;
logic [3:0] spi_dev_dq_t;

wire uart_txd = io_gpio_o[17];
assign io_gpio_i_default = { {15{1'b1}}, uart_txd, {16{1'b1}} };

for (genvar i=0; i < $size(io_gpio_i); i++) begin
    assign io_gpio_i[i] = (io_gpio_ds[i] & ~io_gpio_pue[i]) ? io_gpio_o[i] : io_gpio_i_default[i];
end

zr_soc #(
    .RV32E(0),
    .RV32M(1),
`ifdef TCM_INIT_FILE
    .TCM_INIT_FILE(`TCM_INIT_FILE),
`endif
    .TCM_ADDR_BASE(32'h8000_0000),
//    .TCM_ADDR_MASK(32'h0000_3fff),
    .TCM_AWIDTH(`TCM_AWIDTH),
    .BOOT_ADDR(32'h8000_0000)
) u_soc (
    .irq_i(irq_i),
    .irq_id_i('0),
    .irq_ack_o(irq_ack_o),
    .irq_id_o(),
    .io_qspi_sck_o(sck),
    .io_qspi_sck_oe( ),
    .io_qspi_sck_pue( ),
    .io_qspi_cs_0_o(spi_cs_n),
    .io_qspi_cs_0_oe( ),
    .io_qspi_cs_0_pue( ),
    .io_qspi_dq_i(spi_dq),
    .io_qspi_dq_o(spi_dut_dq_o),
    .io_qspi_dq_oe(spi_dut_dq_oe),
    .io_qspi_dq_pue( ),
    .*
);


for (genvar i=0; i<4; i++) begin
    assign spi_dq[i] = spi_dut_dq_oe[i] ? spi_dut_dq_o[i] : 1'bz;
    assign spi_dq[i] = spi_dev_dq_t[i] ? 1'bz : spi_dev_dq_o[i];
end

spi_model#(.SIZE(2**16)) u_spi_dev(
    .sck(sck),
    .rst_n(rst_n),
    .cs_n(spi_cs_n),
    .dq_i(spi_dq),
    .dq_o(spi_dev_dq_o),
    .dq_t(spi_dev_dq_t)
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
        else if (cycle_count[13]) begin
            irq_i <= 1'b1;
        end
    end
end


uart_model u_uart (
    .clk(clk),
    .rst_n(rst_n),

    .ctrl_baud_clks(`UART_BAUD_CLOCKS),
    .ctrl_bits(`UART_BITS),
    .ctrl_stops(`UART_STOPS),

    .rxd(uart_txd),
    .rx_rdy(uart_rx_rdy),
    .rx_err(uart_rx_err),
    .rx_data(uart_rx_data)
);

endmodule
