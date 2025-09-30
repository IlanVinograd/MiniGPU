`timescale 1ns/1ps

module uart_tx (
    input  wire CLK,
    input  wire rst,
    input  wire bit_tick,      // 1×baud
    input  wire [7:0] data_in,
    input  wire valid_in,
    output reg  ready,
    output reg  TX
);

    localparam S_IDLE=2'd0, S_START=2'd1, S_DATA=2'd2, S_STOP=2'd3;
    reg [1:0] state;
    reg [2:0] bit_idx;
    reg [7:0] shreg;

    reg valid_d;
    wire valid_pulse = valid_in & ~valid_d;

    always @(posedge CLK) begin
        if (rst) begin
            ready    <= 1'b1;
            TX       <= 1'b1;
            bit_idx  <= 3'd0;
            shreg    <= 8'h00;
            state    <= S_IDLE;
            valid_d  <= 1'b0;
        end else begin
            valid_d <= valid_in;

            case (state)
                S_IDLE: begin
                    TX    <= 1'b1;
                    ready <= 1'b1;
                    if (valid_pulse) begin
                        shreg   <= data_in;
                        bit_idx <= 3'd0;
                        ready   <= 1'b0;
                        state   <= S_START;
                    end
                end

                S_START: begin
                    if (bit_tick) begin
                        TX    <= 1'b0;
                        state <= S_DATA;
                    end
                end

                S_DATA: begin
                    if (bit_tick) begin
                        TX      <= shreg[0];
                        shreg   <= {1'b0, shreg[7:1]};
                        if (bit_idx == 3'd7) begin
                            state <= S_STOP;
                        end
                        bit_idx <= bit_idx + 3'd1;
                    end
                end

                S_STOP: begin
                    if (bit_tick) begin
                        TX    <= 1'b1;
                        ready <= 1'b1;
                        state <= S_IDLE;
                    end
                end

                default: state <= S_IDLE;
            endcase
        end
    end
endmodule