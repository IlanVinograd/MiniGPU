`timescale 1ns/1ps

module uart_tb;
  localparam integer CLK_PERIOD_NS = 10;
  localparam integer FCLK_HZ       = 100_000_000;
  localparam integer BAUD          = 115200;

  reg  CLK = 1'b0;
  reg  rst = 1'b1;

  wire TX;
  wire RX;

  wire [7:0] rx_data;
  wire       rx_valid;

  reg  [7:0] tx_data;
  reg        tx_valid;
  wire       tx_ready;

  uart_core #(.FCLK_HZ(FCLK_HZ), .BAUD(BAUD)) DUT (
    .CLK(CLK),
    .rst(rst),
    .RX(RX),
    .TX(TX),
    .rx_data(rx_data),
    .rx_valid(rx_valid),
    .tx_data(tx_data),
    .tx_valid(tx_valid),
    .tx_ready(tx_ready)
  );

  assign RX = TX;

  always #(CLK_PERIOD_NS/2) CLK = ~CLK;

  reg [7:0] exp [0:1023];
  integer wr_ptr = 0;
  integer rd_ptr = 0;
  integer total  = 0;

  reg [7:0] pkt0 [0:31];
  reg [7:0] pkt1 [0:47];
  reg [7:0] pkt2 [0:63];
  
  task automatic push_exp(input [7:0] b);
  begin
    exp[wr_ptr] = b;
    wr_ptr = wr_ptr + 1;
    total  = total + 1;
  end
  endtask

  task automatic send_byte(input [7:0] b);
  begin
    @(posedge CLK);
    wait (tx_ready);
    @(posedge CLK);
    tx_data  <= b;
    tx_valid <= 1'b1;
    @(posedge CLK);
    tx_valid <= 1'b0;
  end
  endtask

  task automatic send_packet(input [7:0] cmd, input integer len, input integer base_idx, input integer which);
    integer i;
    reg [7:0] sum;
  begin
    $display("[%0t] PKT start cmd=%02h len=%0d", $time, cmd, len);
    sum = 8'h00;
    send_byte(8'hAA); push_exp(8'hAA); sum = sum + 8'hAA;
    send_byte(cmd);   push_exp(cmd);   sum = sum + cmd;
    send_byte(len[7:0]); push_exp(len[7:0]); sum = sum + len[7:0];
    for (i = 0; i < len; i = i + 1) begin
      case (which)
        0: begin send_byte(pkt0[base_idx + i]); push_exp(pkt0[base_idx + i]); sum = sum + pkt0[base_idx + i]; end
        1: begin send_byte(pkt1[base_idx + i]); push_exp(pkt1[base_idx + i]); sum = sum + pkt1[base_idx + i]; end
        default: begin send_byte(pkt2[base_idx + i]); push_exp(pkt2[base_idx + i]); sum = sum + pkt2[base_idx + i]; end
      endcase
    end
    send_byte(sum); push_exp(sum);
    $display("[%0t] PKT end cmd=%02h", $time, cmd);
  end
  endtask

  always @(posedge CLK) begin
    if (rx_valid) begin
      if (rx_data !== exp[rd_ptr]) begin
        $display("[%0t] RX[%0d]=%02h EXPECT=%02h FAIL", $time, rd_ptr, rx_data, exp[rd_ptr]);
        $fatal;
      end
      $display("[%0t] RX[%0d]=%02h OK", $time, rd_ptr, rx_data);
      rd_ptr <= rd_ptr + 1;
    end
  end

  initial begin : init_payloads
    integer i;
    for (i = 0; i < 32; i = i + 1) pkt0[i] = 8'h10 + i[7:0];
    for (i = 0; i < 48; i = i + 1) pkt1[i] = (i * 7) & 8'hFF;
    for (i = 0; i < 64; i = i + 1) pkt2[i] = 8'hC0 ^ i[7:0];
  end

  initial begin : run
    tx_data  = 8'h00;
    tx_valid = 1'b0;
    $display("[%0t] RESET", $time);
    repeat (20) @(posedge CLK);
    rst = 1'b0;
    $display("[%0t] RUN", $time);
    repeat (20) @(posedge CLK);

    send_packet(8'h01, 16, 0, 0);
    send_packet(8'h02, 32, 0, 1);
    send_packet(8'h03, 48, 0, 2);
    send_packet(8'h10, 8,  8, 0);
    send_packet(8'h20, 16, 16, 1);
    send_packet(8'h30, 32, 16, 2);

    fork
      begin : guard_blk
        integer guard;
        guard = 0;
        while (rd_ptr < total) begin
          @(posedge CLK);
          guard = guard + 1;
          if (guard > 200_000_000) begin
            $display("[%0t] TIMEOUT", $time);
            $fatal;
          end
        end
        $display("[%0t] PASS bytes=%0d", $time, total);
        $finish;
      end
      begin : hard_timeout
        repeat (50_000_000) @(posedge CLK);
        $display("[%0t] HARD TIMEOUT", $time);
        $fatal;
      end
    join
  end

endmodule