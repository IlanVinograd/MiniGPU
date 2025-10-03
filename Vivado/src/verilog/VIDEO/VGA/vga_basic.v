`timescale 1ns / 1ps

module vga_basic #(
    parameter ADDR_W = 17
)(
    input  CLK,
    input  [ADDR_W-1:0] BASE_ADDR,
    output HS,
    output VS,
    output [3:0] RED,
    output [3:0] GREEN,
    output [3:0] BLUE
);

    wire clk25, locked;
    clk_wiz_0 clkgen (
        .clk_in1 (CLK),
        .reset   (1'b0),
        .clk_out1(clk25),
        .locked  (locked)
    );

    wire [9:0] x, y;
    wire blank;
    wire [7:0] vram_q;
    wire [16:0] vram_addr;

    vga_controller v(.CLK(clk25), .HS(HS), .VS(VS), .x(x), .y(y), .blank(blank));

    scanout_rgb scan(
        .clk25(clk25), .x(x), .y(y), .blank(blank),
        .vram_q(vram_q), .vram_addr(vram_addr), .BASE_ADDR(BASE_ADDR),
        .RED(RED), .GREEN(GREEN), .BLUE(BLUE)
    );


    vram_dual_clock #(.TOTAL_BYTES(98304)) vram (
        .CLK_A (clk25),
        .DATA_A(8'h00),
        .ADDR_A({1'b0, vram_addr}),
        .WE_A  (1'b0),
        .Q_A   (vram_q),

        .CLK_B (CLK),
        .DATA_B(8'h00),
        .ADDR_B(18'd0),
        .WE_B  (1'b0),
        .Q_B   ()
    );


endmodule