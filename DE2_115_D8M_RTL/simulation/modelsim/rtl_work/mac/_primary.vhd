library verilog;
use verilog.vl_types.all;
entity mac is
    generic(
        TOTAL_BITS      : integer := 16;
        MULTS           : integer := 9
    );
    port(
        clk             : in     vl_logic;
        rst             : in     vl_logic;
        ifmap_chunk     : in     vl_logic_vector(143 downto 0);
        weight          : in     vl_logic_vector(143 downto 0);
        mac_output      : out    vl_logic_vector(17 downto 0)
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of TOTAL_BITS : constant is 1;
    attribute mti_svvh_generic_type of MULTS : constant is 1;
end mac;
