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
    2019, Jan., Tomas Brabec
    - Created.
*/


/**
* Implements an UART receiver with baud rate defined in terms of a reference
* clock.
*
* This implementation is useful for Verilator that does not support a lot of
* behavioral simulation SystemVerilog constructs.
*/
module uart_model (
    input  logic clk,
    input  logic rst_n,

    input  int ctrl_baud_clks,
    input  int ctrl_bits,
    input  int ctrl_stops,

    input  logic rxd,
    output logic rx_rdy,
    output logic rx_err,
    output int rx_data
);

typedef enum {
    RX_IDLE,
    RX_START,
    RX_DATA,
    RX_STOP,
    RX_RECOVER
} t_rx_state;

logic rx_rdy_comb;
logic rx_err_comb;

t_rx_state rx_fsm_q;
t_rx_state rx_fsm_n;

int baud_cnt;
logic baud_rst;
logic baud_half;
logic baud_full;
int bit_cnt;

always @(posedge clk) begin
    if (baud_rst) begin
        baud_cnt <= 1;
    end
    else begin
        baud_cnt <= (baud_cnt >= ctrl_baud_clks) ? 1 : baud_cnt + 1;
    end
end


assign baud_half = baud_cnt == (ctrl_baud_clks/2);
assign baud_full = baud_cnt >= ctrl_baud_clks;


always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rx_fsm_q <= RX_IDLE;
        rx_rdy <= 1'b0;
        rx_err <= 1'b0;
    end
    else begin
        rx_fsm_q <= rx_fsm_n;
        rx_rdy <= rx_rdy_comb;
        rx_err <= rx_err_comb;
    end
end


always_comb begin
    rx_fsm_n = rx_fsm_q;
    baud_rst = 1'b1;
    rx_rdy_comb = 1'b0;
    rx_err_comb = 1'b0;

    case (rx_fsm_q)
        RX_IDLE: begin
            if (rxd == 1'b0) begin
                baud_rst = baud_half ? 1'b1 : 1'b0;
                rx_fsm_n = baud_half ? RX_DATA : RX_START;
            end
        end

        RX_START: begin
            baud_rst = 1'b0;
            if (baud_half) begin
                rx_fsm_n = RX_DATA;
                baud_rst = 1'b1;
            end
            else if (rxd != 1'b0) begin
                rx_fsm_n = RX_RECOVER;
                baud_rst = 1'b1;
                rx_rdy_comb = 1'b1;
                rx_err_comb = 1'b1;
            end
        end

        RX_DATA: begin
            baud_rst = 1'b0;
            // Note: The baud timing is pahse shifted by half of the baud rate and
            // so we use `baud_half` as an indication of the end of the baud interval.
            if (baud_half) begin
                // Note: The `bit_cnt` resets automatically when transfering
                // from RX_DATA to RX_STOP.
                rx_fsm_n = (bit_cnt > ctrl_bits) ? RX_STOP : RX_DATA;
            end
        end

        RX_STOP: begin
            baud_rst = 1'b0;
            if (rxd != 1'b1) begin
                rx_fsm_n = RX_RECOVER;
                baud_rst = 1'b1;
                rx_rdy_comb = 1'b1;
                rx_err_comb = 1'b1;
            end
            else if (baud_full) begin
                if (bit_cnt >= ctrl_stops) begin
                    rx_fsm_n = RX_IDLE;
                    baud_rst = 1'b1;
                    rx_rdy_comb = 1'b1;
                    rx_err_comb = 1'b0;
                end
            end
        end

        RX_RECOVER: begin
            baud_rst = 1'b0;
            if (rxd != 1'b1) begin
                baud_rst = 1'b1;
            end
            else if (baud_full && bit_cnt >= ctrl_stops) begin
                rx_fsm_n = RX_IDLE;
                baud_rst = 1'b1;
            end
        end
    endcase
end


always_ff @(posedge clk) begin: p_bit_cnt
    if (baud_rst) begin
        bit_cnt <= 1;
    end
    else if (baud_full) begin
        if (rx_fsm_n == RX_STOP)
            bit_cnt <= 1;
        else
            bit_cnt <= bit_cnt + 1;
    end
end: p_bit_cnt

int rx_data_int;
always_ff @(posedge clk) begin: p_rx_data_int
    if (baud_rst) begin
        rx_data_int <= '0;
    end
    else if (baud_full && rx_fsm_q == RX_DATA) begin
        rx_data_int[bit_cnt-1] <= rxd; // LSB first
//        rx_data_int[ctrl_bits - bit_cnt] <= rxd; // MSB first
    end
end: p_rx_data_int


always_ff @(posedge clk or negedge rst_n) begin: p_rx_data
    if (!rst_n)
        rx_data <= 0;
    else if (rx_rdy_comb)
        rx_data <= rx_err_comb ? 0 : rx_data_int;
end: p_rx_data

endmodule: uart_model
