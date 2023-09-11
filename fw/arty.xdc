# Clock pin
set_property PACKAGE_PIN E3 [get_ports {clk}]
set_property IOSTANDARD LVCMOS33 [get_ports {clk}]

set_property PACKAGE_PIN D10  [get_ports {uart_txd}]
set_property PACKAGE_PIN A9  [get_ports {uart_rxd}]
set_property IOSTANDARD LVCMOS33 [get_ports {uart_txd}]
set_property IOSTANDARD LVCMOS33 [get_ports {uart_rxd}]
# set_property SLEW SLOW [get_ports {uart_txd}]
# set_property DRIVE 12 [get_ports {uart_txd}]


# Clock constraints
# create_clock -period 10.0 [get_ports {clk}]
create_clock -add -name sys_clk -period 10.0  [get_ports { clk }];

# create_generated_clock -name clk_28_unbuf -source [get_pin PLL/CLKIN] [get_pin PLL/CLKOUT0]
# create_generated_clock -name clk_2p8_unbuf -source [get_pin PLL/CLKIN] [get_pin PLL/CLKOUT1]

# create_generated_clock -name TDC_FIFO_CLK -source [get_pins PLL/CLKOUT0] -divide_by 10 [get_pins tdc_top/output_data/ser_div/out]

