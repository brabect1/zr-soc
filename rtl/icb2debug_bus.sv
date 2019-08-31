/*
Copyright 2018 Tomas Brabec

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
    2018, Sep., Tomas Brabec
    - Created.
*/

/**
* Implements a DTM variant controlled from an ICB system bus.
*
* This implementation is merely for exercising Debug Module directly from
* a CPU. This may be somewhat tricky, but should work for covering basic
* DM functionality, incl. entering and leaving the debug mode.
*
* This module provides the following registers:
*
* - 00h (r/w): DM Request DWORD
* - 04h (r/w): DM Request Others
* - 08h (r/-): DM Response DWORD
* - 0Ch (r/-): DM Response Others
* - 10h (-/w): Control
* - 14h (r/-): Status
* - 18h (r/w): DM Interrupt Enable
* - 1Ch (r/w): Temporal DM Interrupt Disable
*
* DM Request Registers
* --------------------
*
* The two registers (DWORD and Others) are used for controling the request part of the
* DMI interface. For use of the registers refer to the description of the DMI
* interface.
*
* - DWORD[31:0]: Request data[31:0]
* - Others[3:2]: Request code
* - Others[8:4]: Request address
*
* DM Response Registers
* ---------------------
*
* The two registers (DWORD and Others) latch responses to requests on the the DMI
* interface.
*
* - DWORD[31:0]: Response data[31:0]
* - Others[3:2]: Response code
* - Others[8:4]: Request address (copied from DM Request Others at the completion
*                of DMI handshake)
*
* Control Register
* ----------------
*
* Presently this is a write-only register, for which writing to a register causes reset
* of this DTM module. The register reads as 0.
*
* Status Register
* ---------------
*
* Read-only register to provide miscellaneous status information. Its structure is as
* follows:
*
* - [31]: DMI Busy (asserted when there is a DMI operation in progress)
* - [HART_NUM-1:0]: Debug IRQ (represents the value on the `dbg_irq` input)
* - others: reserved (read as 0)
*
* DM Interrupt Enable Register
* ----------------------------
*
* Individual bits (starting from LSB) AND-mask interrupt request outputs of
* the DM module. The masking is implemented at the Coreplex level.
*
* - [n]: Log.1 enables DM interrupt [n]
*
* Temporary DM Interrupt Disable
* ------------------------------
*
* Writing this registers starts a down-counter that will (for all 1 bits) block
* DM interrupt until the counter underruns. The temporary disable overrides settings
* of the DM Interrupt Enable register.
*
* The n-th bit applies to the n-th DM IRQ.
*
* To restart the counter (e.g. to prolong the temporary delay), one can read and
* write back the register.
*
* The primary use of this register is to defer propagation of DM IRQ by a certain
* time. This is again for testing purposes, where CPU enters the Debug Mode by other
* than DM IRQ means and waits for a debuger to react by activating DM IRQ. CPU may
* mimic the debugger by (1) activating the temporary IRQ disable, (2) setting DM
* IRQ (through this DTM) and (3) taking whatever action to take the CPU into the
* Debug Mode (e.g. executing `ebreak` or setting `halt` in `dcsr`).
*
* DMI Interface
* -------------
*
* DMI is an interface between DTM and DM modules. It represents a request-response
* handshake interface, where a request initiated by DTM is responded to by DM.
*
* The request part carries an address, 32-bit data and 2-bit request code. This
* infomation is mapped to the DTM Request registers, such that data[31:0] maps
* to DM Request DWORD and the other information map to DM Request Others.
*
* The response part carries a 2-bit response code and 32-bit data. This information
* maps to the DM Response registers. Again, data[31:0] maps to DM Response DWORD and
* the other information to DM Response Others. Value of the DM Response registers
* updates only on the completion of the DMI request-response handshake.
*
* The handshake is started by writing into the DM Request Others register. Hence
* a new value of DM Request DWORD shall be written ahead of the write to DM Request
* Others. The completion of the handshake shall be monitored through MSB of the
* Status regoster. Once clear, the DM Response register hold the DM's response to
* the last DTM request.
*
*/
module icb2debug_bus #(
    parameter int DEBUG_DATA_BITS  = 32,
    parameter int DEBUG_ADDR_BITS = 7, // Spec allows values are 5-7 (TODO: need to double check)
    parameter int DEBUG_OP_BITS = 2, // OP and RESP are the same size.
    parameter int DBUS_REQ_BITS = DEBUG_OP_BITS + DEBUG_ADDR_BITS + DEBUG_DATA_BITS,
    parameter int DBUS_RESP_BITS = DEBUG_OP_BITS + DEBUG_DATA_BITS,
    parameter int HART_NUM = 1
) (
    input  logic clk,
    input  logic rst_n,

    // ICB Interface
    input  logic       icb_cmd_valid,
    output logic       icb_cmd_ready,
    input  logic[11:0] icb_cmd_addr,
    input  logic       icb_cmd_read,
    input  logic[31:0] icb_cmd_wdata,

    output logic       icb_rsp_valid,
    input  logic       icb_rsp_ready,
    output logic[31:0] icb_rsp_rdata,

    // Debug Bus interface
    output logic                     dtm_req_valid,
    input  logic                     dtm_req_ready,
    output logic[DBUS_REQ_BITS-1:0]  dtm_req_bits,

    input  logic                     dtm_resp_valid,
    output logic                     dtm_resp_ready,
    input  logic[DBUS_RESP_BITS-1:0] dtm_resp_bits,

    // Misc

    //! May be used to gate Debug IRQs going to RV cores (which is for purely
    //! testing purposes).
    output logic[HART_NUM-1:0] dbg_ien,

    //! When connected to DM's Debug IRQ outputs, these may be observed by
    //! reading from the Status register.
    input  logic[HART_NUM-1:0] dbg_irq
);

localparam logic [$size(icb_cmd_addr)-1:0] ADDR_REQ_DWORD  = 0;
localparam logic [$size(icb_cmd_addr)-1:0] ADDR_REQ_OTHERS = 4;
localparam logic [$size(icb_cmd_addr)-1:0] ADDR_RSP_DWORD  = 8;
localparam logic [$size(icb_cmd_addr)-1:0] ADDR_RSP_OTHERS = 12;
localparam logic [$size(icb_cmd_addr)-1:0] ADDR_CTRL = 16;
localparam logic [$size(icb_cmd_addr)-1:0] ADDR_STAT = 20;
localparam logic [$size(icb_cmd_addr)-1:0] ADDR_DM_IEN = 24;
localparam logic [$size(icb_cmd_addr)-1:0] ADDR_DM_TMP_IDIS = 28;

localparam int DBUS_OTHERS_LEN = DBUS_REQ_BITS - 32 +2; // the extra +2 is for unused LSBs (compatibility with RV DBG v0.11)

// synchronous reset activated on write into CTRL
logic dtm_rst;

logic[31:0] reg_dbus_req_dword;
logic[DBUS_OTHERS_LEN-1:0] reg_dbus_req_others;

logic[31:0] reg_dbus_rsp_dword;
logic[DBUS_OTHERS_LEN-1:0] reg_dbus_rsp_others;

logic[HART_NUM-1:0] reg_dm_ien;
logic[HART_NUM-1:0] reg_dm_tmp_idis;

logic we_ctrl;
logic we_dbus_req_dword;
logic we_dbus_req_others;
logic we_dbus_req_others_d;
logic dbus_op_start;
logic dbus_op_done;

typedef enum bit[DEBUG_OP_BITS-1:0] {
    OP_DBUS_NOP = 2'b00,
    OP_DBUS_READ = 2'b01,
    OP_DBUS_WRITE = 2'b10,
    OP_DBUS_RESERVED = 2'b11
} t_dbus_req_op;

typedef enum bit[DEBUG_OP_BITS-1:0] {
    OP_RSP_OK = 2'b00,
    OP_RSP_ERR = 2'b10,
    OP_RSP_BUSY = 2'b11,
    OP_RSP_RESERVED = 2'b01
} t_dbus_rsp_stat;

typedef enum bit[1:0] {
    Q_DBUS_IDLE,
    Q_DBUS_REQ_BUSY,
    Q_DBUS_RSP_BUSY
} t_dbus_fsm_state;

t_dbus_req_op dbus_req_op_i;
t_dbus_req_op dbus_req_op;
t_dbus_rsp_stat dbus_rsp_stat;
logic dbus_rsp_stat_sticky;

t_dbus_fsm_state dbus_fsm_act;
t_dbus_fsm_state dbus_fsm_nxt;


// Temporary DM Interrupt Disable
always_ff @(posedge clk or negedge rst_n) begin: p_dm_tmp_idis_reg
    if (!rst_n) begin
        reg_dm_tmp_idis <= '0;
    end
    else begin
        if (dtm_rst)
            reg_dm_tmp_idis <= '0;
        else if ((icb_cmd_addr == ADDR_DM_TMP_IDIS) & icb_cmd_valid & icb_cmd_ready & ~icb_cmd_read)
            reg_dm_tmp_idis <= icb_cmd_wdata[HART_NUM-1:0];
    end
end: p_dm_tmp_idis_reg


// Temporary Interrupt Disable Counter
// (Presently the counter length is fixed to 64. The counter is set off by writing
// into the Temporary DM Interrupt Disable register. The counter stops on underrun.)
logic[6:0] cnt_dm_tmp_idis;
logic cnt_dm_tmp_idis_urun;
always_ff @(posedge clk or negedge rst_n) begin: p_dm_tmp_idis_cnt
    if (!rst_n) begin
        cnt_dm_tmp_idis <= '1;
    end
    else begin
        if (dtm_rst)
            cnt_dm_tmp_idis <= '1;
        else if ((icb_cmd_addr == ADDR_DM_TMP_IDIS) & icb_cmd_valid & icb_cmd_ready & ~icb_cmd_read)
            cnt_dm_tmp_idis <= {1'b0,{$size(cnt_dm_tmp_idis)-1{1'b1}}};
        else if (~cnt_dm_tmp_idis_urun)
            cnt_dm_tmp_idis <= cnt_dm_tmp_idis - 1'b1;
    end
end: p_dm_tmp_idis_cnt

assign cnt_dm_tmp_idis_urun = cnt_dm_tmp_idis[$high(cnt_dm_tmp_idis)];


// DM Interrupt Enable
always_ff @(posedge clk or negedge rst_n) begin: p_dm_ien_reg
    if (!rst_n) begin
        reg_dm_ien <= '0;
    end
    else begin
        if (dtm_rst)
            reg_dm_ien <= '0;
        else if ((icb_cmd_addr == ADDR_DM_IEN) & icb_cmd_valid & icb_cmd_ready & ~icb_cmd_read)
            reg_dm_ien <= icb_cmd_wdata[HART_NUM-1:0];
    end
end: p_dm_ien_reg

assign dbg_ien = reg_dm_ien & ~(reg_dm_tmp_idis & {HART_NUM{~cnt_dm_tmp_idis_urun}});


// DM Request registers
always_ff @(posedge clk or negedge rst_n) begin: p_req_regs
    if (!rst_n) begin
        reg_dbus_req_dword <= '0;
        reg_dbus_req_others <= '0;
    end
    else if (icb_cmd_valid & icb_cmd_ready & ~icb_cmd_read & (dbus_fsm_act == Q_DBUS_IDLE)) begin
        if (icb_cmd_addr == ADDR_REQ_OTHERS)
            reg_dbus_req_others <= icb_cmd_wdata[DBUS_OTHERS_LEN-1:0];
        if (icb_cmd_addr == ADDR_REQ_DWORD)
            reg_dbus_req_dword <= icb_cmd_wdata;
    end
end: p_req_regs

// DM Response registers (RSP DWORD and RSP OTHERS)
always_ff @(posedge clk or negedge rst_n) begin: p_resp_regs
    if (!rst_n) begin
        reg_dbus_rsp_dword <= '0;
        reg_dbus_rsp_others <= '0;
    end
    else if (dbus_op_done) begin
        reg_dbus_rsp_dword <= dtm_resp_bits[DEBUG_OP_BITS +:32];
        reg_dbus_rsp_others <= {reg_dbus_req_others[2+DEBUG_OP_BITS +:DEBUG_ADDR_BITS], dbus_rsp_stat, 2'b00};
    end
end: p_resp_regs

// Generate strobe for writing into the CTRL register
assign we_ctrl = (icb_cmd_addr == ADDR_CTRL) & icb_cmd_valid & icb_cmd_ready & ~icb_cmd_read;

// Generate strobe for writing into the REQ DWORD register
assign we_dbus_req_dword = (icb_cmd_addr == ADDR_REQ_DWORD) & icb_cmd_valid & icb_cmd_ready & ~icb_cmd_read;

// Generate a starting strobe on write into the REQ OTHERS reguster
assign we_dbus_req_others = (icb_cmd_addr == ADDR_REQ_OTHERS) & icb_cmd_valid & icb_cmd_ready & ~icb_cmd_read;

always_ff @(posedge clk or negedge rst_n) begin : p_dbus_op_start
    if (!rst_n) begin
        dbus_op_start <= 1'b0;
        we_dbus_req_others_d <= 1'b0;
    end
    else begin
        we_dbus_req_others_d <= we_dbus_req_others;
        dbus_op_start <= we_dbus_req_others & ~we_dbus_req_others_d;
    end
end: p_dbus_op_start

// Just directly pass back the valid in 0 cycle
assign icb_rsp_valid = icb_cmd_valid;
assign icb_cmd_ready = icb_rsp_ready;

// ICB read multiplexer
always_comb begin: p_icb_rsp_mux
    if (icb_cmd_valid & icb_cmd_read) begin
        case (icb_cmd_addr)
            ADDR_REQ_DWORD:  icb_rsp_rdata = reg_dbus_req_dword;
            ADDR_REQ_OTHERS: icb_rsp_rdata = reg_dbus_req_others;
            ADDR_RSP_DWORD:  icb_rsp_rdata = reg_dbus_rsp_dword;
            ADDR_RSP_OTHERS: icb_rsp_rdata = reg_dbus_rsp_others;
            ADDR_STAT:       icb_rsp_rdata = {(dbus_fsm_act != Q_DBUS_IDLE), {31-HART_NUM{1'b0}}, dbg_irq};
            default:         icb_rsp_rdata = '0;
        endcase
    end
    else
        icb_rsp_rdata = '0;
end: p_icb_rsp_mux

assign dtm_req_bits[DEBUG_DATA_BITS-1:0] = {
    reg_dbus_req_dword
};
assign dtm_req_bits[DEBUG_OP_BITS+DEBUG_DATA_BITS-1:DEBUG_DATA_BITS] = dbus_req_op;
assign dtm_req_bits[DBUS_REQ_BITS-1:DEBUG_OP_BITS+DEBUG_DATA_BITS] = reg_dbus_req_others[DBUS_OTHERS_LEN-1:2+DEBUG_OP_BITS];

assign dtm_resp_ready = dtm_resp_valid;

assign dbus_req_op_i = t_dbus_req_op'(reg_dbus_req_others[2+DEBUG_OP_BITS-1:2]);
assign dbus_rsp_stat = t_dbus_rsp_stat'({dbus_rsp_stat_sticky, dtm_resp_bits[0]});

assign dtm_rst = we_ctrl;


always_ff @(posedge clk or negedge rst_n) begin: p_dbus_stat_sticky
    if (!rst_n) begin
        dbus_rsp_stat_sticky <= 1'b0;
    end
    else begin
        if (dtm_rst) begin
            dbus_rsp_stat_sticky <= 1'b0;
        end
        else if ((we_dbus_req_dword | we_dbus_req_others) & (dbus_fsm_act != Q_DBUS_IDLE)) begin
            dbus_rsp_stat_sticky <= 1'b1;
        end
    end
end: p_dbus_stat_sticky


always_ff @(posedge clk or negedge rst_n) begin: p_dbus_req_op
    if (!rst_n) begin
        dbus_req_op <= OP_DBUS_NOP;
    end
    else
        if (dtm_rst)
            dbus_req_op <= OP_DBUS_NOP;
        else if (dbus_op_start & (dbus_fsm_act == Q_DBUS_IDLE)) begin
            dbus_req_op <= dbus_req_op_i;
        end
end: p_dbus_req_op


always_ff @(posedge clk or negedge rst_n) begin: p_dbus_fsm_act
    if (!rst_n)
        dbus_fsm_act <= Q_DBUS_IDLE;
    else
        if (dtm_rst)
            dbus_fsm_act <= Q_DBUS_IDLE;
        else
            dbus_fsm_act <= dbus_fsm_nxt;
end: p_dbus_fsm_act


always_comb begin: p_dbus_fsm
    dtm_req_valid = 1'b0;
    dbus_op_done = 1'b0;
    dbus_fsm_nxt = Q_DBUS_IDLE;

    case (dbus_fsm_act)
        Q_DBUS_IDLE: begin
            if (dbus_op_start)
                dbus_fsm_nxt = Q_DBUS_REQ_BUSY;
            else
                dbus_fsm_nxt = Q_DBUS_IDLE;
        end

        Q_DBUS_REQ_BUSY: begin
            dtm_req_valid = 1'b1;
            dbus_fsm_nxt = Q_DBUS_REQ_BUSY;
            if (dtm_req_ready) begin
                if (dtm_resp_valid) begin
                    dbus_fsm_nxt = Q_DBUS_IDLE;
                    dbus_op_done = 1'b1;
                end else begin
                    dbus_fsm_nxt = Q_DBUS_RSP_BUSY;
                end
            end
        end

        Q_DBUS_RSP_BUSY: begin
            dbus_fsm_nxt = Q_DBUS_RSP_BUSY;
            if (dtm_resp_valid) begin
                dbus_fsm_nxt = Q_DBUS_IDLE;
                dbus_op_done = 1'b1;
            end
        end

`ifndef SYNTHESIS
        default: begin
            $error("Unexpected state: dbus_fsm_act = %s", dbus_fsm_act);
        end
`endif
    endcase
end: p_dbus_fsm

endmodule: icb2debug_bus
