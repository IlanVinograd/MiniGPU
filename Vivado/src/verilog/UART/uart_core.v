module uart_core #(
    parameter integer FCLK_HZ = 100_000_000,
    parameter integer BAUD    = 115200
)(
    input  wire CLK,
    input  wire rst,
    input  wire RX,
    output wire TX,

    output wire [7:0] rx_data,
    output wire       rx_valid,

    input  wire [7:0] tx_data,
    input  wire       tx_valid,
    output wire       tx_ready
);

    wire bit_tick, os_tick;

    baud_gen #(
        .FCLK_HZ(FCLK_HZ),
        .BAUD(BAUD),
        .OS(16)
    ) u_baud (
        .CLK(CLK),
        .rst(rst),
        .bit_tick(bit_tick),
        .os_tick(os_tick)
    );

    uart_rx #(
        .OS(16)
    ) u_rx (
        .CLK(CLK),
        .rst(rst),
        .os_tick(os_tick),
        .RX(RX),
        .data_out(rx_data),
        .valid_out(rx_valid),
        .framing_err()
    );

    uart_tx u_tx (
        .CLK(CLK),
        .rst(rst),
        .bit_tick(bit_tick),
        .data_in(tx_data),
        .valid_in(tx_valid),
        .ready(tx_ready),
        .TX(TX)
    );

endmodule
