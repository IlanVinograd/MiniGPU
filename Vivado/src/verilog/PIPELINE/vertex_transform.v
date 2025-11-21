`timescale 1ns / 1ps

module vertex_transform #(
    parameter integer DW_VERTEX = 64,
    parameter integer MW        = 32
)(
    input  wire CLK,
    input  wire rst,
    input  wire start,

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
    wire [7:0]  v0_col = in_v0[15:8];
    wire [3:0]  v0_pad = in_v0[7:4];
    wire [3:0]  v0_uv  = in_v0[3:0];

    wire signed [15:0] v1_x16 = in_v1[63:48];
    wire signed [15:0] v1_y16 = in_v1[47:32];
    wire signed [15:0] v1_z16 = in_v1[31:16];
    wire [7:0]  v1_col = in_v1[15:8];
    wire [3:0]  v1_pad = in_v1[7:4];
    wire [3:0]  v1_uv  = in_v1[3:0];

    wire signed [15:0] v2_x16 = in_v2[63:48];
    wire signed [15:0] v2_y16 = in_v2[47:32];
    wire signed [15:0] v2_z16 = in_v2[31:16];
    wire [7:0]  v2_col = in_v2[15:8];
    wire [3:0]  v2_pad = in_v2[7:4];
    wire [3:0]  v2_uv  = in_v2[3:0];

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

    wire signed [63:0] v0_x_sum = sm00*v0_x + sm01*v0_y + sm02*v0_z + {{32{sm03[31]}}, sm03};
    wire signed [63:0] v0_y_sum = sm10*v0_x + sm11*v0_y + sm12*v0_z + {{32{sm13[31]}}, sm13};
    wire signed [63:0] v0_z_sum = sm20*v0_x + sm21*v0_y + sm22*v0_z + {{32{sm23[31]}}, sm23};
    wire signed [63:0] v0_w_sum = sm30*v0_x + sm31*v0_y + sm32*v0_z + {{32{sm33[31]}}, sm33};

    wire signed [31:0] v0_clip_x = v0_x_sum[31:0];
    wire signed [31:0] v0_clip_y = v0_y_sum[31:0];
    wire signed [31:0] v0_clip_z = v0_z_sum[31:0];
    wire signed [31:0] v0_clip_w = v0_w_sum[31:0];
    wire signed [31:0] v0_w_safe = (v0_clip_w == 0) ? ONE : v0_clip_w;

    wire signed [31:0] v0_ndc_x = (v0_clip_x <<< 16) / v0_w_safe;
    wire signed [31:0] v0_ndc_y = -(v0_clip_y <<< 16) / v0_w_safe;
    wire signed [31:0] v0_ndc_z = (v0_clip_z <<< 16) / v0_w_safe;

    wire signed [31:0] v0_ndc_x_01 = (v0_ndc_x + ONE) >>> 1;
    wire signed [31:0] v0_ndc_y_01 = (v0_ndc_y + ONE) >>> 1;
    wire signed [31:0] v0_ndc_z_01 = (v0_ndc_z + ONE) >>> 1;

    wire signed [63:0] v0_scr_x_mul = v0_ndc_x_01 * vpw32;
    wire signed [63:0] v0_scr_y_mul = v0_ndc_y_01 * vph32;

    wire [15:0] v0_x_scr = v0_scr_x_mul[31:16];
    wire [15:0] v0_y_scr = v0_scr_y_mul[31:16];
    wire [15:0] v0_z_scr = v0_ndc_z_01[15:0];

    wire signed [63:0] v1_x_sum = sm00*v1_x + sm01*v1_y + sm02*v1_z + {{32{sm03[31]}}, sm03};
    wire signed [63:0] v1_y_sum = sm10*v1_x + sm11*v1_y + sm12*v1_z + {{32{sm13[31]}}, sm13};
    wire signed [63:0] v1_z_sum = sm20*v1_x + sm21*v1_y + sm22*v1_z + {{32{sm23[31]}}, sm23};
    wire signed [63:0] v1_w_sum = sm30*v1_x + sm31*v1_y + sm32*v1_z + {{32{sm33[31]}}, sm33};

    wire signed [31:0] v1_clip_x = v1_x_sum[31:0];
    wire signed [31:0] v1_clip_y = v1_y_sum[31:0];
    wire signed [31:0] v1_clip_z = v1_z_sum[31:0];
    wire signed [31:0] v1_clip_w = v1_w_sum[31:0];
    wire signed [31:0] v1_w_safe = (v1_clip_w == 0) ? ONE : v1_clip_w;

    wire signed [31:0] v1_ndc_x = (v1_clip_x <<< 16) / v1_w_safe;
    wire signed [31:0] v1_ndc_y = -(v1_clip_y <<< 16) / v1_w_safe;
    wire signed [31:0] v1_ndc_z = (v1_clip_z <<< 16) / v1_w_safe;

    wire signed [31:0] v1_ndc_x_01 = (v1_ndc_x + ONE) >>> 1;
    wire signed [31:0] v1_ndc_y_01 = (v1_ndc_y + ONE) >>> 1;
    wire signed [31:0] v1_ndc_z_01 = (v1_ndc_z + ONE) >>> 1;

    wire signed [63:0] v1_scr_x_mul = v1_ndc_x_01 * vpw32;
    wire signed [63:0] v1_scr_y_mul = v1_ndc_y_01 * vph32;

    wire [15:0] v1_x_scr = v1_scr_x_mul[31:16];
    wire [15:0] v1_y_scr = v1_scr_y_mul[31:16];
    wire [15:0] v1_z_scr = v1_ndc_z_01[15:0];

    wire signed [63:0] v2_x_sum = sm00*v2_x + sm01*v2_y + sm02*v2_z + {{32{sm03[31]}}, sm03};
    wire signed [63:0] v2_y_sum = sm10*v2_x + sm11*v2_y + sm12*v2_z + {{32{sm13[31]}}, sm13};
    wire signed [63:0] v2_z_sum = sm20*v2_x + sm21*v2_y + sm22*v2_z + {{32{sm23[31]}}, sm23};
    wire signed [63:0] v2_w_sum = sm30*v2_x + sm31*v2_y + sm32*v2_z + {{32{sm33[31]}}, sm33};

    wire signed [31:0] v2_clip_x = v2_x_sum[31:0];
    wire signed [31:0] v2_clip_y = v2_y_sum[31:0];
    wire signed [31:0] v2_clip_z = v2_z_sum[31:0];
    wire signed [31:0] v2_clip_w = v2_w_sum[31:0];
    wire signed [31:0] v2_w_safe = (v2_clip_w == 0) ? ONE : v2_clip_w;

    wire signed [31:0] v2_ndc_x = (v2_clip_x <<< 16) / v2_w_safe;
    wire signed [31:0] v2_ndc_y = -(v2_clip_y <<< 16) / v2_w_safe;
    wire signed [31:0] v2_ndc_z = (v2_clip_z <<< 16) / v2_w_safe;

    wire signed [31:0] v2_ndc_x_01 = (v2_ndc_x + ONE) >>> 1;
    wire signed [31:0] v2_ndc_y_01 = (v2_ndc_y + ONE) >>> 1;
    wire signed [31:0] v2_ndc_z_01 = (v2_ndc_z + ONE) >>> 1;

    wire signed [63:0] v2_scr_x_mul = v2_ndc_x_01 * vpw32;
    wire signed [63:0] v2_scr_y_mul = v2_ndc_y_01 * vph32;

    wire [15:0] v2_x_scr = v2_scr_x_mul[31:16];
    wire [15:0] v2_y_scr = v2_scr_y_mul[31:16];
    wire [15:0] v2_z_scr = v2_ndc_z_01[15:0];

    reg [1:0] st;

    always @(posedge CLK) begin
        if (rst) begin
            st     <= 0;
            done   <= 0;
            out_v0 <= 0;
            out_v1 <= 0;
            out_v2 <= 0;
        end else begin
            done <= 0;
            case (st)
                0: begin
                    if (start) begin
                        out_v0 <= { v0_x_scr, v0_y_scr, v0_z_scr, v0_col, v0_pad, v0_uv };
                        out_v1 <= { v1_x_scr, v1_y_scr, v1_z_scr, v1_col, v1_pad, v1_uv };
                        out_v2 <= { v2_x_scr, v2_y_scr, v2_z_scr, v2_col, v2_pad, v2_uv };
                        st     <= 1;
                    end
                end
                1: begin
                    done <= 1;
                    st   <= 2;
                end
                2: begin
                    st <= 0;
                end
            endcase
        end
    end

endmodule