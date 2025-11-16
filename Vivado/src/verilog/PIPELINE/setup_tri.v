`timescale 1ns/1ps

module setup_tri #(
    parameter integer DW_VERTEX = 64
)(
    input  wire              CLK,
    input  wire              rst,
    input  wire              ts_start,

    input  wire [15:0]       vp_width,
    input  wire [15:0]       vp_height,

    input  wire [DW_VERTEX-1:0] in_v0,
    input  wire [DW_VERTEX-1:0] in_v1,
    input  wire [DW_VERTEX-1:0] in_v2,
    
    output reg  [15:0]       x_min_out,
    output reg  [15:0]       x_max_out,
    output reg  [15:0]       y_min_out,
    output reg  [15:0]       y_max_out,

    output reg               ts_done,
    output reg               area_zero
);
    wire signed [15:0] v0_x16 = in_v0[63:48];
    wire signed [15:0] v0_y16 = in_v0[47:32];
    wire signed [15:0] v0_z16 = in_v0[31:16];

    wire signed [15:0] v1_x16 = in_v1[63:48];
    wire signed [15:0] v1_y16 = in_v1[47:32];
    wire signed [15:0] v1_z16 = in_v1[31:16];

    wire signed [15:0] v2_x16 = in_v2[63:48];
    wire signed [15:0] v2_y16 = in_v2[47:32];
    wire signed [15:0] v2_z16 = in_v2[31:16];

    wire signed [31:0] area;
    assign area = (v1_x16 - v0_x16) * (v2_y16 - v0_y16) -
                  (v1_y16 - v0_y16) * (v2_x16 - v0_x16);

    function signed [15:0] min3;
        input signed [15:0] a;
        input signed [15:0] b;
        input signed [15:0] c;
        begin
            min3 = (a < b) ? ((a < c) ? a : c)
                           : ((b < c) ? b : c);
        end
    endfunction

    function signed [15:0] max3;
        input signed [15:0] a;
        input signed [15:0] b;
        input signed [15:0] c;
        begin
            max3 = (a > b) ? ((a > c) ? a : c)
                           : ((b > c) ? b : c);
        end
    endfunction

    function [15:0] clamp3;
        input signed [15:0] a;
        input [15:0] lo;
        input [15:0] hi;
        begin
            clamp3 = (a < lo) ? lo :
                     (a > hi) ? hi : a;
        end
    endfunction

    wire signed [15:0] x_min_raw = min3(v0_x16, v1_x16, v2_x16);
    wire signed [15:0] x_max_raw = max3(v0_x16, v1_x16, v2_x16);
    wire signed [15:0] y_min_raw = min3(v0_y16, v1_y16, v2_y16);
    wire signed [15:0] y_max_raw = max3(v0_y16, v1_y16, v2_y16);

    wire [15:0] x_min_clamped;
    wire [15:0] x_max_clamped;
    wire [15:0] y_min_clamped;
    wire [15:0] y_max_clamped;

    assign x_min_clamped = clamp3(x_min_raw, 16'd0, vp_width  - 1);
    assign x_max_clamped = clamp3(x_max_raw, 16'd0, vp_width  - 1);
    assign y_min_clamped = clamp3(y_min_raw, 16'd0, vp_height - 1);
    assign y_max_clamped = clamp3(y_max_raw, 16'd0, vp_height - 1);

    always @(posedge CLK) begin
        if (rst) begin
            ts_done   <= 1'b0;
            area_zero <= 1'b0;
            x_min_out <= 16'd0;
            x_max_out <= 16'd0;
            y_min_out <= 16'd0;
            y_max_out <= 16'd0;
        end else begin
            ts_done <= 1'b0;

            if (ts_start) begin
                if (area == 0) begin
                    area_zero <= 1'b1;
                    x_min_out <= 16'd0;
                    x_max_out <= 16'd0;
                    y_min_out <= 16'd0;
                    y_max_out <= 16'd0;
                end else begin
                    area_zero <= 1'b0;
                    x_min_out <= x_min_clamped;
                    x_max_out <= x_max_clamped;
                    y_min_out <= y_min_clamped;
                    y_max_out <= y_max_clamped;
                end
                ts_done <= 1'b1;
            end
        end
    end

endmodule