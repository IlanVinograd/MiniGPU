`timescale 1ns / 1ps

module uart_pc_fpga #(
    parameter integer DEPTH    = 8,
    parameter integer SIZE     = 256,
    parameter [7:0]   SYNC     = 8'hAA,
    parameter integer ADDR_W   = 17,
    parameter [ADDR_W-1:0] BASE_ADDR = 17'd49152
)(
    input  CLK,
    input  RX,
    input  rst,
    output HS,
    output VS,
    output [3:0] RED,
    output [3:0] GREEN,
    output [3:0] BLUE
);

    wire [7:0] rx_data;
    wire       rx_valid;
    wire       tx_ready_dummy;

    uart_core uc (
        .CLK     (CLK),
        .rst     (rst),
        .RX      (RX),
        .TX      (),
        .rx_data (rx_data),
        .rx_valid(rx_valid),
        .tx_data (8'b0),
        .tx_valid(1'b0),
        .tx_ready(tx_ready_dummy)
    );

    wire [8*SIZE-1:0] packet;
    wire valid_packet;

    wire fifo_empty;
    wire fifo_full;
    wire [8*SIZE-1:0] fifo_data;
    reg rd_en;
    wire wr_en = valid_packet && !fifo_full;

    sync_fifo #(.WIDTH(SIZE), .DEPTH(DEPTH)) u_pkt_fifo (
        .CLK     (CLK),
        .rst     (rst),
        .wr_en   (wr_en),
        .rd_en   (rd_en),
        .data_in (packet),
        .data_out(fifo_data),
        .empty   (fifo_empty),
        .full    (fifo_full)
    );

    wire err_len_dummy, err_crc_dummy;
    packet_assembler #(.SIZE(SIZE), .SYNC(SYNC)) pa (
        .CLK         (CLK),
        .rst         (rst),
        .rx_data     (rx_data),
        .rx_valid    (rx_valid),
        .fifo_ready  (!fifo_full),
        .fifo_full   (fifo_full),
        .packet      (packet),
        .valid_packet(valid_packet),
        .err_len     (err_len_dummy),
        .err_crc     (err_crc_dummy)
    );

    localparam [7:0] IMG_ONE = 8'h01, IMG_TWO = 8'h02;
    localparam integer OPCODE_BYTE = 2;

    reg image = 1'b0;

    always @(posedge CLK) begin
        if (rst) begin
            image <= 1'b0;
            rd_en <= 1'b0;
        end else begin
            rd_en <= 1'b0;

            if (!fifo_empty) begin
                case (fifo_data[8*OPCODE_BYTE +: 8])
                    IMG_ONE: image <= 1'b0;
                    IMG_TWO: image <= 1'b1;
                endcase
                    rd_en <= 1'b1;
            end
        end
    end

    vga_basic #(.ADDR_W(ADDR_W)) vb (
        .CLK       (CLK),
        .BASE_ADDR (image ? BASE_ADDR : {ADDR_W{1'b0}}),
        .HS        (HS),
        .VS        (VS),
        .RED       (RED),
        .GREEN     (GREEN),
        .BLUE      (BLUE)
    );

endmodule