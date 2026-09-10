library verilog;
use verilog.vl_types.all;
entity VIDEO_PLL_altpll is
    port(
        areset          : in     vl_logic;
        clk             : out    vl_logic_vector(4 downto 0);
        inclk           : in     vl_logic_vector(1 downto 0);
        locked          : out    vl_logic
    );
end VIDEO_PLL_altpll;
