`timescale 1ns/1ps

module packet_assembler #(
    parameter integer SIZE = 256,
    parameter [7:0]   SYNC = 8'hAA
)(
    input              CLK,
    input              rst,
    input      [7:0]   rx_data,
    input              rx_valid,
    input              fifo_ready,
    input              fifo_full,
    output reg [8*SIZE-1:0] packet,
    output reg         valid_packet,
    // output reg  [8:0]  packet_len,
    output reg         err_len,
    output reg         err_crc
);

    localparam S_WAIT = 3'd0;
    localparam S_LEN  = 3'd1;
    localparam S_BODY = 3'd2;
    localparam S_DONE = 3'd3;

    reg [2:0]  state = S_WAIT;
    reg [7:0]  len_reg = 8'd0;
    reg [8:0]  idx = 9'd0;
    reg [7:0]  crc = 8'd0;
    reg [7:0]  rx_crc = 8'd0;

    reg [7:0]  buffer [0:SIZE-1];
    integer k;

    function [7:0] crc8_next;
        input [7:0] c;
        input [7:0] d;
        integer i; reg [7:0] x;
        begin
            x = c ^ d;
            for (i = 0; i < 8; i = i + 1)
                x = x[7] ? ((x << 1) ^ 8'h07) : (x << 1);
            crc8_next = x;
        end
    endfunction

    always @(posedge CLK) begin
        if (rst) begin
            state <= S_WAIT;
            len_reg <= 8'd0;
            idx <= 9'd0;
            crc <= 8'd0;
            rx_crc <= 8'd0;
            valid_packet <= 1'b0;
            // packet_len <= 9'd0;
            err_len <= 1'b0;
            err_crc <= 1'b0;
            packet <= {8*SIZE{1'b0}};
        end else begin
            valid_packet <= 1'b0;
            err_len <= 1'b0;
            err_crc <= 1'b0;

            case (state)
                S_WAIT: begin
                    if (rx_valid && rx_data == SYNC) begin
                        buffer[0] <= SYNC;
                        idx <= 9'd1;
                        crc <= 8'd0;
                        state <= S_LEN;
                    end
                end

                S_LEN: begin
                    if (rx_valid) begin
                        len_reg   <= rx_data;
                        buffer[1] <= rx_data;
                        crc       <= crc8_next(8'd0, rx_data);
                        if (rx_data < 8'd2 || (2 + rx_data) > SIZE) begin
                            err_len <= 1'b1;
                            state   <= S_WAIT;
                            idx     <= 9'd0;
                        end else begin
                            idx   <= 9'd2;
                            state <= S_BODY;
                        end
                    end
                end

                S_BODY: begin
                    if (rx_valid) begin
                        buffer[idx] <= rx_data;
                        if (idx < (2 + len_reg - 1)) crc <= crc8_next(crc, rx_data);
                        else rx_crc <= rx_data;
                        idx <= idx + 1'b1;
                        if (idx == (2 + len_reg - 1)) state <= S_DONE;
                    end
                end

                S_DONE: begin
                    if (rx_crc == crc) begin
                        for (k = 0; k < SIZE; k = k + 1)
                            packet[8*k +: 8] <= (k < (2 + len_reg)) ? buffer[k] : 8'h00;

                        if (fifo_ready && !fifo_full) begin
                            valid_packet <= 1'b1;
                            state        <= S_WAIT;
                            idx          <= 9'd0;
                        end else begin
                            valid_packet <= 1'b0;
                            state        <= S_DONE;
                        end
                    end else begin
                        err_crc <= 1'b1;
                        state   <= S_WAIT;
                        idx     <= 9'd0;
                    end
                end


                default: state <= S_WAIT;
            endcase
        end
    end
endmodule