`timescale 1ns/1ps

module swap_buffer #(
    parameter VS_ACTIVE_LOW = 1,
    parameter BYPASS_VSYNC  = 0
)(
    input  wire CLK,
    input  wire rst,
    input  wire vsync,
    input  wire swap_req,
    output reg  side = 1'b0
);
    reg vs_meta, vs_sync, vs_prev;
    always @(posedge CLK) begin
        vs_meta <= vsync;
        vs_sync <= vs_meta;
        vs_prev <= vs_sync;
    end

    wire rise = (~vs_prev) &  vs_sync;
    wire fall = ( vs_prev) & ~vs_sync;
    wire vs_event = VS_ACTIVE_LOW ? fall : rise;

    reg pending;

    wire will_swap = pending | swap_req;

    always @(posedge CLK) begin
        if (rst) begin
            side    <= 1'b0;
            pending <= 1'b0;
        end else if (BYPASS_VSYNC) begin
            if (swap_req) side <= ~side;
        end else begin
            if (vs_event && will_swap) begin
                side    <= ~side;
                pending <= 1'b0;
            end else if (swap_req) begin
                pending <= 1'b1;
            end
        end
    end
endmodule