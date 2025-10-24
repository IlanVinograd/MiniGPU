`timescale 1ns / 1ps

module cmd_status (
    input  wire       CLK,
    input  wire       rst,
    input  wire       status_req,
    input  wire [7:0] BUSY_STATUS,
    input  wire       tx_ready,
    output reg        BUSY,
    output reg [7:0]  tx_data,
    output reg        tx_valid
);

    reg status_req_d;
    wire status_req_pulse = status_req & ~status_req_d;

    localparam S_IDLE = 1'b0, S_SEND = 1'b1;
    reg state;

    always @(posedge CLK) begin
        if (rst) begin
            status_req_d <= 1'b0;
        end else begin
            status_req_d <= status_req;
        end
    end

    always @(posedge CLK) begin
        if (rst) begin
            state    <= S_IDLE;
            BUSY     <= 1'b0;
            tx_data  <= 8'h00;
            tx_valid <= 1'b0;
        end else begin
            tx_valid <= 1'b0;

            case (state)
                S_IDLE: begin
                    BUSY <= 1'b0;
                    if (status_req_pulse || status_req) begin
                        BUSY    <= 1'b1;
                        tx_data <= BUSY_STATUS;
                        state   <= S_SEND;
                    end
                end

                S_SEND: begin
                    BUSY <= 1'b1;
                    if (tx_ready) begin
                        tx_valid <= 1'b1;
                        state    <= S_IDLE;
                    end
                end
            endcase
        end
    end

endmodule