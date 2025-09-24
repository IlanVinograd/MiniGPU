`timescale 1ns/1ps

module uart_tb;

  reg  CLK;
  reg  rst;
  reg  RX;
  wire TX;

  wire [7:0] rx_data;
  wire       rx_valid;

  reg  [7:0] tx_data;
  reg        tx_valid;
  wire       tx_ready;

  localparam integer CLK_PERIOD_NS = 10;
  localparam integer BAUD          = 115200;
  localparam integer BIT_NS        = 1_000_000_000 / BAUD;

  uart_core CUT(
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

  initial CLK = 1'b0;
  always #(CLK_PERIOD_NS/2) CLK = ~CLK;

  task automatic send_byte(input [7:0] b);
    integer i;
    begin
      RX = 1'b0; #(BIT_NS);
      for (i = 0; i < 8; i = i + 1) begin
        RX = b[i]; #(BIT_NS);
      end
      RX = 1'b1; #(BIT_NS);
    end
  endtask

  always @(posedge rx_valid) begin
    $display("RX byte: 0x%02h @ %t", rx_data, $time);
  end

  initial begin
    RX       = 1'b1;
    rst      = 1'b1;
    tx_data  = 8'h00;
    tx_valid = 1'b0;

    repeat (8) @(posedge CLK);
    rst = 1'b0;

    #(10*BIT_NS);

    send_byte(8'h55);
    #(2*BIT_NS);
    send_byte(8'hA3);

    #(20*BIT_NS);

    $finish;
  end

endmodule