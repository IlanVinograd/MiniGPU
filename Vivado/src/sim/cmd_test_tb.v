`timescale 1ns/1ps

module cmd_test_tb;
    localparam integer CLK_PERIOD_NS = 10;
    localparam integer FCLK_HZ       = 100_000_000;
    localparam integer BAUD          = 3_125_000;
    localparam real    BIT_TIME      = 1e9 / BAUD;

    reg  CLK = 1'b0;
    reg  RX  = 1'b1;
    reg  rst = 1'b1;

    wire HS;
    wire VS;
    wire [3:0] RED;
    wire [3:0] GREEN;
    wire [3:0] BLUE;
    wire TX;

    always #(CLK_PERIOD_NS/2) CLK = ~CLK;

    uart_pc_fpga DUT (
        .CLK   (CLK),
        .RX    (RX),
        .rst   (rst),
        .HS    (HS),
        .VS    (VS),
        .RED   (RED),
        .GREEN (GREEN),
        .BLUE  (BLUE),
        .TX    (TX)
    );

    pullup pu_TX (TX);

    initial begin
        $timeformat(-9, 3, " ns", 10);
        $display("---- CMD TB started @ %t ----", $time);
    end

    initial begin : TX_SNIFFER
        integer i;
        reg [7:0] byte_accum;
        @(negedge rst);
        forever begin
            @(negedge TX);
            #(BIT_TIME + BIT_TIME/2.0);
            byte_accum = 8'h00;
            for (i = 0; i < 8; i = i + 1) begin
                byte_accum[i] = TX;
                #(BIT_TIME);
            end
            #(BIT_TIME);
            $display("[%t] FPGA->PC  TX: 0x%02h (%0d)", $time, byte_accum, byte_accum);
        end
    end

    reg VS_q = 1'b0, HS_q = 1'b0;
    always @(posedge CLK) begin
        VS_q <= VS;
        HS_q <= HS;
        if (VS & ~VS_q) $display("[%t] VSYNC ↑ (new frame)", $time);
    end

    task automatic log_hdr(input [127:0] txt);
        begin
            $display("");
            $display("[%t] ==== %0s ====", $time, txt);
        end
    endtask

    task automatic send_byte(input [7:0] b);
        integer i;
        begin
            RX <= 1'b1; #(BIT_TIME/4.0);
            RX <= 1'b0; #(BIT_TIME);
            for (i = 0; i < 8; i = i + 1) begin
                RX <= b[i];
                #(BIT_TIME);
            end
            RX <= 1'b1; #(BIT_TIME);
            $display("[%t] PC->FPGA RX: 0x%02h (%0d)", $time, b, b);
        end
    endtask

    task automatic swap;
        begin
            log_hdr("SWAP");
            send_byte(8'hAA);
            send_byte(8'h02);
            send_byte(8'h01);
            send_byte(8'h2D);
        end
    endtask

    task automatic clear;
        begin
            log_hdr("CLEAR color=0x00");
            send_byte(8'hAA);
            send_byte(8'h03);
            send_byte(8'h02);
            send_byte(8'h00);
            send_byte(8'h97);
        end
    endtask

    task automatic clear_color;
        begin
            log_hdr("CLEAR color=0xF0");
            send_byte(8'hAA);
            send_byte(8'h03);
            send_byte(8'h02);
            send_byte(8'hF0);
            send_byte(8'h49);
        end
    endtask

    task automatic clear_color_two;
        begin
            log_hdr("CLEAR color=0x0F");
            send_byte(8'hAA);
            send_byte(8'h03);
            send_byte(8'h02);
            send_byte(8'h0F);
            send_byte(8'hBA);
        end
    endtask

    task automatic status;
        begin
            log_hdr("STATUS");
            send_byte(8'hAA);
            send_byte(8'h02);
            send_byte(8'h07);
            send_byte(8'h3F);
        end
    endtask

    task automatic load_edge;
        begin
            log_hdr("LOAD_EDGE (head, cmd=0x05, START=0x0000, COUNT=3)");
            send_byte(8'hAA);
            send_byte(8'h17);
            send_byte(8'h05);
            send_byte(8'h03);
            send_byte(8'h00);
            send_byte(8'h00);
            send_byte(8'h00); send_byte(8'h11);
            send_byte(8'h00); send_byte(8'h22);
            send_byte(8'h00); send_byte(8'h33);
            send_byte(8'h00); send_byte(8'h44);
            send_byte(8'h00); send_byte(8'h55);
            send_byte(8'h00); send_byte(8'h66);
            send_byte(8'h00); send_byte(8'h77);
            send_byte(8'h00); send_byte(8'h88);
            send_byte(8'h00); send_byte(8'h99);
            send_byte(8'h05);
        end
    endtask

    task automatic load_edge_cont;
        begin
            log_hdr("LOAD_EDGE_CONT (cmd=0x05, START=0x0004, COUNT=3)");
            send_byte(8'hAA);
            send_byte(8'h17);
            send_byte(8'h05);
            send_byte(8'h03);
            send_byte(8'h00);
            send_byte(8'h04);
            send_byte(8'h00); send_byte(8'h88);
            send_byte(8'h00); send_byte(8'h77);
            send_byte(8'h00); send_byte(8'h66);
            send_byte(8'h00); send_byte(8'h55);
            send_byte(8'h00); send_byte(8'h44);
            send_byte(8'h00); send_byte(8'h33);
            send_byte(8'h00); send_byte(8'h22);
            send_byte(8'h00); send_byte(8'h11);
            send_byte(8'h00); send_byte(8'hFF);
            send_byte(8'h85);
        end
    endtask

    task automatic load_vertex_begin;
        begin
            log_hdr("LOAD_VERTEX_BEGIN (cmd=0x03, START=0x0010, COUNT=2)");
            send_byte(8'hAA);
            send_byte(8'h15);
            send_byte(8'h03);
            send_byte(8'h02);
            send_byte(8'h00);
            send_byte(8'h10);
            send_byte(8'h00); send_byte(8'h64);
            send_byte(8'h00); send_byte(8'hC8);
            send_byte(8'h00); send_byte(8'h00);
            send_byte(8'hE3);
            send_byte(8'h10);
            send_byte(8'h00); send_byte(8'h32);
            send_byte(8'h00); send_byte(8'h96);
            send_byte(8'h00); send_byte(8'h00);
            send_byte(8'h4F);
            send_byte(8'h20);
            send_byte(8'h22);
        end
    endtask

    task automatic load_vertex_begin_alt;
        begin
            log_hdr("LOAD_VERTEX_BEGIN (cmd=0x03, START=0x0004, COUNT=3)");
            send_byte(8'hAA);
            send_byte(8'h1D);
            send_byte(8'h03);
            send_byte(8'h03);
            send_byte(8'h00);
            send_byte(8'h04);
            send_byte(8'h00); send_byte(8'h10);
            send_byte(8'h00); send_byte(8'h20);
            send_byte(8'h00); send_byte(8'h30);
            send_byte(8'hA5);
            send_byte(8'h01);
            send_byte(8'h00); send_byte(8'h40);
            send_byte(8'h00); send_byte(8'h50);
            send_byte(8'h00); send_byte(8'h60);
            send_byte(8'h5A);
            send_byte(8'h0F);
            send_byte(8'h00); send_byte(8'h70);
            send_byte(8'h00); send_byte(8'h80);
            send_byte(8'h00); send_byte(8'h90);
            send_byte(8'hF0);
            send_byte(8'h07);
            send_byte(8'h9F);
        end
    endtask

    initial begin
        rst = 1'b1;
        #(10*CLK_PERIOD_NS);
        rst = 1'b0;
        #(20*CLK_PERIOD_NS);
        #(5*BIT_TIME);

        clear();
        swap();
        status();

        load_vertex_begin();
        load_vertex_begin_alt();
        load_edge();
        load_edge_cont();
        swap();
        status();

        load_vertex_begin();
        load_vertex_begin_alt();
        load_edge();
        load_edge_cont();
        swap();
        status();

        #(100*BIT_TIME);
        $display("---- CMD TB finished @ %t ----", $time);
        $finish;
    end
endmodule