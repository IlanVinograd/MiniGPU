`timescale 1ns / 1ps

module scanout_rgb332_scaled #(
    parameter H_SRC  = 256,
    parameter V_SRC  = 192,
    parameter ADDR_W = 17
)(
    input clk25,
    input [9:0] x,
    input [9:0] y,
    input blank,
    input [7:0] vram_q,
    input  [ADDR_W-1:0] BASE_ADDR,
    output [ADDR_W-1:0] vram_addr,
    output reg [3:0] RED = 0,
    output reg [3:0] GREEN = 0,
    output reg [3:0] BLUE  = 0
);
    localparam [23:0] STEP_X = 24'd26214;
    localparam [23:0] STEP_Y = 24'd26214;

    reg [23:0] sx_acc = 24'd0;
    reg [23:0] sy_acc = 24'd0;
    reg  [7:0] sx     = 8'd0;
    reg  [7:0] sy     = 8'd0;

    reg [9:0] y_line = 10'd0;

    always @(posedge clk25) begin
        if (x == 10'd0) begin
            y_line <= (y < 10'd480) ? y : 10'd479;

            if (y == 10'd0)       sy_acc <= 24'd0;
            else if (y < 10'd480) sy_acc <= sy_acc + STEP_Y;

            sx_acc <= 24'd0;
        end else if (x < 10'd640) begin
            sx_acc <= sx_acc + STEP_X;
        end

        sx <= sx_acc[23:16];
        sy <= sy_acc[23:16];
    end

    wire [15:0] src_off = {sy, 8'b0} + sx;

    reg  [ADDR_W-1:0] addr_r = {ADDR_W{1'b0}};
    always @(posedge clk25) begin
        addr_r <= BASE_ADDR + src_off;
    end
    assign vram_addr = addr_r;

    reg       blank_d  = 1'b1;
    reg [7:0] pixel_d  = 8'h00;

    wire [2:0] r = pixel_d[7:5];
    wire [2:0] g = pixel_d[4:2];
    wire [1:0] b = pixel_d[1:0];

    always @(posedge clk25) begin
        pixel_d <= vram_q;
        blank_d <= blank;

        if (blank_d) begin
            RED   <= 4'h0;
            GREEN <= 4'h0;
            BLUE  <= 4'h0;
        end else begin
            RED   <= {r, r[2]};
            GREEN <= {g, g[2]};
            BLUE  <= {b, b};
        end
    end

endmodule