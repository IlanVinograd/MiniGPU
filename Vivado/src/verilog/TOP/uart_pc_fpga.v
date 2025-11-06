`timescale 1ns / 1ps
module uart_pc_fpga #(
    parameter integer DEPTH     = 8,
    parameter integer SIZE      = 256,
    parameter [7:0]   SYNC      = 8'hAA,
    parameter integer ADDR_W    = 17,
    parameter [ADDR_W-1:0] BASE_ADDR = 17'd49152,
    parameter integer SWAP_IDX = 0,
    parameter integer CLEAN_IDX = 1,
    localparam integer LOAD_VERTEX_IDX = 2,
    localparam integer UNKNOWN_1  = 3,
    localparam integer LOAD_EDGE_IDX = 4,
    localparam integer UNKNOWN_2 = 5,
    localparam integer UNKNOWN_3 = 6,
    localparam integer STATUS_IDX = 7
)(
    input  wire CLK,
    input  wire RX,
    input  wire rst,
    output wire HS,
    output wire VS,
    output wire [3:0] RED,
    output wire [3:0] GREEN,
    output wire [3:0] BLUE,
    output wire TX
);
    localparam integer LEN_BYTE    = 1;
    localparam integer OPCODE_BYTE = 2;
    localparam integer ARG0_BYTE   = 3;

    wire [7:0] rx_data;
    wire       rx_valid;
    wire [7:0] tx_data;
    wire       tx_valid;
    wire       tx_ready;

    uart_core u_uart_core (
        .CLK     (CLK),
        .rst     (rst),
        .RX      (RX),
        .TX      (TX),
        .rx_data (rx_data),
        .rx_valid(rx_valid),
        .tx_data (tx_data),
        .tx_valid(tx_valid),
        .tx_ready(tx_ready)
    );

    wire [8*SIZE-1:0] packet;
    wire              valid_packet;
    wire              fifo_empty, fifo_full;
    wire [8*SIZE-1:0] fifo_data;
    wire              rd_en;
    wire              wr_en = valid_packet && !fifo_full;

    packet_assembler #(.SIZE(SIZE), .SYNC(SYNC)) u_packet_assembler (
        .CLK         (CLK),
        .rst         (rst),
        .rx_data     (rx_data),
        .rx_valid    (rx_valid),
        .fifo_ready  (!fifo_full),
        .fifo_full   (fifo_full),
        .packet      (packet),
        .valid_packet(valid_packet),
        .err_len     (),
        .err_crc     ()
    );

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

    wire        clk25;
    wire [16:0] vram_addr;
    wire [7:0]  vram_q;
    wire        side;

    vga_basic #(.ADDR_W(ADDR_W)) u_vga_basic (
        .CLK       (CLK),
        .BASE_ADDR (side ? BASE_ADDR : {ADDR_W{1'b0}}),
        .HS        (HS),
        .VS        (VS),
        .RED       (RED),
        .GREEN     (GREEN),
        .BLUE      (BLUE),
        .clk25     (clk25),
        .vram_addr (vram_addr),
        .vram_q    (vram_q)
    );

    swap_buffer u_swap_buffer (
        .CLK      (CLK),
        .rst      (rst),
        .vsync    (VS),
        .swap_req (CMD[SWAP_IDX]),
        .side     (side)
    );

    wire [7:0] opcode;
    wire       packet_ready;

    wire [7:0] head_opcode = fifo_data[8*OPCODE_BYTE +: 8];

    reg vs_d;
    always @(posedge CLK) vs_d <= VS;
    wire vs_event = (vs_d & ~VS);

    reg swap_lock;
    always @(posedge CLK) begin
        if (rst) swap_lock <= 1'b0;
        else begin
            if (CMD[SWAP_IDX]) swap_lock <= 1'b1;
            if (vs_event && swap_lock) swap_lock <= 1'b0;
        end
    end

    wire hold_05   = (!fifo_empty) && (head_opcode == 8'h05) && ledge_busy;
    wire hold_swap = (!fifo_empty) && (head_opcode == 8'h01) && swap_lock;
    wire hold = hold_05 | hold_swap;
    wire fifo_empty_eff = fifo_empty | hold;

    packet_reader #(.SIZE(SIZE), .OPCODE_BYTE(OPCODE_BYTE)) u_packet_reader (
        .CLK          (CLK),
        .rst          (rst),
        .fifo_empty   (fifo_empty_eff),
        .fifo_data    (fifo_data),
        .rd_en        (rd_en),
        .opcode       (opcode),
        .packet_ready (packet_ready)
    );

    wire [7:0] BUSY;
    wire [7:0] CMD;

    cmd_decoder u_cmd_decoder (
        .CLK          (CLK),
        .rst          (rst),
        .packet_ready (packet_ready),
        .opcode       (opcode),
        .BUSY         (BUSY),
        .CMD          (CMD)
    );

    cmd_status u_cmd_status (
        .CLK        (CLK),
        .rst        (rst),
        .status_req (CMD[STATUS_IDX]),
        .BUSY_STATUS(BUSY),
        .tx_ready   (tx_ready),
        .BUSY       (),
        .tx_data    (tx_data),
        .tx_valid   (tx_valid)
    );

    reg [7:0] color;
    always @(posedge CLK) begin
        if (rst) color <= 8'h00;
        else if (packet_ready && (opcode == 8'h02))
            color <= fifo_data[8*ARG0_BYTE +: 8];
    end

    wire        clear_busy;
    wire [17:0] clear_addr_b;
    wire [7:0]  clear_data_b;
    wire        clear_we_b;

    cmd_clear u_cmd_clear (
        .CLK            (CLK),
        .rst            (rst),
        .clear_req_pulse(CMD[CLEAN_IDX]),
        .side           (side),
        .color          (color),
        .vram_addr_b    (clear_addr_b),
        .vram_data_b    (clear_data_b),
        .vram_we_b      (clear_we_b),
        .BUSY           (clear_busy)
    );

    wire                     ledge_busy;
    wire [$clog2(1024)-1:0]  edge_waddr_w;
    wire [47:0]              edge_wdata_w;
    wire                     edge_we_w;

    cmd_load_edge #(
        .DEPTH       (1024),
        .DW          (48),
        .PACKET_SIZE (SIZE)
    ) u_cmd_load_edge (
        .CLK            (CLK),
        .rst            (rst),
        .begin_req_pulse(packet_ready && (opcode == 8'h05)),
        .begin_len      (fifo_data[8*LEN_BYTE +: 8]),
        .begin_packet   (fifo_data),
        .edge_waddr     (edge_waddr_w),
        .edge_wdata     (edge_wdata_w),
        .edge_we        (edge_we_w),
        .BUSY           (ledge_busy),
        .err_len        (),
        .err_range      (),
        .err_proto      ()
    );

    edge_buffer #(
        .DEPTH (1024),
        .DW    (48)
    ) u_edge_buffer (
        .CLK_A  (CLK),
        .DATA_A (edge_wdata_w),
        .ADDR_A (edge_waddr_w),
        .WE_A   (edge_we_w),
        .Q_A    (),

        .CLK_B  (CLK),
        .DATA_B ({48{1'b0}}),
        .ADDR_B ({$clog2(1024){1'b0}}),
        .WE_B   (1'b0),
        .Q_B    ()
    );

    vram_dual_clock #(.TOTAL_BYTES(98304)) u_vram (
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

    assign BUSY[SWAP_IDX]             = swap_lock;
    assign BUSY[CLEAN_IDX]            = clear_busy;
    assign BUSY[LOAD_VERTEX_IDX]  = 1'b0;
    assign BUSY[UNKNOWN_1] = 1'b0;
    assign BUSY[LOAD_EDGE_IDX]    = ledge_busy;
    assign BUSY[UNKNOWN_2]   = 1'b0;
    assign BUSY[UNKNOWN_3] = 0;
    assign BUSY[STATUS_IDX]           = 1'b0;
endmodule