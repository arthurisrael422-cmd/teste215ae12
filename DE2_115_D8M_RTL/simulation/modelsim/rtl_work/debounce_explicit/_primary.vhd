library verilog;
use verilog.vl_types.all;
entity debounce_explicit is
    port(
        clk             : in     vl_logic;
        rst_n           : in     vl_logic;
        sw              : in     vl_logic;
        db_level        : out    vl_logic;
        db_tick         : out    vl_logic
    );
end debounce_explicit;
