module baud_gen #(
    parameter integer FCLK_HZ = 100_000_000,
    parameter integer BAUD    = 3_125_000,
    parameter integer OS      = 16
)(
    input  wire CLK,
    input  wire rst,
    output reg  bit_tick,  // 1×baud,
    output reg  os_tick    // 16×baud,
);

    localparam integer DIV_OS = FCLK_HZ / (BAUD*OS);
    localparam integer COW    = (DIV_OS > 1) ? $clog2(DIV_OS) : 1;
    localparam integer OSW    = (OS     > 1) ? $clog2(OS)     : 1;

    reg [COW-1:0] cnt_os = {COW{1'b0}};
    reg [OSW-1:0] os_mod = {OSW{1'b0}};

    always @(posedge CLK) begin
        if (rst) begin
            bit_tick <= 1'b0;
            os_tick  <= 1'b0;
            cnt_os   <= {COW{1'b0}};
            os_mod   <= {OSW{1'b0}};
        end else begin
            bit_tick <= 1'b0;
            os_tick  <= 1'b0;

            if (cnt_os == DIV_OS-1) begin
                os_tick <= 1'b1;
                cnt_os  <= {COW{1'b0}};

                if (os_mod == OS-1) begin
                    os_mod   <= {OSW{1'b0}};
                    bit_tick <= 1'b1;
                end else begin
                    os_mod <= os_mod + 1'b1;
                end
            end else begin
                cnt_os <= cnt_os + 1'b1;
            end
        end
    end

endmodule