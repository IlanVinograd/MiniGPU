module uart_tx #(
    parameter integer BAUD    = 115200
)(
    input  wire CLK,
    input  wire rst,
    input  wire bit_tick,      // 1×baud
    input  wire [7:0] data_in, // байт на отправку
    input  wire valid_in,      // импульс: "в линию data_in"
    output reg  ready,         // =1: можно давать следующий байт
    output reg  TX            // на пин TX (idle=1)
);



endmodule
