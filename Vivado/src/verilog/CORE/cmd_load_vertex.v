`timescale 1ns / 1ps

/*
x	  15:0
y	  31:16
z	  47:32
color 55:48	RGB332 
pad	  59:56	reserve
uv	  63:60	UV

AA   15    03   02   00 10       |   00 64 00 C8 00 00 E3 10   |     |  00 32 00 96 00 00 4F 20 |  CRC
│    │     │    │    └─┬─┘       └───────── vertex[0] ─────────┘      └──────── vertex[1] ───────┘
│    │     │    │    START = 0x0010
│    │     │    COUNT = 2
│    │     opcode (LOAD_VERTEX_BEGIN = 0x03)
│    LEN = 5 + 8×2 = 21 (0x15)
SYNC (0xAA)
*/

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
    output reg                          BUSY
);
    localparam B_LEN      = 1;
    localparam B_COUNT    = 3;
    localparam B_START    = 4;
    localparam B_PAYLOAD  = 6;


endmodule