module uart_tx #(
    parameter integer BAUD    = 115200
)(
    input  wire CLK,
    input  wire rst,
    input  wire bit_tick,      // 1×baud
    input  wire [7:0] data_in,
    input  wire valid_in,
    output reg  ready,
    output reg  TX
);



endmodule
