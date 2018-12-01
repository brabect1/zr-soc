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

interface if_uart_rx_notif;
    event rdy;
    logic[7:0] data;
    logic err;
/*
    modport master (
        output rdy,
        output data,
        output err
    );
 */   
endinterface: if_uart_rx_notif


module sim_uart_rx #(
    parameter int BAUDRATE = 115200
)(
    input logic rxd,
    if_uart_rx_notif notif
);

initial begin: p_rcv
    realtime t_baud;
    logic [7:0] data;

    t_baud = 1s / BAUDRATE;

    // wait for line become high
    if (rxd != 1'b1) @(posedge rxd);

    // receive loop
    while (1) begin: rcv_loop
        // start bit
        if (rxd != 1'b0) begin
            @(negedge rxd);
        end

        fork
            #t_baud;
            @(posedge rxd);
        join_any
        disable fork;

        if (rxd != 1'b0) begin
            notif.err = 1'b1;
            -> notif.rdy;
            continue;
        end

        // 8 data bits
        // (sample data in the middle of the baud period)
        data = 'x;
        #(t_baud/2);
        for (int i=0; i<8; i++) begin
            data[i] = rxd;
            #t_baud;
        end

        // stop bit
        if (rxd != 1'b1) begin
            notif.err = 1'b1;
            notif.data = data;
            -> notif.rdy;

            // wait for a line become idle for one baud period
            while (1) begin
                @(posedge rxd);
                fork
                    #t_baud;
                    @(negedge rxd);
                join_any
                disable fork;
                if (rxd == 1'b1) break;
            end
            continue;
        end
        else begin
            realtime tstamp;

            // wait for the end of the baud period
            tstamp = $realtime;
            fork
                #(t_baud/2);
                @(negedge rxd);
            join_any
            disable fork;

            // notify data reception
            notif.err = (($realtime - tstamp) == (t_baud/2));
            notif.data = data;
            -> notif.rdy;
        end
    end: rcv_loop
end: p_rcv

endmodule: sim_uart_rx
