// Copyright 2018 Tomas Brabec
// 
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// 
//     http://www.apache.org/licenses/LICENSE-2.0
// 
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

module zr_coreplex #(
    parameter int RV32E = 0,
    parameter int RV32M = 1,
    parameter logic[31:0] TCM_ADDR_BASE = 32'h8000_0000,
    parameter logic[31:0] TCM_ADDR_MASK = 32'h0000_3fff,
    parameter logic[31:0] BOOT_ADDR = TCM_ADDR_BASE
) (
    input  logic        irq_i,                 // level sensitive IR lines
    input  logic [4:0]  irq_id_i,
    output logic        irq_ack_o,             // irq ack
    output logic [4:0]  irq_id_o,

    input  logic clk,
    input  logic rst_n
);

// Instruction memory interface
logic        instr_req_o;
logic        instr_gnt_i;
logic        instr_rvalid_i;
logic [31:0] instr_addr_o;
logic [31:0] instr_rdata_i;

// Data memory interface
logic        data_req_o;
logic        data_gnt_i;
logic        data_rvalid_i;
logic        data_we_o;
logic [3:0]  data_be_o;
logic [31:0] data_addr_o;
logic [31:0] data_wdata_o;
logic [31:0] data_rdata_i;
logic        data_err_i;

// Other
logic dbg_irq;
logic dm_dbg_irq;
logic dtm_dbg_ien;

assign dbg_irq = dm_dbg_irq & dtm_dbg_ien;

// ----------------------------------------------
// CPU Core
// ----------------------------------------------
zeroriscy_core #(
    .N_EXT_PERF_COUNTERS(0),
    .RV32E(RV32E),
    .RV32M(RV32M)
) u_core (
    // Clock and Reset
    .clk_i(clk),
    .rst_ni(rst_n),
    .clock_en_i(1'b1),    // enable clock, otherwise it is gated
    .test_en_i(1'b0),     // enable all clock gates for testing

    // Core ID, Cluster ID and boot address are considered more or less static
    .core_id_i('0),
    .cluster_id_i('0),
    .boot_addr_i(BOOT_ADDR),

    // Interrupt inputs
    .irq_i( irq_i ),                 // level sensitive IR lines
    .irq_id_i( irq_id_i ),
    .irq_ack_o( irq_ack_o ),             // irq ack
    .irq_id_o( irq_id_o ),

    // Debug Interface (legacy)
    .debug_req_i(1'b0),
    .debug_gnt_o(),
    .debug_rvalid_o(),
    .debug_addr_i('0),
    .debug_we_i(1'b0),
    .debug_wdata_i('0),
    .debug_rdata_o(),
    .debug_halted_o(),
    .debug_halt_i(1'b0),
    .debug_resume_i(1'b0),

    // Debug interface (RV)
    .dbg_irq( dbg_irq ),

    // CPU Control Signals
    .fetch_enable_i(1'b1),
    .ext_perf_counters_i('0),

    // other ports
    .*
);

// ----------------------------------------------
// TCM (Tightly Coupled Memory)
// ----------------------------------------------

// Instruction memory interface
logic        tcm_instr_cs;
logic        tcm_instr_gnt_i;
logic        tcm_instr_rvalid_i;
logic [31:0] tcm_instr_rdata_i;

// Data memory interface
logic        tcm_data_cs;
logic        tcm_data_gnt_i;
logic        tcm_data_rvalid_i;
logic [31:0] tcm_data_rdata_i;
logic        tcm_data_err_i;

localparam int TCM_AWIDTH = $countones(TCM_ADDR_MASK);

assign tcm_instr_cs = instr_req_o & ((instr_addr_o & ~TCM_ADDR_MASK) == (TCM_ADDR_BASE & ~TCM_ADDR_MASK));
assign tcm_data_cs = data_req_o & ((data_addr_o & ~TCM_ADDR_MASK) == (TCM_ADDR_BASE & ~TCM_ADDR_MASK));

assign tcm_data_err_i = 1'b0;
assign tcm_data_gnt_i = tcm_data_cs;
assign tcm_instr_gnt_i = tcm_instr_cs;

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        tcm_data_rvalid_i <= 1'b0;
        tcm_instr_rvalid_i <= 1'b0;
    end
    else begin
        tcm_data_rvalid_i <= tcm_data_cs;
        tcm_instr_rvalid_i <= tcm_instr_cs;
    end
end

dp_ram #(
    .NB_COL(4),
    .COL_WIDTH(8),
    .AWIDTH(TCM_AWIDTH-1),
    .INIT_FILE("")
) u_tcm_ram (
    .addra(instr_addr_o[TCM_AWIDTH:2]),
    .addrb(data_addr_o[TCM_AWIDTH:2]),
    .dina('0),
    .dinb(data_wdata_o),
    .clka(clk),
    .clkb(clk),
    .wea('0),
    .web( {$size(data_be_o){data_we_o}} & data_be_o ),
//---->>>> TODO use *_req_o
    .ena(tcm_instr_cs), // Port A RAM Enable, for additional power savings, disable BRAM when not in use
    .enb(tcm_data_cs), // Port B RAM Enable, for additional power savings, disable BRAM when not in use
//<<<<----
    .douta(tcm_instr_rdata_i),
    .doutb(tcm_data_rdata_i)
);


// ----------------------------------------------
// System Bus Debug Transport Module
// ----------------------------------------------

localparam int DBUS_REQ_BITS = 41;
localparam int DBUS_RESP_BITS = 36;

// Debug Bus interface
logic                     dtm_req_valid;
logic                     dtm_req_ready;
logic[DBUS_REQ_BITS-1:0]  dtm_req_bits;
logic                     dtm_resp_valid;
logic                     dtm_resp_ready;
logic[DBUS_RESP_BITS-1:0] dtm_resp_bits;


localparam logic[31:0] DTM_ADDR_BASE = 32'h0000_4000;
localparam logic[31:0] DTM_ADDR_MASK = 32'h0000_0fff;

// DTM to Data memory interface
logic        dtm_data_cs;
logic        dtm_data_gnt_i;
logic        dtm_data_rvalid_i;
logic [31:0] dtm_data_rdata_i;
logic        dtm_data_err_i;

// DTM ICB interface
logic       dtm_cmd_valid;
logic       dtm_cmd_ready;
logic       dtm_cmd_read;
logic       dtm_rsp_valid;
logic       dtm_rsp_ready;
logic[31:0] dtm_rsp_rdata;

assign dtm_data_cs = data_req_o & ((data_addr_o & ~DTM_ADDR_MASK) == (DTM_ADDR_BASE & ~DTM_ADDR_MASK));

assign dtm_data_err_i = 1'b0;
assign dtm_data_gnt_i = dtm_cmd_valid & dtm_cmd_ready;

//always_ff @(posedge clk or negedge rst_n) begin
//    if (!rst_n) begin
//        dtm_data_rvalid_i <= 1'b0;
//    end
//    else begin
//        dtm_data_rvalid_i <= dtm_data_cs;
//    end
//end
assign dtm_rsp_ready = 1'b1;
assign dtm_cmd_valid = dtm_data_cs;
assign dtm_cmd_read = ~data_we_o;
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        dtm_data_rvalid_i <= 1'b0;
        dtm_data_rdata_i <= '0;
    end
    else begin
        dtm_data_rvalid_i <= dtm_rsp_valid & dtm_rsp_ready;
        dtm_data_rdata_i <= (dtm_rsp_valid & dtm_rsp_ready) ? dtm_rsp_rdata : '0;
    end
end

icb2debug_bus u_icb2dm (
    .icb_cmd_valid( dtm_cmd_valid ),
    .icb_cmd_ready( dtm_cmd_ready ),
    .icb_cmd_addr(  data_addr_o[11:0] ),
    .icb_cmd_read(  dtm_cmd_read ),
    .icb_cmd_wdata( data_wdata_o ),
    .icb_rsp_valid( dtm_rsp_valid ),
    .icb_rsp_ready( dtm_rsp_ready ),
    .icb_rsp_rdata( dtm_rsp_rdata ),
    .dbg_irq( dm_dbg_irq ),
    .dbg_ien( dtm_dbg_ien ),
    .*
);

// ----------------------------------------------
// RISC-V Debug Module
// ----------------------------------------------

localparam logic[31:0] DM_ADDR_BASE = 32'h0000_0000;
localparam logic[31:0] DM_ADDR_MASK = 32'h0000_3fff;

// DM to Instruction memory interface
logic        dm_instr_cs;
logic        dm_instr_gnt_i;
logic        dm_instr_rvalid_i;
logic [31:0] dm_instr_rdata_i;

// DM to Data memory interface
logic        dm_data_cs;
logic        dm_data_gnt_i;
logic        dm_data_rvalid_i;
logic [31:0] dm_data_rdata_i;
logic        dm_data_err_i;

// DM Instruction/Data memory arbiter
logic dm_instr_sel;

// DM ICB interface
logic       dm_cmd_valid;
logic       dm_cmd_ready;
logic[11:0] dm_cmd_addr;
logic       dm_cmd_read;
logic[31:0] dm_cmd_wdata;
logic       dm_rsp_valid;
logic       dm_rsp_ready;
logic[31:0] dm_rsp_rdata;

assign dm_instr_cs = instr_req_o & ((instr_addr_o & ~DM_ADDR_MASK) == (DM_ADDR_BASE & ~DM_ADDR_MASK));
assign dm_data_cs = data_req_o & ((data_addr_o & ~DM_ADDR_MASK) == (DM_ADDR_BASE & ~DM_ADDR_MASK));

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        dm_instr_sel <= 1'b1;
        dm_cmd_valid <= 1'b0;
    end
    else begin
        if (dm_instr_cs & dm_data_cs)
            dm_instr_sel <= ~dm_instr_sel;
        else
            dm_instr_sel <= dm_instr_cs;

        dm_cmd_valid <= (dm_instr_cs | dm_data_cs) & ~(dm_cmd_valid & dm_cmd_ready);
    end
end

assign dm_rsp_ready = 1'b1;
assign dm_cmd_wdata = data_wdata_o;
assign dm_cmd_addr  = dm_instr_sel ? instr_addr_o[11:0] : data_addr_o[11:0];
assign dm_cmd_read  = dm_instr_sel ? 1'b1 : ~data_we_o;
//assign dm_instr_rdata_i = {32{dm_instr_sel & dm_instr_cs}} & dm_rsp_rdata;
//assign dm_data_rdata_i = {32{~dm_instr_sel & dm_data_cs}}  & dm_rsp_rdata;
assign dm_instr_gnt_i = dm_instr_sel & dm_cmd_valid & dm_cmd_ready;
//assign dm_instr_rvalid_i = dm_instr_sel & dm_rsp_valid & dm_rsp_ready;
assign dm_data_err_i = 1'b0;
assign dm_data_gnt_i = ~dm_instr_sel & dm_cmd_valid & dm_cmd_ready;
//assign dm_data_rvalid_i = ~dm_instr_sel & dm_rsp_valid & dm_rsp_ready;

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        dm_instr_rvalid_i <= 1'b0;
        dm_instr_rdata_i <= '0;
        dm_data_rvalid_i <= 1'b0;
        dm_data_rdata_i <= '0;
    end
    else begin
        dm_instr_rvalid_i <= dm_instr_sel & dm_rsp_valid & dm_rsp_ready;
        dm_instr_rdata_i <= (dm_instr_sel & dm_rsp_valid & dm_rsp_ready) ? dm_rsp_rdata : '0;
        dm_data_rvalid_i <= ~dm_instr_sel & dm_rsp_valid & dm_rsp_ready;
        dm_data_rdata_i <= (~dm_instr_sel & dm_rsp_valid & dm_rsp_ready) ? dm_rsp_rdata : '0;
    end
end


riscv_dm_0p11 #(
    .ASYNC_FF_LEVELS(2),
    .PC_SIZE(32),
    .HART_NUM(2),
    .HART_ID_W(1)
) u_dm(
    .i_icb_cmd_valid( dm_cmd_valid ),
    .i_icb_cmd_ready( dm_cmd_ready ),
    .i_icb_cmd_addr(  dm_cmd_addr ),
    .i_icb_cmd_read(  dm_cmd_read ),
    .i_icb_cmd_wdata( dm_cmd_wdata ),
    .i_icb_rsp_valid( dm_rsp_valid ),
    .i_icb_rsp_ready( dm_rsp_ready ),
    .i_icb_rsp_rdata( dm_rsp_rdata ),
    .o_dbg_irq( dm_dbg_irq ),
    .o_ndreset(),
    .o_fullreset(),
    .test_mode(1'b0),
    .*
);

// ----------------------------------------------
// Instruction Memory Interface Aggregation
// ----------------------------------------------

assign instr_gnt_i = 
    tcm_instr_gnt_i |
    dm_instr_gnt_i;

assign instr_rvalid_i =
    tcm_instr_rvalid_i |
    dm_instr_rvalid_i;

assign instr_rdata_i =
    (tcm_instr_rdata_i & {32{tcm_instr_rvalid_i}}) |
    (dm_instr_rdata_i & {32{dm_instr_rvalid_i}});

// ----------------------------------------------
// Data Memory Interface Aggregation
// ----------------------------------------------

assign data_gnt_i =
    tcm_data_gnt_i |
    dm_data_gnt_i |
    dtm_data_gnt_i;

assign data_rvalid_i =
    tcm_data_rvalid_i |
    dm_data_rvalid_i |
    dtm_data_rvalid_i;

assign data_rdata_i =
    (tcm_data_rdata_i & {32{tcm_data_rvalid_i}}) |
    (dm_data_rdata_i & {32{dm_data_rvalid_i}}) |
    (dtm_data_rdata_i & {32{dtm_data_rvalid_i}});

assign data_err_i =
    tcm_data_err_i |
    dm_data_err_i |
    dtm_data_err_i;

endmodule: zr_coreplex


module dp_ram #(
    parameter int NB_COL,                     // Specify number of columns (number of bytes)
    parameter int COL_WIDTH,                  // Specify column width (byte width, typically 8 or 9)
    parameter int AWIDTH,                  // Specify RAM depth (number of entries)
    parameter string INIT_FILE = ""           // Specify name/location of RAM initialization file if using one (leave blank if not)
) (
    input  logic [AWIDTH-1:0] addra,  // Port A address bus, width determined from RAM_DEPTH
    input  logic [AWIDTH-1:0] addrb,  // Port B address bus, width determined from RAM_DEPTH
    input  logic [(NB_COL*COL_WIDTH)-1:0] dina,  // Port A RAM input data
    input  logic [(NB_COL*COL_WIDTH)-1:0] dinb,  // Port B RAM input data
    input  logic clka,                           // Clock
    input  logic clkb,                           // Clock
    input  logic [NB_COL-1:0] wea,               // Port A write enable
    input  logic [NB_COL-1:0] web,	           // Port B write enable
    input  logic ena,                            // Port A RAM Enable, for additional power savings, disable BRAM when not in use
    input  logic enb,                            // Port B RAM Enable, for additional power savings, disable BRAM when not in use
    output logic [(NB_COL*COL_WIDTH)-1:0] douta, // Port A RAM output data
    output logic [(NB_COL*COL_WIDTH)-1:0] doutb  // Port B RAM output data
);

    logic [(NB_COL*COL_WIDTH)-1:0] mem [2**AWIDTH-1:0];

    // The following code either initializes the memory values to a specified file or to all zeros to match hardware
    if (INIT_FILE != "") begin: use_init_file
        initial
            $readmemh(INIT_FILE, mem, 0, 2**AWIDTH-1);
    end else begin: init_bram_to_zero
        integer ram_index;
        initial begin
            for (ram_index = 0; ram_index < 2**AWIDTH; ram_index = ram_index + 1)
                mem[ram_index] = {(NB_COL*COL_WIDTH){1'b0}};
        end
    end

    always @(posedge clka)
        if (ena) begin
            douta <= mem[addra];
        end

    always @(posedge clkb)
        if (enb) begin
            doutb <= mem[addrb];
        end

    for (genvar i = 0; i < NB_COL; i = i+1) begin: byte_write
        always @(posedge clka)
            if (ena)
                if (wea[i])
                    mem[addra][(i+1)*COL_WIDTH-1:i*COL_WIDTH] <= dina[(i+1)*COL_WIDTH-1:i*COL_WIDTH];

        always @(posedge clkb)
            if (enb)
                if (web[i])
                    mem[addrb][(i+1)*COL_WIDTH-1:i*COL_WIDTH] <= dinb[(i+1)*COL_WIDTH-1:i*COL_WIDTH];
    end

endmodule: dp_ram
