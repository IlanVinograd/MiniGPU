`timescale 1ns/1ps

module uart_tb;
  localparam integer CLK_PERIOD_NS = 10;
  localparam integer FCLK_HZ       = 100_000_000;
  localparam integer BAUD          = 3_125_000;
  localparam integer OS            = 16;
  localparam integer BIT_CLKS      = FCLK_HZ / BAUD;

  reg  CLK = 1'b0;
  reg  rst = 1'b1;

  wire [7:0] rx_data;
  wire       rx_valid;

  wire [8*256-1:0] pkt_bus;
  wire             pkt_valid;
  wire [8:0]       pkt_len;
  wire             err_len, err_crc;

  reg  rx_line;
  wire RX;
  assign RX = rx_line;

  uart_core #(
    .FCLK_HZ(FCLK_HZ),
    .BAUD   (BAUD),
    .OS     (OS)
  ) DUT (
    .CLK(CLK),
    .rst(rst),
    .RX(RX),
    .TX(),
    .rx_data(rx_data),
    .rx_valid(rx_valid),
    .tx_data(8'h00),
    .tx_valid(1'b0),
    .tx_ready()
  );

  packet_assembler #(
    .SIZE(256),
    .SYNC(8'hAA)
  ) PA (
    .CLK(CLK),
    .rst(rst),
    .data_out(rx_data),
    .valid_out(rx_valid),
    .fifo_ready(1'b1),
    .fifo_full(1'b0),
    .packet(pkt_bus),
    .valid_packet(pkt_valid),
    .packet_len(pkt_len),
    .err_len(err_len),
    .err_crc(err_crc)
  );

  always #(CLK_PERIOD_NS/2) CLK = ~CLK;

  function [7:0] crc8_next;
    input [7:0] c, d;
    integer i; reg [7:0] x;
    begin
      x = c ^ d;
      for (i=0;i<8;i=i+1)
        x = x[7] ? ((x<<1)^8'h07) : (x<<1);
      crc8_next = x;
    end
  endfunction

  task uart_tx_byte;
    input [7:0] b;
    integer i;
    begin
      rx_line <= 1'b0;
      repeat (BIT_CLKS) @(posedge CLK);
      for (i=0;i<8;i=i+1) begin
        rx_line <= b[i];
        repeat (BIT_CLKS) @(posedge CLK);
      end
      rx_line <= 1'b1;
      repeat (BIT_CLKS) @(posedge CLK);
    end
  endtask

  reg [7:0] args_mem [0:255];
  reg [7:0] exp_frame [0:63][0:255];
  reg [8:0] exp_len_q [0:63];
  integer   exp_q_wr, exp_q_rd;

  task exp_push_byte;
    input integer frame_id;
    input integer pos;
    input [7:0] b;
    begin
      exp_frame[frame_id][pos] = b;
    end
  endtask

  task send_packet;
    input [7:0] opcode;
    input integer arg_len;
    integer i, f, p;
    reg [7:0] len_b;
    reg [7:0] crc;
    begin
      f = exp_q_wr;
      p = 0;

      len_b = (1 + arg_len + 1);
      crc   = 8'h00;
      exp_push_byte(f, p, 8'hAA);                      p = p + 1;
      exp_push_byte(f, p, len_b);  crc = crc8_next(8'h00, len_b); p = p + 1;
      exp_push_byte(f, p, opcode); crc = crc8_next(crc, opcode);  p = p + 1;
      for (i=0;i<arg_len;i=i+1) begin
        exp_push_byte(f, p, args_mem[i]);
        crc = crc8_next(crc, args_mem[i]);
        p   = p + 1;
      end
      exp_push_byte(f, p, crc);
      exp_len_q[f] = p + 1;
      exp_q_wr     = exp_q_wr + 1;

      $display("TB: frame=%0d len=%0d opcode=%02x CRC=%02x",
               f, exp_len_q[f], opcode, crc);

      for (i=0; i<exp_len_q[f]; i=i+1)
        uart_tx_byte(exp_frame[f][i]);
    end
  endtask

  integer pkts_seen;
  always @(posedge CLK) begin
    if (pkt_valid) begin
      pkts_seen <= pkts_seen + 1;
      if (err_len || err_crc) $fatal;
    end
  end

  integer i_print, mismatch_idx, k;
  reg [8:0] exp_len_cur;
  reg stop_cmp;

  always @(posedge CLK) begin
    if (pkt_valid) begin
      exp_len_cur = exp_len_q[exp_q_rd];

      $display("[%0t] PKT FPGA len=%0d  EXP len=%0d (frame=%0d)",
               $time, pkt_len, exp_len_cur, exp_q_rd);

      $write("FPGA: ");
      for (i_print=0;i_print<pkt_len;i_print=i_print+1) $write("%02x ", pkt_bus[8*i_print +: 8]);
      $write("\n");

      $write("EXP : ");
      for (i_print=0;i_print<exp_len_cur;i_print=i_print+1) $write("%02x ", exp_frame[exp_q_rd][i_print]);
      $write("\n");

      mismatch_idx = -1;
      stop_cmp = 0;
      if (pkt_len !== exp_len_cur) mismatch_idx = 0;
      else begin
        for (k=0; k<pkt_len; k=k+1) begin
          if (!stop_cmp && (pkt_bus[8*k +: 8] !== exp_frame[exp_q_rd][k])) begin
            mismatch_idx = k;
            stop_cmp = 1;
          end
        end
      end

      if (mismatch_idx >= 0) begin
        $display("MISMATCH at byte %0d: FPGA=%02x EXP=%02x",
                 mismatch_idx,
                 pkt_bus[8*mismatch_idx +: 8],
                 exp_frame[exp_q_rd][mismatch_idx]);
        $fatal;
      end else begin
        $display("MATCH");
      end

      exp_q_rd = exp_q_rd + 1;
    end
  end

  integer i;
  integer j;
  initial begin
    rx_line   = 1'b1;
    pkts_seen = 0;
    exp_q_wr  = 0;
    exp_q_rd  = 0;

    for (i=0;i<64;i=i+1) begin
      exp_len_q[i] = 0;
      for (j=0;j<256;j=j+1) exp_frame[i][j] = 8'h00;
    end

    repeat (20) @(posedge CLK);
    rst = 1'b0;
    repeat (20) @(posedge CLK);

    args_mem[0] = 8'h0F;
    send_packet(8'h01, 1);

    args_mem[0]=8'h0A; args_mem[1]=8'h00;
    args_mem[2]=8'h14; args_mem[3]=8'h00;
    args_mem[4]=8'h1E; args_mem[5]=8'h00;
    args_mem[6]=8'h28; args_mem[7]=8'h00;
    args_mem[8]=8'h05;
    send_packet(8'h03, 9);

    args_mem[0] = 8'hFF;
    send_packet(8'h20, 1);

    repeat (2_000_000) @(posedge CLK);
    if (pkts_seen < 3) $fatal;
    $finish;
  end
endmodule