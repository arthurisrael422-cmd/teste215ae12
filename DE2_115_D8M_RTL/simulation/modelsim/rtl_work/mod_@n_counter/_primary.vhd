library verilog;
use verilog.vl_types.all;
entity mod_N_counter is
    generic(
        N               : integer := 900;
        N_BITS          : integer := 10
    );
    port(
        clk             : in     vl_logic;
        rst             : in     vl_logic;
        en              : in     vl_logic;
        count           : out    vl_logic_vector;
        done            : out    vl_logic
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of N : constant is 1;
    attribute mti_svvh_generic_type of N_BITS : constant is 1;
end mod_N_counter;
