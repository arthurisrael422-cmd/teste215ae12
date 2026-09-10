library verilog;
use verilog.vl_types.all;
entity mac_array is
    generic(
        DEC_BITS        : integer := 2;
        MANTISSA_BITS   : integer := 14;
        NUM_MACS        : integer := 16;
        MULTS_PER_MAC   : integer := 9
    );
    port(
        clk             : in     vl_logic;
        rst             : in     vl_logic;
        RCV_L2          : in     vl_logic;
        valid_i         : in     vl_logic;
        valid_o         : out    vl_logic;
        ifmap_chunk     : in     vl_logic;
        wt              : in     vl_logic;
        accum_o         : out    vl_logic
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of DEC_BITS : constant is 1;
    attribute mti_svvh_generic_type of MANTISSA_BITS : constant is 1;
    attribute mti_svvh_generic_type of NUM_MACS : constant is 1;
    attribute mti_svvh_generic_type of MULTS_PER_MAC : constant is 1;
end mac_array;
