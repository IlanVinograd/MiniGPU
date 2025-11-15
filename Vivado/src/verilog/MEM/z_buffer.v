`timescale 1ns/1ps

module z_buffer #(
    parameter integer SIZE = 49_152,
    parameter integer ADDR_W = $clog2(SIZE)
)(
    input CLK,
    input rst,
    input WE_A,
    input  [15:0] DATA_A,
    input  [ADDR_W-1:0] ADDR_A,
    output reg [15:0] Q_A
);
    (* ram_style = "block", keep = "true" *)
    reg [15:0] MEM [0:SIZE-1];

    always @(posedge CLK) begin
        
        if (rst) begin
            Q_A <= 16'd0;
        end else begin
            if (WE_A) begin
                MEM[ADDR_A] <= DATA_A;
            end

            Q_A <= MEM[ADDR_A];
        end

    end

endmodule