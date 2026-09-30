# Board oscillators. Quartus/TimeQuest periods are expressed in nanoseconds.
create_clock -name CLOCK_50  -period 20.000 [get_ports {CLOCK_50}]
create_clock -name CLOCK2_50 -period 20.000 [get_ports {CLOCK2_50}]
create_clock -name CLOCK3_50 -period 20.000 [get_ports {CLOCK3_50}]

# Source-synchronous pixel clock returned by the OV7670. With XCLK=24 MHz
# and the official VGA/30-fps CLKRC setting, constrain for 24 MHz PCLK.
create_clock -name OV7670_PCLK -period 41.667 [get_ports {MIPI_PIXEL_CLK}]

# The sensor changes D/HREF/VSYNC after PCLK's falling edge (0..5 ns) and
# guarantees 15 ns setup before the next relevant edge. The RTL captures on
# the following rising edge, near the centre of the valid-data window.
set_input_delay -clock OV7670_PCLK -clock_fall -min 0.000 \
    [get_ports {MIPI_PIXEL_D[*] MIPI_PIXEL_HS MIPI_PIXEL_VS}]
set_input_delay -clock OV7670_PCLK -clock_fall -max 5.000 \
    [get_ports {MIPI_PIXEL_D[*] MIPI_PIXEL_HS MIPI_PIXEL_VS}]

# Create clocks produced by VIDEO_PLL, pll_test and sdram_pll and add the
# device-specific clock uncertainty calculated by TimeQuest.
derive_pll_clocks
derive_clock_uncertainty

# The board clock inputs are separate oscillators. OV7670_PCLK is regenerated
# inside the sensor. Crossings use dual-clock FIFOs or two-register synchronizers.
# Quartus Prime 18.1 get_clocks accepts only a name filter; the newer
# -include_generated_clocks switch must not be used here.
set_clock_groups -asynchronous \
    -group [get_clocks {CLOCK_50}] \
    -group [get_clocks {CLOCK2_50}] \
    -group [get_clocks {CLOCK3_50}] \
    -group [get_clocks {OV7670_PCLK}]
