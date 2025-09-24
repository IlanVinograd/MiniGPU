module uart_rx #(
    parameter integer OS = 16
)(
    input  wire CLK,
    input  wire rst,
    input  wire os_tick,    // 16×baud
    input  wire RX,
    output reg  [7:0] data_out,   // принятый байт
    output reg        valid_out,  // импульс на 1 clk
    output reg        framing_err // стоп-бит был не '1'
);



endmodule
