`timescale 1ns / 1ps

module uart_pc_fpga #(
    parameter ADDR_W   = 17,
    parameter [ADDR_W-1:0] BASE_ADDR = 17'd49152
)(
    input  CLK,
    input  RX,
    input  rst,
    // output TX,
    output HS,
    output VS,
    output [3:0] RED,
    output [3:0] GREEN,
    output [3:0] BLUE
);

wire [7:0] rx_data;
wire       rx_valid;

wire tx_ready_dummy;

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

localparam [7:0] IMG_ONE = 8'ha, IMG_TWO = 8'hf;
reg image = 1'b0;

vga_basic #(.ADDR_W(ADDR_W)) vb (
    .CLK       (CLK),
    .BASE_ADDR (image ? BASE_ADDR : {ADDR_W{1'b0}}),
    .HS        (HS),
    .VS        (VS),
    .RED       (RED),
    .GREEN     (GREEN),
    .BLUE      (BLUE)
);

always @(posedge CLK) begin
    if (rst) image <= 1'b0;

    else if (rx_valid) begin
        case (rx_data)
            "A","a": image <= 1'b0;
            "F","f": image <= 1'b1;
        endcase
    end
end

endmodule