`timescale 1ns / 1ps

module vga_controller(
    input  CLK,
    output HS,
    output VS,
    output [9:0] x,
    output reg [9:0] y = 0,
    output blank
);
    reg [9:0] xc = 0;
    localparam H_VISIBLE=640, H_FP=16, H_SYNC=96, H_BP=48,  H_TOTAL=800;
    localparam V_VISIBLE=480, V_FP=10, V_SYNC=2,  V_BP=33,  V_TOTAL=525;

    assign blank = (xc >= H_VISIBLE) || (y >= V_VISIBLE);
    assign HS = ~((xc >= (H_VISIBLE + H_FP)) && (xc < (H_VISIBLE + H_FP + H_SYNC)));
    assign VS = ~((y  >= (V_VISIBLE + V_FP)) && (y  < (V_VISIBLE + V_FP + V_SYNC)));
    assign x  = xc;

    always @(posedge CLK) begin
        
        if (xc == H_TOTAL-1) begin
            xc <= 0;
            y  <= (y == V_TOTAL-1) ? 0 : (y + 1);
        end else begin
            xc <= xc + 1;
        end
    end

endmodule