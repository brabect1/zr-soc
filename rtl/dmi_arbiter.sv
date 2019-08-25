/*
Copyright 2019 Tomas Brabec

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
    2019, Feb.
    - Created.
*/


/**
* Implements a fair policy arbiter between two DTMs accessing the same DM.
* The module provides two DBus interfaces (i.e. DTM request/response pairs)
* arbitrated to a single DBus interface (i.e. DM request/response pair).
*
* The expected use case is that from two DTMs only one is used at a time
* to run a RISC-V debug session. Otherwise the fair arbitration policy makes
* little sense.
*
* All DBus ports implement the ready--valid protocol, where data handshake
* complets when both valid and ready are asserted.
*
*/
module dmi_arbiter #(
    // Number of DBus Request data bits
    parameter int DBUS_REQ_BITS = 41,
    // Number of DBus Response data bits
    parameter int DBUS_RSP_BITS = 34
)(
    // Rising edge active clock. All DBus interfaces have CDC synchronizers
    // at inputs so the clock sources may be whichever.
    input  logic clk,

    // Active low reset, asynchronous with synchronized removal.
    input  logic rst_n,

    // --- Port 0 DTM Interface ---
    input  logic                     dtm0_req_vld,
    output logic                     dtm0_req_rdy,
    input  logic [DBUS_REQ_BITS-1:0] dtm0_req_bits,
    output logic                     dtm0_rsp_vld,
    input  logic                     dtm0_rsp_rdy,
    output logic [DBUS_RSP_BITS-1:0] dtm0_rsp_bits,

    // --- Port 1 DTM Interface ---
    input  logic                     dtm1_req_vld,
    output logic                     dtm1_req_rdy,
    input  logic [DBUS_REQ_BITS-1:0] dtm1_req_bits,
    output logic                     dtm1_rsp_vld,
    input  logic                     dtm1_rsp_rdy,
    output logic [DBUS_RSP_BITS-1:0] dtm1_rsp_bits,

    // --- DM Interface ---
    output logic                     dm_req_vld,
    input  logic                     dm_req_rdy,
    output logic [DBUS_REQ_BITS-1:0] dm_req_bits,
    input  logic                     dm_rsp_vld,
    output logic                     dm_rsp_rdy,
    input  logic [DBUS_RSP_BITS-1:0] dm_rsp_bits
);


// ----------------------------------------------
// DTM to DM Request Path
// ----------------------------------------------

// enables accepting requests from DTM0
logic dtm0_req_allow;
// strobe indicating to proceed with processing DTM0 request
logic dtm0_req_accept;
// strobe indicating DTM0 request fall
logic dtm0_req_done;

// DTM1 signals with the same meaning as for DTM0
logic dtm1_req_allow;
logic dtm1_req_accept;
logic dtm1_req_done;

// indicates the end of handshake on the DM side
logic dm_req_done;


// DM Request (Output) Port
// ------------------------

// DM request data (latches request data bits from a DTM port, request of which
// gets accepted)
always_ff @(posedge clk or negedge rst_n) begin: p_dm_req_bits
    if (!rst_n)
        dm_req_bits <= '0;
    else if (dtm0_req_accept)
        dm_req_bits <= dtm0_req_bits;
    else if (dtm1_req_accept)
        dm_req_bits <= dtm1_req_bits;
end: p_dm_req_bits

// Indicates handshake completion on the DM side.
assign dm_req_done = dm_req_vld & dm_req_rdy;

// DM request indication (set on acceptance of a request from an either DTM
// port, cleared on DM request acknowledge)
always_ff @(posedge clk or negedge rst_n) begin: p_dm_req_vld
    if (!rst_n)
        dm_req_vld <= 1'b0;
    else if (dtm0_req_accept | dtm1_req_accept | dm_req_done)
        dm_req_vld <= dtm0_req_accept | dtm1_req_accept | (~dm_req_done);
end: p_dm_req_vld


// DTM0 Request (Input) Port
// -------------------------

// acceptance of the DTM0 Request
assign dtm0_req_accept = dtm0_req_vld & dtm0_req_rdy & dtm0_req_allow;

// The request completes if it has been pending (i.e. ready low) and the DM side
// completed the hanshake.
assign dtm0_req_done = dm_req_done & ~dtm0_req_rdy;

// DTM0 Request ready (also acts as an inverted Pending flag)
always_ff @(posedge clk or negedge rst_n) begin: p_dtm0_req_rdy
    if (!rst_n) begin
        dtm0_req_rdy <= 1'b1;
    end
    else if (dtm0_req_accept | dtm0_req_done) begin
        dtm0_req_rdy <= ~dtm0_req_accept | dtm0_req_done;
    end
end: p_dtm0_req_rdy


// DTM1 Request (Input) Port
// -------------------------
// (The implementation is the same as for DMT0 and hence requires no extra
// comments.)

assign dtm1_req_accept = dtm1_req_vld & dtm1_req_rdy & dtm1_req_allow;

assign dtm1_req_done = dm_req_done & ~dtm1_req_rdy;

always_ff @(posedge clk or negedge rst_n) begin: p_dtm1_req_rdy
    if (!rst_n) begin
        dtm1_req_rdy <= 1'b1;
    end
    else if (dtm1_req_accept | dtm1_req_done) begin
        dtm1_req_rdy <= ~dtm1_req_accept | dtm1_req_done;
    end
end: p_dtm1_req_rdy


// ----------------------------------------------
// DM to DTM Response Path
// ----------------------------------------------

// enables accepting responses from DM
logic dm_rsp_allow;
// strobe indicating to proceed with processing DM response
logic dm_rsp_accept;
// indicates end of DM response handshake
logic dm_rsp_done;

// Latched DM response forwarded to either DTM response port.
logic [DBUS_RSP_BITS-1:0] dtm_rsp_bits;

// sets DTM0 response request
logic dtm0_rsp_accept;
// clears DTM0 response request (in return to DTM0 response acknowledge)
logic dtm0_rsp_clr;

// DTM1 signals with the same meaning as for DTM0
logic dtm1_rsp_accept;
logic dtm1_rsp_clr;


// DTM response data (latches request data bits from the DM port, this flop
// is shared for both DTM ports)
always_ff @(posedge clk or negedge rst_n) begin: p_dtm_rsp_bits
    if (!rst_n)
        dtm_rsp_bits <= '0;
    else if (dm_rsp_accept)
        dtm_rsp_bits <= dm_rsp_bits;
end: p_dtm_rsp_bits

assign dtm0_rsp_bits = dtm_rsp_bits;
assign dtm1_rsp_bits = dtm_rsp_bits;


// DM Response (Input) Port
// ------------------------

// DM Response ready
always_ff @(posedge clk or negedge rst_n) begin: p_dm_rsp_rdy
    if (!rst_n) begin
        dm_rsp_rdy <= 1'b1;
    end
    else if (dm_rsp_accept | dm_rsp_done) begin
        dm_rsp_rdy <= ~dm_rsp_accept | dm_rsp_done;
    end
end: p_dm_rsp_rdy


// DTM0 Response (Output) Port
// ---------------------------

// clear DTM0 Response request after the handshake is over
assign dtm0_rsp_clr = dtm0_rsp_vld & dtm0_rsp_rdy;

// DTM0 Response request indication
always_ff @(posedge clk or negedge rst_n) begin: p_dtm0_rsp_vld
    if (!rst_n)
        dtm0_rsp_vld <= 1'b0;
    else if (dtm0_rsp_accept | dtm0_rsp_clr)
        dtm0_rsp_vld <= dtm0_rsp_accept | (~dtm0_rsp_clr);
end: p_dtm0_rsp_vld


// DTM1 Response (Output) Port
// ---------------------------
// (The implementation is the same as for DMT0 and hence requires no extra
// comments.)

assign dtm1_rsp_clr = dtm1_rsp_vld & dtm1_rsp_rdy;

always_ff @(posedge clk or negedge rst_n) begin: p_dtm1_rsp_vld
    if (!rst_n)
        dtm1_rsp_vld <= 1'b0;
    else if (dtm1_rsp_accept | dtm1_rsp_clr)
        dtm1_rsp_vld <= dtm1_rsp_accept | (~dtm1_rsp_clr);
end: p_dtm1_rsp_vld


// ----------------------------------------------
// Arbitration Policy
// ----------------------------------------------
// (This is a fair arbitration policy. For two DTM ports, this is represented
// by a single flop that holds the index of the last arbitrated DTM port.
// Besides the arbitration policy, there is a FSM monitoring progress of the
// DBus Request-Response transaction. This FSM is used to prevent accepting
// a new Request when a preceding Request-Response pair is still ongoing.)

// Identifies which DTM port has been serviced last.
logic dtm_src_last;

// Represents states of a state machine that tracks completion of DBus
// Request-Response transaction cycle. While the Request and Response
// represent independent channels within the DBus link layer, the DBus
// transaction layer assumes a transaction starts with a Request and
// shall be followed by a response.
typedef enum bit {
    // In this state, the arbiter allows accepting a new request from
    // either DTM port (and blocks handshake in the DBus response channel).
    Q_REQ = 1'b0,
    // In this state, the arbiter blocks accepting new requests from any
    // DTM port (and allows DM responses pass towards the initiating DTM
    // port).
    Q_RSP = 1'b1
} t_transaction_fsm;

// Present and next FSM state.
t_transaction_fsm trans_fsm_q;
t_transaction_fsm trans_fsm_n;


// DTM arbitration policy
// (If both DTM ports indicate a request at the same time, the policy selects
// which port is allowed to proceed with the request. The policy is based on
// the last port allowed to proceed and the actual state of DTM requests, and
// translates into the following Boolean table. The transition is conditioned
// by the transaction monitor FSM being in the request phase.)
//
// last    req0    req1 |  last'
// ---------------------+------
// 0       0       0    |  0
// 0       0       1    |  1
// 0       1       0    |  0
// 0       1       1    |  1
// 1       0       0    |  1
// 1       0       1    |  1
// 1       1       0    |  0
// 1       1       1    |  0
//
// The above Boolean table (including the FSM state guard) is yielded through
// "accept" and "allow" signals for both DTM ports.
always_ff @(posedge clk or negedge rst_n) begin: p_dtm_src_last
    if (!rst_n)
        dtm_src_last <= 1'b0;
    else begin
        // Request from both ports cannot be accepted at the same time.
        assert( ~(dtm0_req_accept & dtm1_req_accept) );
        if (dtm0_req_accept | dtm1_req_accept) begin
            dtm_src_last <= dtm1_req_accept;
        end
    end
end: p_dtm_src_last

// DTM Request is allowed when a) no other request is in progress, and
// b) the request is arbitrated.
assign dtm0_req_allow = (trans_fsm_q == Q_REQ) & ( dtm_src_last | ~dtm1_req_vld);
assign dtm1_req_allow = (trans_fsm_q == Q_REQ) & (~dtm_src_last | ~dtm0_req_vld);

// DM Response is allowed when a) a request is in progress, b) DM requests
// a response, and c) no other response is in progress.
assign dm_rsp_accept = (trans_fsm_q == Q_RSP) & dm_rsp_vld & dm_rsp_rdy;

// DTM Response port is selected by the index of the port from which the last
// Request came (represented by the arbitration policy).
assign dtm0_rsp_accept = dm_rsp_accept & ~dtm_src_last;
assign dtm1_rsp_accept = dm_rsp_accept &  dtm_src_last;

// DTM Response acknowledge fall strobe is selected based on the last Request
// port.
assign dm_rsp_done = dtm_src_last ? dtm1_rsp_clr : dtm0_rsp_clr;


// Transaction FSM current state
always_ff @(posedge clk or negedge rst_n) begin: p_trans_fsm_q
    if (!rst_n)
        trans_fsm_q <= Q_REQ;
    else
        trans_fsm_q <= trans_fsm_n;
end: p_trans_fsm_q


// Transaction FSM transition and output function
// (at the moment the FSM is fairly simple)
always_comb begin: p_trans_fsm_n
    trans_fsm_n = trans_fsm_q;

    case (trans_fsm_q)
        Q_REQ: begin
            if (dtm0_req_accept | dtm1_req_accept) begin
                trans_fsm_n = Q_RSP;
            end
        end

        Q_RSP: begin
            if (dm_rsp_done) begin
                trans_fsm_n = Q_REQ;
            end
        end

        default: begin
            $error("Unexpected FSM state: %0s", trans_fsm_q);
        end
    endcase
end: p_trans_fsm_n


endmodule: dmi_arbiter
