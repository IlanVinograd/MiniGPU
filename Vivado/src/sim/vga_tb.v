`timescale 1ns/1ps

module vga_tb;

  reg  CLK = 0;
  wire HS, VS;
  wire [3:0] RED, GREEN, BLUE;

  vga_basic CUT(.CLK(CLK), .HS(HS), .VS(VS), .RED(RED), .GREEN(GREEN), .BLUE(BLUE));

  localparam integer CLK_PERIOD_NS = 40;
  always #(CLK_PERIOD_NS/2) CLK = ~CLK;

  initial begin
    #50_000_000;
    $finish;
  end

endmodule

module clk_wiz_0(input clk_in1, input reset, output clk_out1, output locked);
      assign clk_out1 = clk_in1;
      assign locked   = 1'b1;
endmodule