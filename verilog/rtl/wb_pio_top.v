// SPDX-FileCopyrightText: 2020 Efabless Corporation
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// SPDX-License-Identifier: Apache-2.0

`default_nettype none
/*
 *-------------------------------------------------------------
 *
 * user_proj_example
 *
 * This is an example of a (trivially simple) user project,
 * showing how the user project can connect to the logic
 * analyzer, the wishbone bus, and the I/O pads.
 *
 * This project generates an integer count, which is output
 * on the user area GPIO pads (digital output only).  The
 * wishbone connection allows the project to be controlled
 * (start and stop) from the management SoC program.
 *
 * See the testbenches in directory "mprj_counter" for the
 * example programs that drive this user project.  The three
 * testbenches are "io_ports", "la_test1", and "la_test2".
 *
 *-------------------------------------------------------------
 */

module wb_pio #(
    parameter BITS = 32
)(
`ifdef USE_POWER_PINS
    // SKY130
    inout vccd1,	// User area 1 1.8V supply
    inout vssd1,	// User area 1 digital ground
    inout vdda1,	// User area 1 3.3V supply
    inout vssa2,	// User area 2 analog ground
    inout vdda2,	// User area 2 3.3V supply
    inout vssd2,	// User area 2 digital ground
    // GF180
    inout vdd,	    // User area 1 1.8V supply
    inout vss,    	// User area 1 digital ground
`endif

    // Wishbone Slave ports (WB MI A)
    input wb_clk_i,
    input wb_rst_i,
    input wbs_stb_i,
    input wbs_cyc_i,
    input wbs_we_i,
    input [3:0] wbs_sel_i,
    input [31:0] wbs_dat_i,
    input [31:0] wbs_adr_i,
    output wbs_ack_o,
    output [31:0] wbs_dat_o,

    // Logic Analyzer Signals
    input  [127:0] la_data_in,
    output [127:0] la_data_out,
    input  [127:0] la_oenb,

    // IOs
    input  [`MPRJ_IO_PADS-1:0] io_in,
    output [`MPRJ_IO_PADS-1:0] io_out,
    output [`MPRJ_IO_PADS-1:0] io_oeb,

    // IRQ
    output [2:0] irq
);
    wire clk;
    wire rst;

    wire [`MPRJ_IO_PADS-1:0] io_in;
    wire [`MPRJ_IO_PADS-1:0] io_out;
    wire [`MPRJ_IO_PADS-1:0] io_oeb;

    wire [31:0] wdata;
    wire [BITS-1:0] count;

    wire valid;
    wire [3:0] wstrb;
    wire [31:0] la_write;

    // WB MI A
    assign valid = wbs_cyc_i && wbs_stb_i && wbs_adr_i[31:16] == 16'h761c;
    assign wstrb = wbs_sel_i & {4{wbs_we_i}};
    assign wdata = wbs_dat_i;

    // IO
    assign io_out = count;

    // PIO registers and wires
    reg [31:0]  din;        // Data sent to PIO
    reg [4:0]   index;      // Instruction index
    reg [1:0]   mindex;     // Machine index

    reg [31:0]  dout;       // Output from PIO
    wire [3:0]  action;     // Action to be done by PIO
    wire        irq0, irq1; // IRQ flags from PIO
    wire [3:0]  tx_full;    // Set when TX fifo is full  
    wire [3:0]  rx_empty;   // Set when RX fifo is empty

    assign irq[2] = 1'b0;

    reg ack;
    assign wbs_ack_o = ack;
    assign wbs_dat_o = dout;

    always @(posedge wb_clk_i) begin
        if (wb_rst_i) begin
            ack <= 1'b0;
        end else begin
            ack <= 1'b0;
            if (valid && !ack) begin
                ack <= 1'b1;
                if (wbs_we_i) begin
                    action[3:0] <= wbs_adr_i[5:2];
                    if (wbs_we_i) begin
                        if (wstrb[0]) din[7:0]   <= wbs_dat_i[7:0];
                        if (wstrb[1]) din[15:8]  <= wbs_dat_i[15:8];
                        if (wstrb[2]) din[23:16] <= wbs_dat_i[23:16];
                        if (wstrb[3]) din[31:24] <= wbs_dat_i[31:24];
                    end else begin
                        if (wstrb[0]) wbs_dat_o[7:0] <= dout[7:0];
                        if (wstrb[1]) wbs_dat_o[15:8] <= dout[15:8];
                        if (wstrb[2]) wbs_dat_o[23:16] <= dout[23:16];
                        if (wstrb[3]) wbs_dat_o[31:24] <= dout[31:24];
                    end
                end else begin
                    // When there is no action, set the action to `NONE`
                    action[3:0] <= 4'b0000;
                end
            end
        end
    end

    // PIO instance 1
    pio pio_1 (
        .clk(wb_clk_i),
        .reset(wb_rst_i),

        .mindex(mindex),
        .din(din),
        .index(index),
        .action(action),
        .dout(dout),

        .gpio_in(io_in),
        .gpio_out(io_out),
        .gpio_dir(io_oeb),
        .irq0(irq[0]),
        .irq1(irq[1]),

        .tx_full(tx_full),
        .rx_empty(rx_empty)
    );
endmodule

`default_nettype wire
