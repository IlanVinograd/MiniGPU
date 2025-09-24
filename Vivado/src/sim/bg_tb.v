`timescale 1ns/1ps

module bg_tb;

    reg CLK = 0;
    reg rst = 0;
    wire bit_tick;
    wire os_tick;

    baud_gen bg(.CLK(CLK), .rst(rst), .bit_tick(bit_tick), .os_tick(os_tick));

    localparam integer CLK_PERIOD_NS = 10;
    always #(CLK_PERIOD_NS/2) CLK = ~CLK;

    initial begin
        #10_000_000;
        $finish;
    end

endmodule