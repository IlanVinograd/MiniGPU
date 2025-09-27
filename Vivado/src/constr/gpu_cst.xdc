set_property PACKAGE_PIN W5 [get_ports CLK]
set_property IOSTANDARD LVCMOS33 [get_ports CLK]
create_clock -name sys_clk_pin -period 10.000 -waveform {0 5} [get_ports CLK]

set_property PACKAGE_PIN N19 [get_ports {RED[3]}]
set_property PACKAGE_PIN J19 [get_ports {RED[2]}]
set_property PACKAGE_PIN H19 [get_ports {RED[1]}]
set_property PACKAGE_PIN G19 [get_ports {RED[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {RED[*]}]

set_property PACKAGE_PIN D17 [get_ports {GREEN[3]}]
set_property PACKAGE_PIN G17 [get_ports {GREEN[2]}]
set_property PACKAGE_PIN H17 [get_ports {GREEN[1]}]
set_property PACKAGE_PIN J17 [get_ports {GREEN[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {GREEN[*]}]

set_property PACKAGE_PIN J18 [get_ports {BLUE[3]}]
set_property PACKAGE_PIN K18 [get_ports {BLUE[2]}]
set_property PACKAGE_PIN L18 [get_ports {BLUE[1]}]
set_property PACKAGE_PIN N18 [get_ports {BLUE[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {BLUE[*]}]

set_property PACKAGE_PIN P19 [get_ports HS]
set_property PACKAGE_PIN R19 [get_ports VS]
set_property IOSTANDARD LVCMOS33 [get_ports {HS VS}]

set_property PACKAGE_PIN B18 [get_ports RX]
set_property IOSTANDARD LVCMOS33 [get_ports RX]
set_property PULLUP true [get_ports RX]

set_property PACKAGE_PIN A18 [get_ports TX]
set_property IOSTANDARD LVCMOS33 [get_ports TX]

set_property PACKAGE_PIN U18 [get_ports rst]
set_property IOSTANDARD LVCMOS33 [get_ports rst]

create_generated_clock -name pix_clk -source [get_ports CLK] -divide_by 4 [get_pins -hier *clk_wiz_0*/clk_out1]

set_clock_groups -asynchronous -group [get_clocks sys_clk_pin] -group [get_clocks pix_clk]

set_false_path -from [get_ports RX] -to [get_pins -hier *rx_meta*/D]
set_false_path -from [get_ports RX] -to [get_pins -hier *rx_sync*/D]