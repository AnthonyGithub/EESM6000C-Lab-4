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

module user_proj_example #(
    parameter BITS = 32,
    parameter DELAYS=10
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

    reg  [31:0] delays_count;
    
    wire [3:0]  bram_we;
    wire        bram_en;

    assign clk = wb_clk_i ;
    assign rst = wb_rst_i;
    
    always @(posedge clk) begin
        if (rst) begin
            delays_count[31:0] <= 32'b0;
        end else begin
            if (bram_en) begin
                if (delays_count[31:0] != DELAYS) begin
                    delays_count[31:0] <= delays_count[31:0] + 32'b1;
                end else begin
                    delays_count[31:0] <= 32'b0;
                end
            end
        end
    end
    
    assign wbs_ack_o = delays_count[31:0] == DELAYS;
    
    assign bram_we[3:0] = {4{wbs_we_i}} & wbs_sel_i[3:0]                   ;
    assign bram_en      = wbs_stb_i & wbs_cyc_i & wbs_adr_i[31:24] == 8'h38;

    bram user_bram (
        .CLK(clk            ),
        .WE0(bram_we[3:0]   ),
        .EN0(bram_en        ),
        .Di0(wbs_dat_i[31:0]),
        .Do0(wbs_dat_o[31:0]),
        .A0 (wbs_adr_i[31:0])
    );

endmodule



`default_nettype wire
