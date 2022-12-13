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
    inout vccd1,	// User area 1 1.8V supply
    inout vssd1,	// User area 1 digital ground
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
    assign valid = wbs_cyc_i && wbs_stb_i; 
    assign wstrb = wbs_sel_i & {4{wbs_we_i}};
    assign wdata = wbs_dat_i;

    // IO
    assign io_out = count;
    // assign io_oeb = {(`MPRJ_IO_PADS-1){rst}};

    // IRQ
    // assign irq = 3'b000;	// Unused

    // PIO registers and wires
    reg [31:0]  din;        // Data sent to PIO
    reg [4:0]   index;      // Instruction index
    reg [1:0]   mindex;     // Machine index

    reg [31:0] dout;       // Output from PIO
    wire [3:0]   action;     // Action to be done by PIO
    wire        irq0, irq1; // IRQ flags from PIO
    wire [3:0]  tx_full;    // Set when TX fifo is full  
    wire [3:0]  rx_empty;   // Set when RX fifo is empty

    // // LA
    // assign la_data_out = {{(127-BITS){1'b0}}, count};
    // // Assuming LA probes [63:32] are for controlling the count register  
    // assign la_write = ~la_oenb[63:32] & ~{BITS{valid}};
    // // Assuming LA probes [65:64] are for controlling the count clk & reset  
    // assign clk = (~la_oenb[64]) ? la_data_in[64]: wb_clk_i;
    // assign rst = (~la_oenb[65]) ? la_data_in[65]: wb_rst_i;

    // counter #(
    //     .BITS(BITS)
    // ) counter(
    //     .clk(clk),
    //     .reset(rst),
    //     .ready(wbs_ack_o),
    //     .valid(valid),
    //     .rdata(rdata),
    //     .wdata(wbs_dat_i),
    //     .wstrb(wstrb),
    //     .la_write(la_write),
    //     .la_input(la_data_in[63:32]),
    //     .count(count)
    // );

    assign irq[2] = 1'b0;

    reg [3:0] actions[32];
    reg [4:0] pc;
    assign action = actions[pc];
    // assign action = actions[0];
    reg ack;
    assign wbs_ack_o = ack;
    assign wbs_dat_o = dout;

    always @(posedge wb_clk_i) begin
        if (wb_rst_i) begin
            ack <= 1'b0;
            pc <= 5'b00000;
        end else begin
            ack <= 1'b0;
            pc <= pc + 1;
            if (valid && !ack) begin
                ack <= 1'b1;
                if ((wbs_adr_i[3:0] == 0) && wbs_we_i) begin
                    if (wstrb[0]) din[7:0]   <= wbs_dat_i[7:0];
                    if (wstrb[1]) din[15:8]  <= wbs_dat_i[15:8];
                    if (wstrb[2]) din[23:16] <= wbs_dat_i[23:16];
                    if (wstrb[3]) din[31:24] <= wbs_dat_i[31:24];
                end else if ((wbs_adr_i[3:0] == 4) && wbs_we_i) begin
                    if (wstrb[0]) mindex[1:0]   <= wbs_dat_i[1:0];
                end else if ((wbs_adr_i[3:0] == 8) && wbs_we_i) begin
                    if (wstrb[0]) index[4:0]   <= wbs_dat_i[4:0];
                end else if ((wbs_adr_i[3:0] == 12) && wbs_we_i) begin
                    if (wstrb[0]) actions[pc][3:0]   <= wbs_dat_i[3:0];
                // end else if ((wbs_adr_i[3:0] == 16) && !wbs_we_i) begin
                    // if (wstrb[0]) wbs_dat_o[7:0] <= dout[7:0];
                    // if (wstrb[1]) wbs_dat_o[15:8] <= dout[15:8];
                    // if (wstrb[2]) wbs_dat_o[23:16] <= dout[23:16];
                    // if (wstrb[3]) wbs_dat_o[31:24] <= dout[31:24];
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

// module counter #(
//     parameter BITS = 32
// )(
//     input clk,
//     input reset,
//     input valid,
//     input [3:0] wstrb,
//     input [BITS-1:0] wdata,
//     input [BITS-1:0] la_write,
//     input [BITS-1:0] la_input,
//     output ready,
//     output [BITS-1:0] rdata,
//     output [BITS-1:0] count
// );
//     reg ready;
//     reg [BITS-1:0] count;
//     reg [BITS-1:0] rdata;

//     always @(posedge clk) begin
//         if (reset) begin
//             count <= 0;
//             ready <= 0;
//         end else begin
//             ready <= 1'b0;
//             if (~|la_write) begin
//                 count <= count + 1;
//             end
//             if (valid && !ready) begin
//                 ready <= 1'b1;
//                 rdata <= count;
//                 if (wstrb[0]) count[7:0]   <= wdata[7:0];
//                 if (wstrb[1]) count[15:8]  <= wdata[15:8];
//                 if (wstrb[2]) count[23:16] <= wdata[23:16];
//                 if (wstrb[3]) count[31:24] <= wdata[31:24];
//             end else if (|la_write) begin
//                 count <= la_write & la_input;
//             end
//         end
//     end

// endmodule
`default_nettype wire
