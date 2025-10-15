`timescale 1ns / 1ps

module uart_pc_fpga #(
    parameter integer DEPTH     = 8,
    parameter integer SIZE      = 256,
    parameter [7:0]   SYNC      = 8'hAA,
    parameter integer ADDR_W    = 17,
    parameter [ADDR_W-1:0] BASE_ADDR = 17'd49152,
    parameter integer SWAP_IDX  = 0,
    parameter integer CLEAN_IDX = 1
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
    wire              valid_packet;
    wire              err_len_dummy, err_crc_dummy;

    wire              fifo_empty;
    wire              fifo_full;
    wire [8*SIZE-1:0] fifo_data;
    wire              rd_en;
    wire              wr_en = valid_packet && !fifo_full;

    sync_fifo #(.WIDTH(SIZE), .DEPTH(DEPTH)) u_pkt_fifo (
        .CLK      (CLK),
        .rst      (rst),
        .wr_en    (wr_en),
        .rd_en    (rd_en),
        .data_in  (packet),
        .data_out (fifo_data),
        .empty    (fifo_empty),
        .full     (fifo_full)
    );

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

    wire hs_int, vs_int;
    wire [3:0] red_i, green_i, blue_i;

    wire side;

    wire clk25;
    wire [16:0] vram_addr;
    wire [7:0]  vram_q;

    vga_basic #(.ADDR_W(ADDR_W)) vb (
        .CLK       (CLK),
        .BASE_ADDR (side ? BASE_ADDR : {ADDR_W{1'b0}}),
        .HS        (hs_int),
        .VS        (vs_int),
        .RED       (red_i),
        .GREEN     (green_i),
        .BLUE      (blue_i),
        .clk25     (clk25),
        .vram_addr (vram_addr),
        .vram_q    (vram_q)
    );

    assign HS   = hs_int;
    assign VS   = vs_int;
    assign RED  = red_i;
    assign GREEN= green_i;
    assign BLUE = blue_i;

    reg  swap_req_pulse;

    swap_buffer sb (
        .CLK      (CLK),
        .rst      (rst),
        .vsync    (vs_int),
        .swap_req (swap_req_pulse),
        .side     (side)
    );

    wire [7:0] BUSY;
    wire [7:0] CMD;

    wire [7:0] opcode;
    wire       packet_ready_pulse;

    localparam integer OPCODE_BYTE = 2;
    localparam integer ARG0_BYTE   = 3;

    packet_reader #(.SIZE(SIZE), .OPCODE_BYTE(OPCODE_BYTE)) pr (
        .CLK          (CLK),
        .rst          (rst),
        .fifo_empty   (fifo_empty),
        .fifo_data    (fifo_data),
        .rd_en        (rd_en),
        .opcode       (opcode),
        .packet_ready (packet_ready_pulse)
    );

    reg [7:0] arg0_color;
    always @(posedge CLK) begin
        if (rst) begin
            arg0_color <= 8'h00;
        end else if (rd_en) begin
            arg0_color <= fifo_data[8*ARG0_BYTE +: 8];
        end
    end

    cmd_decoder cd (
        .CLK          (CLK),
        .rst          (rst),
        .packet_ready (packet_ready_pulse),
        .opcode       (opcode),
        .BUSY         (BUSY),
        .CMD          (CMD)
    );

    always @(posedge CLK) begin
        if (rst) begin
            swap_req_pulse <= 1'b0;
        end else begin
            swap_req_pulse <= CMD[SWAP_IDX] & ~BUSY[CLEAN_IDX];
        end
    end

    wire        clear_busy;
    wire        clear_we_b;
    wire [7:0]  clear_data_b;
    wire [17:0] clear_addr_b;

    cmd_clear clr (
        .CLK            (CLK),
        .rst            (rst),
        .clear_req_pulse(CMD[CLEAN_IDX]),
        .side           (side),
        .color          (arg0_color),
        .vram_addr_b    (clear_addr_b),
        .vram_data_b    (clear_data_b),
        .vram_we_b      (clear_we_b),
        .BUSY           (clear_busy)
    );

    assign BUSY[SWAP_IDX]   = clear_busy;
    assign BUSY[CLEAN_IDX]  = clear_busy;
    assign BUSY[7:2]        = 6'b0;

    vram_dual_clock #(.TOTAL_BYTES(98304)) vram (
        .CLK_A (clk25),
        .DATA_A(8'h00),
        .ADDR_A({1'b0, vram_addr}),
        .WE_A  (1'b0),
        .Q_A   (vram_q),

        .CLK_B (CLK),
        .DATA_B(clear_data_b),
        .ADDR_B(clear_addr_b),
        .WE_B  (clear_we_b),
        .Q_B   ()
    );

endmodule