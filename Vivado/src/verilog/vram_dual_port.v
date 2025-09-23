`timescale 1ns / 1ps

module vram_dual_clock #(
    parameter TOTAL_BYTES = 230400
)(
    input CLK_A,
    input [7:0] DATA_A,
    input [17:0] ADDR_A,
    input WE_A,
    output reg [7:0] Q_A,

    input CLK_B,
    input [7:0] DATA_B,
    input [17:0] ADDR_B,
    input WE_B,
    output reg [7:0] Q_B
);

    (* ram_style = "block", keep = "true" *)
    reg [7:0] MEM [0:TOTAL_BYTES-1];

    initial $readmemh("frame1.hex", MEM);

    always @(posedge CLK_A) begin
        if (WE_A) MEM[ADDR_A] <= DATA_A;
        Q_A <= MEM[ADDR_A];
    end

    always @(posedge CLK_B) begin
        if (WE_B) MEM[ADDR_B] <= DATA_B;
        Q_B <= MEM[ADDR_B];
    end

endmodule