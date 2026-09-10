library verilog;
use verilog.vl_types.all;
entity sdram_pll is
    port(
        areset          : in     vl_logic;
        inclk0          : in     vl_logic;
        c0              : out    vl_logic;
        c1              : out    vl_logic;
        locked          : out    vl_logic
    );
end sdram_pll;
