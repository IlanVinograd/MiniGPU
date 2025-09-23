set proj_name    "GPU"
set part_name    "xc7a35tcpg236-1"          ;
set board_part   "digilentinc.com:basys3:part0:1.2"
set origin_dir   [file normalize "."]        ;
set work_dir     [file normalize "./.build"] ;

file mkdir $work_dir
create_project $proj_name $work_dir -part $part_name -force
if {![catch { set_property board_part $board_part [current_project] }]} { }


set hdl_dir  [file join $origin_dir "src" "verilog"]
add_files -fileset sources_1 [list \
  [file join $hdl_dir "scanout_rgb.v"] \
  [file join $hdl_dir "vga_basic.v"] \
  [file join $hdl_dir "vga_controller.v"] \
  [file join $hdl_dir "vram_dual_port.v"] \
]

set xci_file [file join $hdl_dir "clk_wiz_0.xci"]
if {[file exists $xci_file]} {
  import_files -fileset sources_1 $xci_file
  upgrade_ip [get_ips *]
  generate_target all [get_ips *]
}

set xdc_file [file join $origin_dir "src" "constr" "gpu_cst.xdc"]
add_files -fileset constrs_1 $xdc_file

set tb_file [file join $origin_dir "src" "sim" "vga_tb.v"]
if {[file exists $tb_file]} {
  if {[string equal [get_filesets -quiet sim_1] ""]} { create_fileset -simset sim_1 }
  add_files -fileset sim_1 $tb_file
  set_property top vga_tb [get_filesets sim_1]
}

set_property top vga_basic [get_filesets sources_1]

launch_runs synth_1 -jobs 8
wait_on_run synth_1
launch_runs impl_1 -to_step write_bitstream -jobs 8
wait_on_run impl_1

set bit [file join $work_dir "$proj_name.runs" "impl_1" "${proj_name}.bit"]
if {[file exists $bit]} {
  file mkdir [file join $origin_dir "out"]
  file copy -force $bit [file join $origin_dir "out" "${proj_name}.bit"]
  puts "DONE: [file join $origin_dir out ${proj_name}.bit]"
} else {
  puts "Build finished, bitstream not found yet (check runs)."
}