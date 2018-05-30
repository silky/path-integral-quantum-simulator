
create_project -part xc7z020clg400-1 -force test_size build/test_size

# read all design files
set origin_dir "."

puts "got $::argc args"
if { $::argc > 0 } {
  for {set i 0} {$i < [llength $::argv]} {incr i} {
    set fname [string trim [lindex $::argv $i]]
    puts "$fname"
    read_verilog "$fname"
  }
} else {
  puts "need input filenames!"
}

puts "read files"
synth_design -top networkRTL -part xc7z020clg400-1
opt_design

create_clock -period 28.000 -name sysClk -waveform {0.000 5.000} [get_ports -filter { NAME =~  "*clk*" && DIRECTION == "IN" }]

# Synthesize Design

report_timing_summary -delay_type min_max -report_unconstrained -check_timing_verbose -max_paths 10 -input_pins -name timing_2 -file "$origin_dir/build/timing_report.txt"

report_utilization -file "$origin_dir/build/util_report.txt" -name utilization_1