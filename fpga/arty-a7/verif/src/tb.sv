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
    2018, Nov., Tomas Brabec
    - Created.
*/

`timescale 1ns/1ps

module tb #(
    parameter realtime TIMEOUT = 1000us
);

logic clk_100M;
logic ck_rst_n;

// Green LEDs
// (making "inout" for readback of the actual value through the GPIO interface)
wire [3:0] led;

// RGB LEDs, 3 pins each
// (making "inout" for readback of the actual value through the GPIO interface)
wire [2:0] r_led;
wire [2:0] g_led;
wire [2:0] b_led;

// Sliding switches.
logic[3:0] sw;

// Buttons.
logic[3:0] btn;

// Dedicated QSPI interface
logic        qspi_cs;
logic        qspi_sck;
wire[3:0]    qspi_dq;

// UART0 (connected to micro USB)
logic uart_rxd;
logic uart_txd;

assign uart_rxd = 1'b1;
assign qspi_dq = 'z;

arty_a7_shell dut(
    .*
);

if_uart_rx_notif ifc_uart_rxd();

sim_uart_rx #(
    .BAUDRATE( 115200 )
) u_uart_rxd (
    .rxd( uart_txd ),
    .notif( ifc_uart_rxd )
);

initial begin: p_time_fmt
    $timeformat(-9, 2, " ns", 20);
end: p_time_fmt


initial begin: p_clk
    clk_100M = 1'b0;

    while ($realtime < TIMEOUT) begin
        #(5ns);
        clk_100M = ~clk_100M;
    end
end: p_clk


initial begin: p_rst
    ck_rst_n = 1'b1;
    ck_rst_n = 1'b0;

    repeat(10) @(negedge clk_100M);
    ck_rst_n = 1'b1;
end: p_rst


always @(ifc_uart_rxd.rdy) begin: p_uart_rxd_notif
    if (ifc_uart_rxd.err) begin
        $warning("%0t: UART data recieved with error: data=%hh", $realtime, ifc_uart_rxd.data);
    end
    else begin
        $display("%0t: UART data recieved successfully: data=%hh", $realtime, ifc_uart_rxd.data);
    end
end: p_uart_rxd_notif

endmodule: tb
