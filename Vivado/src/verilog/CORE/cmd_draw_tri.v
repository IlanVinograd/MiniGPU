`timescale 1ns/1ps
/*
AA   04   06    XX   XX  CRC
│    │     │    │    |
│    │     │    ------
|    |     |      |
│    │     │    which edge to draw 2 bytes
│    │     opcode (CMD_DRAW_TRI = 0x06)
│    LEN = 0x04 
SYNC (0xAA)
*/

module cmd_draw_tri #(
    parameter integer DEPTH = 1024,
    parameter integer DW_VERTEX = 64,
    parameter integer DW_EDGE = 48
)(
    input CLK,
    input rst,
    input draw_req_pulse,
    input [15:0] edge_addr,
    input [DW_EDGE-1:0] edge_data,
    input [DW_VERTEX-1:0] vertex_data,
    output reg [$clog2(DEPTH)-1:0] ADDR_EDGE,
    output reg WE_EDGE,
    output reg [$clog2(DEPTH)-1:0] ADDR_VERTEX,
    output reg WE_VERTEX,
    output reg BUSY
);
    localparam integer ADDR_W = $clog2(DEPTH);

    reg [3:0] stage;
    reg [15:0] edge_addr_lat;
    reg [DW_EDGE-1:0] edge_data_lat;
    reg [DW_VERTEX-1:0] vertex_data_lat [2:0];

    always @(posedge CLK) begin
        if (rst) begin
            ADDR_EDGE   <= {ADDR_W{1'b0}};
            ADDR_VERTEX <= {ADDR_W{1'b0}};
            WE_EDGE     <= 1'b0;
            WE_VERTEX   <= 1'b0;
            BUSY        <= 1'b0;
            stage       <= 4'd0;
            edge_addr_lat <= 16'd0;
            edge_data_lat <= {DW_EDGE{1'b0}};
            vertex_data_lat[0] <= {DW_VERTEX{1'b0}};
            vertex_data_lat[1] <= {DW_VERTEX{1'b0}};
            vertex_data_lat[2] <= {DW_VERTEX{1'b0}};
        end else begin
            WE_EDGE   <= 1'b0;
            WE_VERTEX <= 1'b0;

            case (stage)
                4'd0: begin
                    if (draw_req_pulse && !BUSY) begin
                        BUSY <= 1'b1;
                        edge_addr_lat <= edge_addr;
                        ADDR_EDGE <= (edge_addr >= DEPTH) ? (DEPTH - 1) : edge_addr[ADDR_W-1:0];
                        stage <= 4'd1;
                    end
                end

                4'd1: begin
                    edge_data_lat <= edge_data;
                    stage <= 4'd2;
                end

                4'd2: begin
                    ADDR_VERTEX <= edge_data_lat[ADDR_W-1:0];
                    stage <= 4'd3;
                end
                4'd3: begin
                    stage <= 4'd4;
                end

                4'd4: begin
                    vertex_data_lat[0] <= vertex_data;
                    ADDR_VERTEX <= edge_data_lat[16 + ADDR_W - 1 -: ADDR_W];
                    stage <= 4'd5;
                end
                4'd5: begin
                    stage <= 4'd6;
                end

                4'd6: begin
                    vertex_data_lat[1] <= vertex_data;
                    ADDR_VERTEX <= edge_data_lat[32 + ADDR_W - 1 -: ADDR_W];
                    stage <= 4'd7;
                end
                4'd7: begin
                    stage <= 4'd8;
                end

                4'd8: begin
                    vertex_data_lat[2] <= vertex_data;
                    stage <= 4'd9;
                end

                4'd9: begin
                    BUSY  <= 1'b0;
                    stage <= 4'd0;
                end

                default: stage <= 4'd0;
            endcase
        end
    end
endmodule