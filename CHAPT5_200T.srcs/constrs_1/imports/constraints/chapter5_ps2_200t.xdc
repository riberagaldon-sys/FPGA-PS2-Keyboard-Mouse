###############################################################################
# GX-BIDT Chapter 5 PS/2 keyboard and mouse experiment
# Vivado 2025.2
# Device: XC7A200T-FBG484-2
# Top: top_chapter5_ps2
###############################################################################

# 50 MHz system clock
set_property -dict {PACKAGE_PIN W19 IOSTANDARD LVCMOS33} [get_ports sys_clk]
create_clock -period 20.000 -name sys_clk -waveform {0.000 10.000} [get_ports sys_clk]

# PS/2 mini-DIN interface
# Board schematic:
#   PS2_DATA -> F_B15_L2_P -> B15_L2_P -> package pin G15
#   PS2_CLK  -> F_B15_L2_N -> B15_L2_N -> package pin G16
# Both lines are open-drain and are released as high impedance for logic 1.
set_property PACKAGE_PIN G15 [get_ports PS2_DATA]
set_property IOSTANDARD LVCMOS33 [get_ports PS2_DATA]
set_property PULLTYPE PULLUP [get_ports PS2_DATA]
set_property PACKAGE_PIN G16 [get_ports PS2_CLK]
set_property IOSTANDARD LVCMOS33 [get_ports PS2_CLK]
set_property PULLTYPE PULLUP [get_ports PS2_CLK]

# Five active-high yellow LEDs
set_property -dict {PACKAGE_PIN J16 IOSTANDARD LVCMOS33} [get_ports {led[0]}]
set_property -dict {PACKAGE_PIN E22 IOSTANDARD LVCMOS33} [get_ports {led[1]}]
set_property -dict {PACKAGE_PIN F18 IOSTANDARD LVCMOS33} [get_ports {led[2]}]
set_property -dict {PACKAGE_PIN E19 IOSTANDARD LVCMOS33} [get_ports {led[3]}]
set_property -dict {PACKAGE_PIN D21 IOSTANDARD LVCMOS33} [get_ports {led[4]}]

# PS/2 inputs are asynchronous and are synchronized in RTL.
set_false_path -from [get_ports {PS2_CLK PS2_DATA}]

