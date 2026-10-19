# Clocks de entrada da DE2-115 (50 MHz = 20 ns)
create_clock -name CLOCK_50  -period 20.000 [get_ports {CLOCK_50}]
create_clock -name CLOCK2_50 -period 20.000 [get_ports {CLOCK2_50}]
create_clock -name CLOCK3_50 -period 20.000 [get_ports {CLOCK3_50}]

# PCLK recebido da OV7670. Com XCLK=24 MHz e CLKRC=01, o periodo esperado
# fica proximo de 83,33 ns. O valor de 40 ns mantem uma restricao conservadora.
create_clock -name MIPI_PIXEL_CLK -period 40.000 [get_ports {MIPI_PIXEL_CLK}]

# Descobre VGA_CLK e MIPI_REFCLK a partir dos ALTPLL do projeto.
derive_pll_clocks
derive_clock_uncertainty
