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
    output [3:0] BLUE,
    output clk25,
    output [16:0] vram_addr,
    input  [7:0]  vram_q
);

    wire locked;
    clk_wiz_0 clkgen (
        .clk_in1 (CLK),
        .reset   (1'b0),
        .clk_out1(clk25),
        .locked  (locked)
    );

    wire [9:0] x, y;
    wire blank;

    vga_controller v(.CLK(clk25), .HS(HS), .VS(VS), .x(x), .y(y), .blank(blank));

    scanout_rgb scan(
        .clk25(clk25), .x(x), .y(y), .blank(blank),
        .vram_q(vram_q), .vram_addr(vram_addr), .BASE_ADDR(BASE_ADDR),
        .RED(RED), .GREEN(GREEN), .BLUE(BLUE)
    );
    
endmodule