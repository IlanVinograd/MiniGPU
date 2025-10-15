`timescale 1ns / 1ps

module cmd_clear #(
    parameter integer FB_BYTES  = 49152,
    parameter [17:0]  BASE_ADDR = 18'd49152
)(
    input  wire        CLK,
    input  wire        rst,
    input  wire        clear_req_pulse,
    input  wire        side,
    input  wire [7:0]  color,

    output reg  [17:0] vram_addr_b,
    output reg  [7:0]  vram_data_b,
    output reg         vram_we_b,
    output reg         BUSY
);

    reg        active;
    reg [17:0] addr;
    reg [17:0] base_latched;
    reg [7:0]  color_latched;

    wire [17:0] back_base = side ? 18'd0 : BASE_ADDR;

    always @(posedge CLK) begin
        if (rst) begin
            BUSY         <= 1'b0;
            active       <= 1'b0;
            addr         <= 18'd0;
            vram_we_b    <= 1'b0;
            vram_addr_b  <= 18'd0;
            vram_data_b  <= 8'h00;
            base_latched <= 18'd0;
            color_latched<= 8'h00;
        end else begin
            vram_we_b <= 1'b0;

            if (clear_req_pulse && !BUSY) begin
                BUSY         <= 1'b1;
                active       <= 1'b1;
                addr         <= 18'd0;
                base_latched <= back_base;
                color_latched<= color;
            end else if (active) begin
                vram_addr_b <= base_latched + addr;
                vram_data_b <= color_latched;
                vram_we_b   <= 1'b1;

                addr <= addr + 1'b1;
                if (addr == FB_BYTES-1) begin
                    BUSY   <= 1'b0;
                    active <= 1'b0;
                end
            end
        end
    end
endmodule