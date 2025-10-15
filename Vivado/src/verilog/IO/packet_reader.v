`timescale 1ns / 1ps

module packet_reader #(
    parameter integer SIZE = 256,
    parameter integer OPCODE_BYTE = 2
)(
    input  wire              CLK,
    input  wire              rst,
    input  wire              fifo_empty,
    input  wire [8*SIZE-1:0] fifo_data,
    output reg               rd_en,
    output reg  [7:0]        opcode,
    output reg               packet_ready
);

    reg have_pkt;

    always @(posedge CLK) begin
        if (rst) begin
            rd_en        <= 1'b0;
            have_pkt     <= 1'b0;
            packet_ready <= 1'b0;
            opcode       <= 8'h00;
        end else begin
            rd_en        <= 1'b0;
            packet_ready <= 1'b0;

            if (!have_pkt) begin
                if (!fifo_empty) begin
                    rd_en        <= 1'b1;
                    have_pkt     <= 1'b1;
                    opcode       <= fifo_data[8*OPCODE_BYTE +: 8];
                    packet_ready <= 1'b1;
                end
            end else begin
                have_pkt <= 1'b0;
            end
        end
    end

endmodule