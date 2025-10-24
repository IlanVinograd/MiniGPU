`timescale 1ns/1ps
/*
i0 - 15:0   index of vertex 0
i1 - 31:16  index of vertex 1
i2 - 47:32  index of vertex 2
*/
module edge_buffer #(
    parameter integer DEPTH = 1024,   // 1024 edges
    parameter integer DW    = 48      // each edge = 48 bits
)(
    input  wire              CLK_A,
    input  wire [DW-1:0]     DATA_A,
    input  wire [$clog2(DEPTH)-1:0] ADDR_A,
    input  wire              WE_A,
    output reg  [DW-1:0]     Q_A,

    input  wire              CLK_B,
    input  wire [DW-1:0]     DATA_B,
    input  wire [$clog2(DEPTH)-1:0] ADDR_B,
    input  wire              WE_B,
    output reg  [DW-1:0]     Q_B
);

    (* ram_style = "block" *)
    reg [DW-1:0] MEM [0:DEPTH-1];

    always @(posedge CLK_A) begin
        if (WE_A) MEM[ADDR_A] <= DATA_A;
        Q_A <= MEM[ADDR_A];
    end

    always @(posedge CLK_B) begin
        if (WE_B) MEM[ADDR_B] <= DATA_B;
        Q_B <= MEM[ADDR_B];
    end

endmodule