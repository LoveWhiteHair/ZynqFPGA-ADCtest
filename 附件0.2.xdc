##tell Vivado do not view dr as a clock signal
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets dr_IBUF]
##get on board clk signal(125M for pynqz1)
set_property -dict {PACKAGE_PIN H16 IOSTANDARD LVCMOS33} [get_ports clk]
##Set Clock signal 125 MHz
create_clock -period 8.000 -name sys_clk_pin -waveform {0.000 4.000} -add [get_ports clk]

##Bind signal to devices on board
##Switches
set_property -dict {PACKAGE_PIN M20 IOSTANDARD LVCMOS33} [get_ports rstn]
set_property -dict {PACKAGE_PIN M19 IOSTANDARD LVCMOS33} [get_ports en]
##Digital IO pins
set_property -dict {PACKAGE_PIN T14 IOSTANDARD LVCMOS18} [get_ports {din[0]}]
set_property -dict {PACKAGE_PIN U12 IOSTANDARD LVCMOS18} [get_ports {din[1]}]
set_property -dict {PACKAGE_PIN U13 IOSTANDARD LVCMOS18} [get_ports {din[2]}]
set_property -dict {PACKAGE_PIN V13 IOSTANDARD LVCMOS18} [get_ports {din[3]}]
set_property -dict {PACKAGE_PIN V15 IOSTANDARD LVCMOS18} [get_ports {din[4]}]
set_property -dict {PACKAGE_PIN T15 IOSTANDARD LVCMOS18} [get_ports {din[5]}]
set_property -dict {PACKAGE_PIN R16 IOSTANDARD LVCMOS18} [get_ports {din[6]}]
set_property -dict {PACKAGE_PIN U17 IOSTANDARD LVCMOS18} [get_ports {din[7]}]
set_property -dict {PACKAGE_PIN V17 IOSTANDARD LVCMOS18} [get_ports {din[8]}]
set_property -dict {PACKAGE_PIN V18 IOSTANDARD LVCMOS18} [get_ports {din[9]}]
set_property -dict {PACKAGE_PIN T16 IOSTANDARD LVCMOS18} [get_ports {din[10]}]
set_property -dict {PACKAGE_PIN R17 IOSTANDARD LVCMOS18} [get_ports dr]
##Hold the output value(important)
set_property PULLTYPE KEEPER [get_ports {din[10]}]
set_property PULLTYPE KEEPER [get_ports {din[9]}]
set_property PULLTYPE KEEPER [get_ports {din[8]}]
set_property PULLTYPE KEEPER [get_ports {din[7]}]
set_property PULLTYPE KEEPER [get_ports {din[6]}]
set_property PULLTYPE KEEPER [get_ports {din[5]}]
set_property PULLTYPE KEEPER [get_ports {din[4]}]
set_property PULLTYPE KEEPER [get_ports {din[3]}]
set_property PULLTYPE KEEPER [get_ports {din[2]}]
set_property PULLTYPE KEEPER [get_ports {din[1]}]
set_property PULLTYPE KEEPER [get_ports {din[0]}]
set_property PULLTYPE KEEPER [get_ports dr]
##debug codes
set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets clk_IBUF_BUFG]

