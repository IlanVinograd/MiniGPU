`timescale 1ns/1ps

module uart_rx #(
    parameter integer OS = 16
)(
    input  wire CLK,
    input  wire rst,
    input  wire os_tick,    // 16×baud
    input  wire RX,
    output reg  [7:0] data_out,
    output reg        valid_out,
    output reg        framing_err
);
    reg [7:0] sh;
    reg [$clog2(OS)-1:0] os_cnt;
    reg [2:0]            bit_idx;

    localparam S_IDLE=2'd0, S_START=2'd1, S_DATA=2'd2, S_STOP=2'd3;
    reg [1:0] state;

    (* ASYNC_REG="TRUE" *) reg rx_meta=1'b1, rx_sync=1'b1;
    always @(posedge CLK) begin
        rx_meta <= RX;
        rx_sync <= rx_meta;
    end

    always @(posedge CLK) begin
        if (rst) begin
            valid_out   <= 0;
            framing_err <= 0;
            state <=  S_IDLE;
            os_cnt<=0; 
            bit_idx<=0; 
            sh<=0;
        end else begin
            valid_out<=0;
            framing_err<=0;
            if (os_tick) begin

                case (state) 

                    S_IDLE: begin
                        if(rx_sync == 1'b0) begin
                            os_cnt <= OS/2;
                            state  <= S_START;
                        end
                    end

                    S_START: begin
                        if (os_cnt == 0) begin
                        if (rx_sync == 1'b0) begin
                            bit_idx <= 3'd0;
                            os_cnt  <= OS-1;
                            state   <= S_DATA;
                        end else begin
                            state   <= S_IDLE;
                        end
                        end else begin
                            os_cnt <= os_cnt - 1'b1;
                        end
                    end

                    S_DATA: begin
                        if (os_cnt == 0) begin
                            sh     <= {rx_sync, sh[7:1]};
                            os_cnt <= OS-1;
                        if (bit_idx == 3'd7) state <= S_STOP;
                        else                bit_idx <= bit_idx + 1'b1;
                        end else begin
                            os_cnt <= os_cnt - 1'b1;
                        end
                    end
                    
                    S_STOP: begin
                        if (os_cnt == 0) begin
                        if (rx_sync == 1'b1) begin
                            data_out   <= sh;
                            valid_out  <= 1'b1;
                        end else begin
                            framing_err <= 1'b1;
                        end
                            state <= S_IDLE;
                        end else begin
                            os_cnt <= os_cnt - 1'b1;
                        end
                    end
                endcase
            end
        end

    end

endmodule
