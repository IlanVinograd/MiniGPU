`timescale 1ns / 1ps

/*
x	  15:0          16 bit
y	  31:16         16 bit
z	  47:32         16 bit
color 55:48	RGB332  8 bit
pad	  59:56	reserve 4 bit
uv	  63:60	UV      4 bit

AA   15    03   02   00 10       |   00 64 00 C8 00 00 E3 10   |     |  00 32 00 96 00 00 4F 20 |  CRC
│    │     │    │    └─┬─┘       └───────── vertex[0] ─────────┘      └──────── vertex[1] ───────┘
│    │     │    │    START = 0x0010
│    │     │    COUNT = 2
│    │     opcode (LOAD_VERTEX_BEGIN = 0x03)
│    LEN = 5 + 8×2 = 21 (0x15)
SYNC (0xAA)
*/

`timescale 1ns / 1ps

module cmd_load_vertex #(
    parameter integer DEPTH       = 1024,
    parameter integer DW          = 64,
    parameter integer PACKET_SIZE = 256
)(
    input  wire                         CLK,
    input  wire                         rst,
    input  wire                         begin_req_pulse,
    input  wire [7:0]                   begin_len,
    input  wire [8*PACKET_SIZE-1:0]     begin_packet,

    output reg  [$clog2(DEPTH)-1:0]     vertex_waddr,
    output reg  [DW-1:0]                vertex_wdata,
    output reg                          vertex_we,
    output reg                          BUSY,
    output reg                          err_len,
    output reg                          err_range,
    output reg                          err_proto
);
    localparam B_LEN      = 1;
    localparam B_COUNT    = 3;
    localparam B_START    = 4;
    localparam B_PAYLOAD  = 6;

    reg [8*PACKET_SIZE-1:0] pkt;
    reg [$clog2(DEPTH)-1:0] next_addr;
    reg [15:0]              remaining;
    reg [7:0]               i;
    reg [7:0]               count_latched;
    reg                     len_ok, range_ok;
    integer                 base;
    reg [15:0]              x, y ,z;
    reg [7:0]               RGB;
    reg [3:0]               reserve;
    reg [3:0]               uv;
    reg [7:0]               last_byte;

    function [15:0] u16_at;
        input [8*PACKET_SIZE-1:0] bus;
        input integer byte_index;
        begin
            u16_at = { bus[8*(byte_index+0)+:8],
                       bus[8*(byte_index+1)+:8] };
        end
    endfunction

    function [7:0] u8_at;
        input [8*PACKET_SIZE-1:0] bus;
        input integer byte_index;
        begin
            u8_at = bus[8*byte_index +: 8];
        end
    endfunction

    wire [7:0]  count_w          = begin_packet[8*B_COUNT +:8];
    wire [15:0] start16_w        = u16_at(begin_packet, B_START);
    wire [16:0] start_plus_count = start16_w + count_w;

    always @(posedge CLK) begin
        if (rst) begin
            vertex_waddr   <= {($clog2(DEPTH)){1'b0}};
            vertex_wdata   <= {DW{1'b0}};
            vertex_we      <= 1'b0;
            BUSY           <= 1'b0;
            pkt            <= {8*PACKET_SIZE{1'b0}};
            next_addr      <= {($clog2(DEPTH)){1'b0}};
            remaining      <= 16'd0;
            i              <= 8'd0;
            count_latched  <= 8'd0;
            len_ok         <= 1'b0;
            range_ok       <= 1'b0;
            err_len        <= 1'b0;
            err_range      <= 1'b0;
            err_proto      <= 1'b0;
        end else begin
            vertex_we <= 1'b0;
            if (begin_req_pulse && !BUSY) begin
                pkt           <= begin_packet;
                len_ok        <= (begin_len == (8'd5 + count_w*8'd8));
                range_ok      <= (start_plus_count <= DEPTH);
                err_len       <= 1'b0;
                err_range     <= 1'b0;
                err_proto     <= 1'b0;
                count_latched <= count_w;
                next_addr     <= start16_w[$clog2(DEPTH)-1:0];
                remaining     <= count_w;
                i             <= 8'd0;
                BUSY          <= 1'b1;
            end else if (BUSY && (i < count_latched)) begin
                if (!len_ok || !range_ok) begin
                    BUSY <= 1'b0;
                    if (!len_ok)   err_len   <= 1'b1;
                    if (!range_ok) err_range <= 1'b1;
                end else begin
                    base      = B_PAYLOAD + (i * 8);
                    x         = u16_at(pkt, base + 0);
                    y         = u16_at(pkt, base + 2);
                    z         = u16_at(pkt, base + 4);
                    RGB       = u8_at(pkt,  base + 6);
                    last_byte = u8_at(pkt,  base + 7);
                    reserve   = last_byte[7:4];
                    uv        = last_byte[3:0];

                    vertex_waddr <= next_addr;
                    vertex_wdata <= {x, y, z, RGB, reserve, uv};
                    vertex_we    <= 1'b1;

                    next_addr  <= next_addr + 1'b1;
                    remaining  <= remaining  - 1'b1;
                    i          <= i + 8'd1;

                    if ((i == count_latched - 1) && (remaining == 16'd1)) begin
                        BUSY <= 1'b0;
                    end
                end
            end
        end
    end
endmodule