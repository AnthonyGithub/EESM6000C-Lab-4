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
    parameter DELAYS=10,
    parameter pADDR_WIDTH  = 12,
    parameter pDATA_WIDTH  = 32,
    parameter pDATA_LENGTH = 64,
    parameter pTAP_NUM     = 11
)(
`ifdef USE_POWER_PINS
    inout vccd1,	// User area 1 1.8V supply
    inout vssd1,	// User area 1 digital ground
`endif

    // Wishbone Slave ports (WB MI A)
    input wire wb_clk_i,
    input wire wb_rst_i,
    input wire wbs_stb_i,
    input wire wbs_cyc_i,
    input wire wbs_we_i,
    input wire [3:0] wbs_sel_i,
    input wire [31:0] wbs_dat_i,
    input wire [31:0] wbs_adr_i,
    output wire wbs_ack_o,
    output wire [31:0] wbs_dat_o,

    // Logic Analyzer Signals
    input  wire [127:0] la_data_in,
    output wire [127:0] la_data_out,
    input  wire [127:0] la_oenb,

    // IOs
    input  wire [`MPRJ_IO_PADS-1:0] io_in,
    output wire [`MPRJ_IO_PADS-1:0] io_out,
    output wire [`MPRJ_IO_PADS-1:0] io_oeb,

    // IRQ
    output wire [2:0] irq
);
    wire clk;
    wire rst;

    //wire [`MPRJ_IO_PADS-1:0] io_in;
    //wire [`MPRJ_IO_PADS-1:0] io_out;
    //wire [`MPRJ_IO_PADS-1:0] io_oeb;
    
    // AXI
    wire                     awready   ;
    wire                     wready    ;
    wire                     awvalid   ;
    wire [(pADDR_WIDTH-1):0] awaddr    ;
    wire                     wvalid    ;
    wire [(pDATA_WIDTH-1):0] wdata     ;
    wire                     arready   ;
    wire                     rready    ;
    wire                     arvalid   ;
    wire [(pADDR_WIDTH-1):0] araddr    ;
    wire                     rvalid    ;
    wire [(pDATA_WIDTH-1):0] rdata     ;
    wire                     ss_tvalid ;
    wire [(pDATA_WIDTH-1):0] ss_tdata  ;
    wire                     ss_tlast  ;
    wire                     ss_tready ;
    wire                     sm_tready ;
    wire                     sm_tvalid ;
    wire [(pDATA_WIDTH-1):0] sm_tdata  ;
    wire                     sm_tlast  ;
    
    // bram for tap RAM
    wire [3:0]               tap_WE    ;
    wire                     tap_EN    ;
    wire [(pDATA_WIDTH-1):0] tap_Di    ;
    wire [(pADDR_WIDTH-1):0] tap_A     ;
    wire [(pDATA_WIDTH-1):0] tap_Do    ;

    // bram for data RAM
    wire [3:0]               data_WE   ;
    wire                     data_EN   ;
    wire [(pDATA_WIDTH-1):0] data_Di   ;
    wire [(pADDR_WIDTH-1):0] data_A    ;
    wire [(pDATA_WIDTH-1):0] data_Do   ;

    wire                     axis_clk  ;
    wire                     axis_rst_n;

    wire                     fir_en    ;

    wire                     axilite_en     ;
    wire [31:0]              axilite_adr    ;
    reg                      axilite_awready;
    reg                      axilite_wready ;
    reg                      axilite_arready;

    wire                     axistream_x    ;
    wire                     axistream_y    ;
    reg  [31:0]              axistream_count;
    
    wire                     exmem_en    ;
    wire [3:0]               exmem_we    ;
    wire [31:0]              exmem_adr   ;
    wire [31:0]              exmem_dat_o ;
    reg  [31:0]              delays_count;

    assign axis_clk   = wb_clk_i ;
    assign axis_rst_n = ~wb_rst_i;

    fir #(.pADDR_WIDTH(pADDR_WIDTH), .pDATA_WIDTH(pDATA_WIDTH), .Tape_Num(pTAP_NUM)) fir_DUT(
        .awready(awready),
        .wready(wready),
        .awvalid(awvalid),
        .awaddr(awaddr),
        .wvalid(wvalid),
        .wdata(wdata),
        .arready(arready),
        .rready(rready),
        .arvalid(arvalid),
        .araddr(araddr),
        .rvalid(rvalid),
        .rdata(rdata),
        .ss_tvalid(ss_tvalid),
        .ss_tdata(ss_tdata),
        .ss_tlast(ss_tlast),
        .ss_tready(ss_tready),
        .sm_tready(sm_tready),
        .sm_tvalid(sm_tvalid),
        .sm_tdata(sm_tdata),
        .sm_tlast(sm_tlast),

        // ram for tap
        .tap_WE(tap_WE),
        .tap_EN(tap_EN),
        .tap_Di(tap_Di),
        .tap_A(tap_A),
        .tap_Do(tap_Do),

        // ram for data
        .data_WE(data_WE),
        .data_EN(data_EN),
        .data_Di(data_Di),
        .data_A(data_A),
        .data_Do(data_Do),

        .axis_clk(axis_clk),
        .axis_rst_n(axis_rst_n)
    );

    // RAM for tap
    //bram11 tap_RAM (
    //    .CLK(axis_clk),
    //    .WE(tap_WE),
    //    .EN(tap_EN),
    //    .Di(tap_Di),
    //    .A(tap_A),
    //    .Do(tap_Do)
    //);

    // RAM for data: choose bram11 or bram12
    //bram11 data_RAM(
    //    .CLK(axis_clk),
    //    .WE(data_WE),
    //    .EN(data_EN),
    //    .Di(data_Di),
    //    .A(data_A),
    //    .Do(data_Do)
    //);

    // RAM for tap
    bram11 tap_RAM (
        .clk  (axis_clk                 ),
        .we   (tap_WE[0]                ),
        .re   (tap_EN                   ),
        .waddr(tap_A[(pADDR_WIDTH-1):0] ),
        .raddr(tap_A[(pADDR_WIDTH-1):0] ),
        .wdi  (tap_Di[(pDATA_WIDTH-1):0]),
        .rdo  (tap_Do[(pDATA_WIDTH-1):0])
    );

    // RAM for data
    bram11 data_RAM(
        .clk  (axis_clk                  ),
        .we   (data_WE[0]                ),
        .re   (data_EN                   ),
        .waddr(data_A[(pADDR_WIDTH-1):0] ),
        .raddr(data_A[(pADDR_WIDTH-1):0] ),
        .wdi  (data_Di[(pDATA_WIDTH-1):0]),
        .rdo  (data_Do[(pDATA_WIDTH-1):0])
    );

    assign fir_en = wbs_stb_i & wbs_cyc_i & (wbs_adr_i[31:24] == 8'h30);
    
    // AXI-Lite
    assign axilite_en        = fir_en & ~((wbs_adr_i[6:0] >= 7'h40) & (wbs_adr_i[6:0] <= 7'h47));
    assign axilite_adr[31:0] = wbs_adr_i[31:0] - 32'h30000000                                   ;

    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            axilite_awready <= 1'b0;
            axilite_wready  <= 1'b0;
            axilite_arready <= 1'b0;
        end else begin
            if (wbs_ack_o) begin
                axilite_awready <= 1'b0;
                axilite_wready  <= 1'b0;
                axilite_arready <= 1'b0;
            end else begin
                axilite_awready <= awready | axilite_awready;
                axilite_wready  <= wready  | axilite_wready ;
                axilite_arready <= arready | axilite_arready;
            end
        end
    end
    
    assign awvalid                   = axilite_en &  wbs_we_i & ~axilite_awready;
    assign awaddr[(pADDR_WIDTH-1):0] = axilite_adr[(pADDR_WIDTH-1):0]           ;
    
    assign wvalid                    = axilite_en &  wbs_we_i & ~axilite_wready ;
    assign wdata[(pDATA_WIDTH-1):0]  = wbs_dat_i[(pDATA_WIDTH-1):0]             ;
    
    assign arvalid                   = axilite_en & ~wbs_we_i & ~axilite_arready;
    assign araddr[(pADDR_WIDTH-1):0] = axilite_adr[(pADDR_WIDTH-1):0]           ;
    
    assign rready                    = axilite_en & ~wbs_we_i                   ;

    // AXI-Stream
    assign axistream_x = fir_en & (wbs_adr_i[6:0] == 7'h40);
    assign axistream_y = fir_en & (wbs_adr_i[6:0] == 7'h44);
    
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            axistream_count[31:0] <= 32'b0;
        end else begin
            if (axistream_x & wbs_ack_o) begin
                axistream_count[31:0] <= axistream_count[31:0] + 32'b1;
            end else begin
                axistream_count[31:0] <= axistream_count[31:0];
            end
        end
    end
    
    assign ss_tvalid                   = axistream_x &  wbs_we_i                                ;
    assign ss_tdata[(pDATA_WIDTH-1):0] = wbs_dat_i[(pDATA_WIDTH-1):0]                           ;
    assign ss_tlast                    = ss_tvalid & (axistream_count[31:0] == pDATA_LENGTH - 1);

    assign sm_tready                   = axistream_y & ~wbs_we_i                                ;


    // EXMEM
    assign exmem_en        = wbs_stb_i & wbs_cyc_i & (wbs_adr_i[31:24] == 8'h38);
    assign exmem_we[3:0]   = {4{wbs_we_i}} & wbs_sel_i[3:0]                     ;
    assign exmem_adr[31:0] = wbs_adr_i[31:0] - 32'h38000000                     ;

    always @(posedge wb_clk_i) begin
        if (wb_rst_i) begin
            delays_count[31:0] <= 32'b0;
        end else begin
            if (exmem_en) begin
                if (delays_count[31:0] != DELAYS) begin
                    delays_count[31:0] <= delays_count[31:0] + 32'b1;
                end else begin
                    delays_count[31:0] <= 32'b0;
                end
            end
        end
    end

    bram user_bram (
        .CLK(wb_clk_i         ),
        .WE0(exmem_we[3:0]    ),
        .EN0(exmem_en         ),
        .Di0(wbs_dat_i[31:0]  ),
        .Do0(exmem_dat_o[31:0]),
        .A0 (exmem_adr[31:0]  )
    );


    // Output
    assign wbs_ack_o = axilite_awready & axilite_wready |
                       rready          & rvalid         |
                       ss_tvalid       & ss_tready      |
                       sm_tready       & sm_tvalid      |
                       (delays_count[31:0] == DELAYS)   ;
    
    assign wbs_dat_o[31:0] = {32{axilite_en }} & rdata[31:0]      |
                             {32{axistream_y}} & sm_tdata[31:0]   |
                             {32{exmem_en   }} & exmem_dat_o[31:0];

endmodule



`default_nettype wire
