`timescale 1ns / 1ps

module vertex_transform #(
    parameter integer DW_VERTEX = 64,
    parameter integer MW        = 32
)(
    input  wire CLK,
    input  wire rst,

    input  wire                 start,
    input  wire [DW_VERTEX-1:0] in_v0,
    input  wire [DW_VERTEX-1:0] in_v1,
    input  wire [DW_VERTEX-1:0] in_v2,

    input  wire [MW-1:0] m00, m01, m02, m03,
    input  wire [MW-1:0] m10, m11, m12, m13,
    input  wire [MW-1:0] m20, m21, m22, m23,
    input  wire [MW-1:0] m30, m31, m32, m33,

    input  wire [15:0]   vp_width,
    input  wire [15:0]   vp_height,

    output reg [DW_VERTEX-1:0] out_v0,
    output reg [DW_VERTEX-1:0] out_v1,
    output reg [DW_VERTEX-1:0] out_v2,
    output reg                 done
);

    localparam signed [31:0] ONE = 32'sh0001_0000;

    wire signed [15:0] v0_x16 = in_v0[63:48];
    wire signed [15:0] v0_y16 = in_v0[47:32];
    wire signed [15:0] v0_z16 = in_v0[31:16];
    wire        [7:0]  v0_col = in_v0[15:8];
    wire        [3:0]  v0_pad = in_v0[7:4];
    wire        [3:0]  v0_uv  = in_v0[3:0];

    wire signed [15:0] v1_x16 = in_v1[63:48];
    wire signed [15:0] v1_y16 = in_v1[47:32];
    wire signed [15:0] v1_z16 = in_v1[31:16];
    wire        [7:0]  v1_col = in_v1[15:8];
    wire        [3:0]  v1_pad = in_v1[7:4];
    wire        [3:0]  v1_uv  = in_v1[3:0];

    wire signed [15:0] v2_x16 = in_v2[63:48];
    wire signed [15:0] v2_y16 = in_v2[47:32];
    wire signed [15:0] v2_z16 = in_v2[31:16];
    wire        [7:0]  v2_col = in_v2[15:8];
    wire        [3:0]  v2_pad = in_v2[7:4];
    wire        [3:0]  v2_uv  = in_v2[3:0];

    wire signed [31:0] v0_x = {{16{v0_x16[15]}}, v0_x16};
    wire signed [31:0] v0_y = {{16{v0_y16[15]}}, v0_y16};
    wire signed [31:0] v0_z = {{16{v0_z16[15]}}, v0_z16};

    wire signed [31:0] v1_x = {{16{v1_x16[15]}}, v1_x16};
    wire signed [31:0] v1_y = {{16{v1_y16[15]}}, v1_y16};
    wire signed [31:0] v1_z = {{16{v1_z16[15]}}, v1_z16};

    wire signed [31:0] v2_x = {{16{v2_x16[15]}}, v2_x16};
    wire signed [31:0] v2_y = {{16{v2_y16[15]}}, v2_y16};
    wire signed [31:0] v2_z = {{16{v2_z16[15]}}, v2_z16};

    wire signed [31:0] sm00 = m00, sm01 = m01, sm02 = m02, sm03 = m03;
    wire signed [31:0] sm10 = m10, sm11 = m11, sm12 = m12, sm13 = m13;
    wire signed [31:0] sm20 = m20, sm21 = m21, sm22 = m22, sm23 = m23;
    wire signed [31:0] sm30 = m30, sm31 = m31, sm32 = m32, sm33 = m33;

    wire [31:0] vpw32 = {16'd0, vp_width};
    wire [31:0] vph32 = {16'd0, vp_height};

    wire signed [63:0] v0_x_t0  = $signed(sm00) * $signed(v0_x);
    wire signed [63:0] v0_x_t1  = $signed(sm01) * $signed(v0_y);
    wire signed [63:0] v0_x_t2  = $signed(sm02) * $signed(v0_z);
    wire signed [63:0] v0_x_sum = v0_x_t0 + v0_x_t1 + v0_x_t2 + {{32{sm03[31]}}, sm03};

    wire signed [63:0] v0_y_t0  = $signed(sm10) * $signed(v0_x);
    wire signed [63:0] v0_y_t1  = $signed(sm11) * $signed(v0_y);
    wire signed [63:0] v0_y_t2  = $signed(sm12) * $signed(v0_z);
    wire signed [63:0] v0_y_sum = v0_y_t0 + v0_y_t1 + v0_y_t2 + {{32{sm13[31]}}, sm13};

    wire signed [63:0] v0_z_t0  = $signed(sm20) * $signed(v0_x);
    wire signed [63:0] v0_z_t1  = $signed(sm21) * $signed(v0_y);
    wire signed [63:0] v0_z_t2  = $signed(sm22) * $signed(v0_z);
    wire signed [63:0] v0_z_sum = v0_z_t0 + v0_z_t1 + v0_z_t2 + {{32{sm23[31]}}, sm23};

    wire signed [63:0] v0_w_t0  = $signed(sm30) * $signed(v0_x);
    wire signed [63:0] v0_w_t1  = $signed(sm31) * $signed(v0_y);
    wire signed [63:0] v0_w_t2  = $signed(sm32) * $signed(v0_z);
    wire signed [63:0] v0_w_sum = v0_w_t0 + v0_w_t1 + v0_w_t2 + {{32{sm33[31]}}, sm33};

    wire signed [31:0] v0_clip_x = v0_x_sum[47:16];
    wire signed [31:0] v0_clip_y = v0_y_sum[47:16];
    wire signed [31:0] v0_clip_z = v0_z_sum[47:16];
    wire signed [31:0] v0_clip_w = v0_w_sum[47:16];

    wire signed [31:0] v0_w_safe = (v0_clip_w == 32'sd0) ? ONE : v0_clip_w;

    wire signed [63:0] v0_ndc_x_num = $signed(v0_clip_x) <<< 16;
    wire signed [63:0] v0_ndc_y_num = -($signed(v0_clip_y) <<< 16);
    wire signed [63:0] v0_ndc_z_num = $signed(v0_clip_z) <<< 16;

    wire signed [31:0] v0_ndc_x = v0_ndc_x_num / v0_w_safe;
    wire signed [31:0] v0_ndc_y = v0_ndc_y_num / v0_w_safe;
    wire signed [31:0] v0_ndc_z = v0_ndc_z_num / v0_w_safe;

    wire signed [31:0] v0_ndc_x_01 = (v0_ndc_x + ONE) >>> 1;
    wire signed [31:0] v0_ndc_y_01 = (v0_ndc_y + ONE) >>> 1;

    wire signed [63:0] v0_scr_x_mul = $signed(v0_ndc_x_01) * $signed(vpw32);
    wire signed [63:0] v0_scr_y_mul = $signed(v0_ndc_y_01) * $signed(vph32);

    wire [15:0] v0_x_scr = v0_scr_x_mul[31+16:16];
    wire [15:0] v0_y_scr = v0_scr_y_mul[31+16:16];
    wire [15:0] v0_z_scr = v0_ndc_z[31:16];

    wire signed [63:0] v1_x_t0  = $signed(sm00) * $signed(v1_x);
    wire signed [63:0] v1_x_t1  = $signed(sm01) * $signed(v1_y);
    wire signed [63:0] v1_x_t2  = $signed(sm02) * $signed(v1_z);
    wire signed [63:0] v1_x_sum = v1_x_t0 + v1_x_t1 + v1_x_t2 + {{32{sm03[31]}}, sm03};

    wire signed [63:0] v1_y_t0  = $signed(sm10) * $signed(v1_x);
    wire signed [63:0] v1_y_t1  = $signed(sm11) * $signed(v1_y);
    wire signed [63:0] v1_y_t2  = $signed(sm12) * $signed(v1_z);
    wire signed [63:0] v1_y_sum = v1_y_t0 + v1_y_t1 + v1_y_t2 + {{32{sm13[31]}}, sm13};

    wire signed [63:0] v1_z_t0  = $signed(sm20) * $signed(v1_x);
    wire signed [63:0] v1_z_t1  = $signed(sm21) * $signed(v1_y);
    wire signed [63:0] v1_z_t2  = $signed(sm22) * $signed(v1_z);
    wire signed [63:0] v1_z_sum = v1_z_t0 + v1_z_t1 + v1_z_t2 + {{32{sm23[31]}}, sm23};

    wire signed [63:0] v1_w_t0  = $signed(sm30) * $signed(v1_x);
    wire signed [63:0] v1_w_t1  = $signed(sm31) * $signed(v1_y);
    wire signed [63:0] v1_w_t2  = $signed(sm32) * $signed(v1_z);
    wire signed [63:0] v1_w_sum = v1_w_t0 + v1_w_t1 + v1_w_t2 + {{32{sm33[31]}}, sm33};

    wire signed [31:0] v1_clip_x = v1_x_sum[47:16];
    wire signed [31:0] v1_clip_y = v1_y_sum[47:16];
    wire signed [31:0] v1_clip_z = v1_z_sum[47:16];
    wire signed [31:0] v1_clip_w = v1_w_sum[47:16];

    wire signed [31:0] v1_w_safe = (v1_clip_w == 32'sd0) ? ONE : v1_clip_w;

    wire signed [63:0] v1_ndc_x_num = $signed(v1_clip_x) <<< 16;
    wire signed [63:0] v1_ndc_y_num = -($signed(v1_clip_y) <<< 16);
    wire signed [63:0] v1_ndc_z_num = $signed(v1_clip_z) <<< 16;

    wire signed [31:0] v1_ndc_x = v1_ndc_x_num / v1_w_safe;
    wire signed [31:0] v1_ndc_y = v1_ndc_y_num / v1_w_safe;
    wire signed [31:0] v1_ndc_z = v1_ndc_z_num / v1_w_safe;

    wire signed [31:0] v1_ndc_x_01 = (v1_ndc_x + ONE) >>> 1;
    wire signed [31:0] v1_ndc_y_01 = (v1_ndc_y + ONE) >>> 1;

    wire signed [63:0] v1_scr_x_mul = $signed(v1_ndc_x_01) * $signed(vpw32);
    wire signed [63:0] v1_scr_y_mul = $signed(v1_ndc_y_01) * $signed(vph32);

    wire [15:0] v1_x_scr = v1_scr_x_mul[31+16:16];
    wire [15:0] v1_y_scr = v1_scr_y_mul[31+16:16];
    wire [15:0] v1_z_scr = v1_ndc_z[31:16];

    wire signed [63:0] v2_x_t0  = $signed(sm00) * $signed(v2_x);
    wire signed [63:0] v2_x_t1  = $signed(sm01) * $signed(v2_y);
    wire signed [63:0] v2_x_t2  = $signed(sm02) * $signed(v2_z);
    wire signed [63:0] v2_x_sum = v2_x_t0 + v2_x_t1 + v2_x_t2 + {{32{sm03[31]}}, sm03};

    wire signed [63:0] v2_y_t0  = $signed(sm10) * $signed(v2_x);
    wire signed [63:0] v2_y_t1  = $signed(sm11) * $signed(v2_y);
    wire signed [63:0] v2_y_t2  = $signed(sm12) * $signed(v2_z);
    wire signed [63:0] v2_y_sum = v2_y_t0 + v2_y_t1 + v2_y_t2 + {{32{sm13[31]}}, sm13};

    wire signed [63:0] v2_z_t0  = $signed(sm20) * $signed(v2_x);
    wire signed [63:0] v2_z_t1  = $signed(sm21) * $signed(v2_y);
    wire signed [63:0] v2_z_t2  = $signed(sm22) * $signed(v2_z);
    wire signed [63:0] v2_z_sum = v2_z_t0 + v2_z_t1 + v2_z_t2 + {{32{sm23[31]}}, sm23};

    wire signed [63:0] v2_w_t0  = $signed(sm30) * $signed(v2_x);
    wire signed [63:0] v2_w_t1  = $signed(sm31) * $signed(v2_y);
    wire signed [63:0] v2_w_t2  = $signed(sm32) * $signed(v2_z);
    wire signed [63:0] v2_w_sum = v2_w_t0 + v2_w_t1 + v2_w_t2 + {{32{sm33[31]}}, sm33};

    wire signed [31:0] v2_clip_x = v2_x_sum[47:16];
    wire signed [31:0] v2_clip_y = v2_y_sum[47:16];
    wire signed [31:0] v2_clip_z = v2_z_sum[47:16];
    wire signed [31:0] v2_clip_w = v2_w_sum[47:16];

    wire signed [31:0] v2_w_safe = (v2_clip_w == 32'sd0) ? ONE : v2_clip_w;

    wire signed [63:0] v2_ndc_x_num = $signed(v2_clip_x) <<< 16;
    wire signed [63:0] v2_ndc_y_num = -($signed(v2_clip_y) <<< 16);
    wire signed [63:0] v2_ndc_z_num = $signed(v2_clip_z) <<< 16;

    wire signed [31:0] v2_ndc_x = v2_ndc_x_num / v2_w_safe;
    wire signed [31:0] v2_ndc_y = v2_ndc_y_num / v2_w_safe;
    wire signed [31:0] v2_ndc_z = v2_ndc_z_num / v2_w_safe;

    wire signed [31:0] v2_ndc_x_01 = (v2_ndc_x + ONE) >>> 1;
    wire signed [31:0] v2_ndc_y_01 = (v2_ndc_y + ONE) >>> 1;

    wire signed [63:0] v2_scr_x_mul = $signed(v2_ndc_x_01) * $signed(vpw32);
    wire signed [63:0] v2_scr_y_mul = $signed(v2_ndc_y_01) * $signed(vph32);

    wire [15:0] v2_x_scr = v2_scr_x_mul[31+16:16];
    wire [15:0] v2_y_scr = v2_scr_y_mul[31+16:16];
    wire [15:0] v2_z_scr = v2_ndc_z[31:16];

    reg [1:0] st;

    always @(posedge CLK) begin
        if (rst) begin
            st     <= 2'd0;
            done   <= 1'b0;
            out_v0 <= {DW_VERTEX{1'b0}};
            out_v1 <= {DW_VERTEX{1'b0}};
            out_v2 <= {DW_VERTEX{1'b0}};
        end else begin
            done <= 1'b0;
            case (st)
                2'd0: begin
                    if (start) begin

                        out_v0 <= { v0_x_scr, v0_y_scr, v0_z_scr, v0_col, v0_pad, v0_uv };
                        out_v1 <= { v1_x_scr, v1_y_scr, v1_z_scr, v1_col, v1_pad, v1_uv };
                        out_v2 <= { v2_x_scr, v2_y_scr, v2_z_scr, v2_col, v2_pad, v2_uv };
                        st     <= 2'd1;
                    end
                end

                2'd1: begin
                    done <= 1'b1;
                    st   <= 2'd2;
                end

                2'd2: begin
                    st <= 2'd0;
                end

                default: st <= 2'd0;
            endcase
        end
    end

endmodule