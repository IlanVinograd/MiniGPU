`timescale 1ns / 1ps
module cmd_load_edge #(
    parameter integer DEPTH       = 1024,
    parameter integer DW          = 48,
    parameter integer PACKET_SIZE = 256
)(
    input  wire                         CLK,
    input  wire                         rst,
    input  wire                         begin_req_pulse,
    input  wire [7:0]                   begin_len,
    input  wire [8*PACKET_SIZE-1:0]     begin_packet,
    output reg  [$clog2(DEPTH)-1:0]     edge_waddr,
    output reg  [DW-1:0]                edge_wdata,
    output reg                          edge_we,
    output reg                          BUSY,
    output reg                          err_len,
    output reg                          err_range,
    output reg                          err_proto
);
    localparam B_LEN   = 1;
    localparam B_COUNT = 3;
    localparam B_START = 4;
    localparam B_PAY_B = 5;

    reg [$clog2(DEPTH)-1:0] next_addr;
    reg [15:0]               remaining;
    reg [7:0] i;
    reg [7:0] count_latched;
    reg       len_ok, range_ok;
    integer   base;
    reg [15:0] i0, i1, i2;

    function [15:0] u16_at;
        input [8*PACKET_SIZE-1:0] pkt;
        input integer byte_index;
        begin
            u16_at = { pkt[8*(byte_index+0)+:8],
                       pkt[8*(byte_index+1)+:8] };
        end
    endfunction

    always @(posedge CLK) begin
        if (rst) begin
            BUSY       <= 1'b0;
            edge_we    <= 1'b0;
            edge_waddr <= {($clog2(DEPTH)){1'b0}};
            edge_wdata <= {DW{1'b0}};
            err_len    <= 1'b0;
            err_range  <= 1'b0;
            err_proto  <= 1'b0;
            next_addr  <= {($clog2(DEPTH)){1'b0}};
            remaining  <= 16'd0;
            count_latched <= 8'd0;
            i          <= 8'd0;
            len_ok     <= 1'b0;
            range_ok   <= 1'b0;
        end else begin
            edge_we <= 1'b0;
            if (begin_req_pulse && !BUSY) begin
                len_ok   <= (begin_len == (8'd4 + begin_packet[8*B_COUNT +:8]*8'd6));
                range_ok <= (begin_packet[8*B_START +:8] + begin_packet[8*B_COUNT +:8] <= DEPTH);
                err_len   <= 1'b0;
                err_range <= 1'b0;
                err_proto <= 1'b0;
                count_latched <= begin_packet[8*B_COUNT +:8];
                next_addr     <= begin_packet[8*B_START +:8];
                remaining     <= begin_packet[8*B_COUNT +:8];
                i             <= 8'd0;
                BUSY <= 1'b1;
            end
            else if (BUSY && (i < count_latched)) begin
                if (!len_ok || !range_ok) begin
                    BUSY <= 1'b0;
                    if (!len_ok)   err_len   <= 1'b1;
                    if (!range_ok) err_range <= 1'b1;
                end else begin
                    base = B_PAY_B + (i * 6);
                    i0   = u16_at(begin_packet, base + 0);
                    i1   = u16_at(begin_packet, base + 2);
                    i2   = u16_at(begin_packet, base + 4);
                    edge_waddr <= next_addr;
                    edge_wdata <= {i2, i1, i0};
                    edge_we    <= 1'b1;
                    next_addr  <= next_addr + 1'b1;
                    remaining  <= remaining  - 1'b1;
                    i          <= i + 8'd1;
                    if (i == count_latched - 1) begin
                        if (remaining == 16'd1) begin
                            BUSY <= 1'b0;
                        end
                    end
                end
            end
        end
    end
endmodule