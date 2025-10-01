`timescale 1ns/1ps

module sync_fifo #(
    parameter integer WIDTH = 256,
    parameter integer DEPTH = 8
)(
    input  wire                CLK,
    input  wire                rst,
    input  wire                wr_en,
    input  wire                rd_en,
    input  wire [8*WIDTH-1:0]  data_in,
    output reg  [8*WIDTH-1:0]  data_out,
    output wire                empty,
    output wire                full
);

    localparam integer AW = (DEPTH <= 2) ? 1 : $clog2(DEPTH);

    reg [AW-1:0] wptr;
    reg [AW-1:0] rptr;

    reg [8*WIDTH-1:0] fifo [0:DEPTH-1];

    assign empty = (rptr == wptr);
    assign full  = ((wptr + 1'b1) == rptr);

    always @(posedge CLK) begin
        if (rst) begin
            wptr <= {AW{1'b0}};
        end else if (wr_en && !full) begin
            fifo[wptr] <= data_in;
            wptr <= wptr + 1'b1;
        end
    end

    always @(posedge CLK) begin
        if (rst) begin
            rptr     <= {AW{1'b0}};
            data_out <= {8*WIDTH{1'b0}};
        end else if (rd_en && !empty) begin
            data_out <= fifo[rptr];
            rptr <= rptr + 1'b1;
        end
    end

endmodule