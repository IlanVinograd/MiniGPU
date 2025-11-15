`timescale 1ns / 1ps

module gpu_uniforms #(
    parameter integer W = 32
)(
    input  wire CLK,
    input  wire rst,

    // input  wire        we,
    // input  wire [7:0]  addr,
    // input  wire [W-1:0] data,

    output reg [W-1:0] m00, m01, m02, m03,
    output reg [W-1:0] m10, m11, m12, m13,
    output reg [W-1:0] m20, m21, m22, m23,
    output reg [W-1:0] m30, m31, m32, m33,

    output reg [15:0]  vp_width,
    output reg [15:0]  vp_height
);
    always @(posedge CLK) begin
        if (rst) begin
            m00 <= /* 1.0 */ 32'h00010000;
            m11 <= /* 1.0 */ 32'h00010000;
            m22 <= /* 1.0 */ 32'h00010000;
            m33 <= /* 1.0 */ 32'h00010000;

            m01 <= 0; m02 <= 0; m03 <= 0;
            m10 <= 0; m12 <= 0; m13 <= 0;
            m20 <= 0; m21 <= 0; m23 <= 0;
            m30 <= 0; m31 <= 0; m32 <= 0;

            vp_width  <= 16'd320;
            vp_height <= 16'd240;
        end else begin
            // if (we) case (addr) ... new CMD
        end
    end
endmodule