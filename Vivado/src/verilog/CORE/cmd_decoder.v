`timescale 1ns / 1ps

module cmd_decoder (
    input  wire        CLK,
    input  wire        rst,
    input  wire        packet_ready,
    input  wire [7:0]  opcode,
    input  wire [7:0]  BUSY,
    output reg  [7:0]  CMD
);

    localparam integer SWAP_IDX              = 0;
    localparam integer CLEAN_IDX             = 1;

    localparam integer LOAD_VERTEX_BEG_IDX   = 2;
    localparam integer LOAD_VERTEX_CONT_IDX  = 3;

    localparam integer LOAD_EDGE_BEG_IDX     = 4;
    localparam integer LOAD_EDGE_CONT_IDX    = 5;


    localparam [7:0] CMD_SWAP                = 8'h01;
    localparam [7:0] CMD_CLEAN               = 8'h02;

    localparam [7:0] CMD_LOAD_VERTEX_BEGIN   = 8'h03;
    localparam [7:0] CMD_LOAD_VERTEX_CONT    = 8'h04;

    localparam [7:0] CMD_LOAD_EDGE_BEGIN     = 8'h05;
    localparam [7:0] CMD_LOAD_EDGE_CONT      = 8'h06;

    always @(posedge CLK) begin
        if (rst) begin
            CMD <= 8'b0;
        end else begin
            CMD <= 8'b0;

            if (packet_ready) begin
                case (opcode)
                    CMD_SWAP:  if (!BUSY[SWAP_IDX])   CMD[SWAP_IDX]   <= 1'b1;
                    CMD_CLEAN: if (!BUSY[CLEAN_IDX])  CMD[CLEAN_IDX]  <= 1'b1;

                    CMD_LOAD_VERTEX_BEGIN: if (!BUSY[LOAD_VERTEX_BEG_IDX])  CMD[LOAD_VERTEX_BEG_IDX]  <= 1'b1;
                    CMD_LOAD_VERTEX_CONT:  if ( BUSY[LOAD_VERTEX_BEG_IDX])  CMD[LOAD_VERTEX_CONT_IDX] <= 1'b1;
                    CMD_LOAD_EDGE_BEGIN:   if (!BUSY[LOAD_EDGE_BEG_IDX])    CMD[LOAD_EDGE_BEG_IDX]    <= 1'b1;
                    CMD_LOAD_EDGE_CONT:    if ( BUSY[LOAD_EDGE_BEG_IDX])    CMD[LOAD_EDGE_CONT_IDX]   <= 1'b1;

                    default: ;
                endcase
            end
        end
    end
endmodule