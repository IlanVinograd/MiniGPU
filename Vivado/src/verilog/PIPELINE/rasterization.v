`timescale 1ns/1ps

module rasterization #(
    parameter integer SIZE     = 49_152,
    parameter integer ADDR_W   = $clog2(SIZE),
    parameter integer DW_VERTEX = 64
)(
    input  wire              CLK,
    input  wire              rst,
    input  wire              rt_start,

    input  wire [15:0]       x_min_in,
    input  wire [15:0]       x_max_in,
    input  wire [15:0]       y_min_in,
    input  wire [15:0]       y_max_in,

    input  wire [DW_VERTEX-1:0] in_v0,
    input  wire [DW_VERTEX-1:0] in_v1,
    input  wire [DW_VERTEX-1:0] in_v2,

    input  wire [15:0]       vp_width,

    output reg  [ADDR_W-1:0] addr_vram,
    output reg  [7:0]       data_vram,
    output reg               we_vram,

    output reg  [ADDR_W-1:0] addr_z,
    output reg  [15:0]       data_z,
    output reg               we_z,

    output reg               rt_done
);
    wire [15:0] v0_x = in_v0[63:48];
    wire [15:0] v0_y = in_v0[47:32];
    wire [15:0] v0_z = in_v0[31:16];
    wire [7:0]  v0_col = in_v0[15:8];

    wire [15:0] v1_x = in_v1[63:48];
    wire [15:0] v1_y = in_v1[47:32];
    wire [15:0] v1_z = in_v1[31:16];
    wire [7:0]  v1_col = in_v1[15:8];

    wire [15:0] v2_x = in_v2[63:48];
    wire [15:0] v2_y = in_v2[47:32];
    wire [15:0] v2_z = in_v2[31:16];
    wire [7:0]  v2_col = in_v2[15:8];

    reg [15:0] x_min, x_max, y_min, y_max;

    reg [15:0] cur_x, cur_y;

    localparam [1:0]
        RT_IDLE = 2'd0,
        RT_RUN  = 2'd1,
        RT_DONE = 2'd2;

    reg [1:0] state;

    wire signed [31:0] E0;
    wire signed [31:0] E1;
    wire signed [31:0] E2;

    assign E0 =
        ( $signed(cur_x) - $signed(v0_x) ) * ( $signed(v1_y) - $signed(v0_y) ) -
        ( $signed(cur_y) - $signed(v0_y) ) * ( $signed(v1_x) - $signed(v0_x) );

    assign E1 =
        ( $signed(cur_x) - $signed(v1_x) ) * ( $signed(v2_y) - $signed(v1_y) ) -
        ( $signed(cur_y) - $signed(v1_y) ) * ( $signed(v2_x) - $signed(v1_x) );

    assign E2 =
        ( $signed(cur_x) - $signed(v2_x) ) * ( $signed(v0_y) - $signed(v2_y) ) -
        ( $signed(cur_y) - $signed(v2_y) ) * ( $signed(v0_x) - $signed(v2_x) );

    wire inside = (E0 >= 0 && E1 >= 0 && E2 >= 0);

    wire [31:0] addr_lin = ( $unsigned(cur_y) * $unsigned(vp_width) ) + $unsigned(cur_x);

    always @(posedge CLK) begin
        if (rst) begin
            state     <= RT_IDLE;
            rt_done   <= 1'b0;
            we_vram   <= 1'b0;
            we_z      <= 1'b0;
            addr_vram <= {ADDR_W{1'b0}};
            data_vram <= 16'd0;
            addr_z    <= {ADDR_W{1'b0}};
            data_z    <= 16'd0;
            x_min     <= 16'd0;
            x_max     <= 16'd0;
            y_min     <= 16'd0;
            y_max     <= 16'd0;
            cur_x     <= 16'd0;
            cur_y     <= 16'd0;
        end else begin
            we_vram <= 1'b0;
            we_z    <= 1'b0;
            rt_done <= 1'b0;

            case (state)
                RT_IDLE: begin
                    if (rt_start) begin
                        x_min <= x_min_in;
                        x_max <= x_max_in;
                        y_min <= y_min_in;
                        y_max <= y_max_in;

                        cur_x <= x_min_in;
                        cur_y <= y_min_in;

                        state <= RT_RUN;
                    end
                end

                RT_RUN: begin
                    addr_vram <= addr_lin[ADDR_W-1:0];
                    addr_z    <= addr_lin[ADDR_W-1:0];

                    if (inside) begin
                        we_vram   <= 1'b1;
                        data_vram <= v0_col; // stub for color v0 color
                        // here Z buffer check will be.
                    end

                    if (cur_x < x_max) begin
                        cur_x <= cur_x + 1'b1;
                    end else begin
                        cur_x <= x_min;
                        if (cur_y < y_max) begin
                            cur_y <= cur_y + 1'b1;
                        end else begin
                            state   <= RT_DONE;
                        end
                    end
                end

                RT_DONE: begin
                    rt_done <= 1'b1;
                    state   <= RT_IDLE;
                end

                default: state <= RT_IDLE;
            endcase
        end
    end

endmodule