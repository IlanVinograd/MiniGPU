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

    task automatic send_byte(input [7:0] b);
        integer i;
        begin
            RX <= 1'b1; #(BIT_TIME);
            RX <= 1'b0; #(BIT_TIME);
            for (i = 0; i < 8; i = i + 1) begin
                RX <= b[i];
                #(BIT_TIME);
            end
            RX <= 1'b1; #(BIT_TIME);
        end
    endtask

    task automatic swap;
        begin
            send_byte(8'hAA);
            send_byte(8'h02);
            send_byte(8'h01);
            send_byte(8'h2D);
        end
    endtask

    task automatic clear;
        begin
            send_byte(8'hAA);
            send_byte(8'h03);
            send_byte(8'h02);
            send_byte(8'h00);
            send_byte(8'h97);
        end
    endtask

    task automatic clear_color;
        begin
            send_byte(8'hAA);
            send_byte(8'h03);
            send_byte(8'h02);
            send_byte(8'hF0);
            send_byte(8'h49);
        end
    endtask

     task automatic clear_color_two;
        begin
            send_byte(8'hAA);
            send_byte(8'h03);
            send_byte(8'h02);
            send_byte(8'h0F);
            send_byte(8'hBA);
        end
    endtask

    task automatic status;
        begin
            send_byte(8'hAA);
            send_byte(8'h02);
            send_byte(8'h07);
            send_byte(8'h3F);
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

        clear_color();
        swap();
        status();

        swap();
        status();

        clear_color_two();
        swap();
        status();

        #(100*BIT_TIME);
        $finish;
    end
endmodule