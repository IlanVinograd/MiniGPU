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

    wire vs_norm = VS_ACTIVE_LOW ? ~vs_sync : vs_sync;

    wire rise = (~vs_prev) &  vs_sync;
    wire fall = ( vs_prev) & ~vs_sync;

    wire vs_event = VS_ACTIVE_LOW ? rise : fall;

    reg pending;

    always @(posedge CLK) begin
        if (rst) begin
            side    <= 1'b0;
            pending <= 1'b0;
        end else begin
            if (swap_req) pending <= 1'b1;

            if (BYPASS_VSYNC) begin
                if (swap_req) side <= ~side;
            end else begin
                if (pending && vs_event) begin
                    side    <= ~side;
                    pending <= 1'b0;
                end
            end
        end
    end
endmodule