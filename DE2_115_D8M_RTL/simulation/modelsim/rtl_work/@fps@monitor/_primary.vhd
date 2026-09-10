library verilog;
use verilog.vl_types.all;
entity FpsMonitor is
    generic(
        ONE_SEC         : integer := 50000000
    );
    port(
        clk50           : in     vl_logic;
        vs              : in     vl_logic;
        fps             : out    vl_logic_vector(7 downto 0);
        hex_fps_h       : out    vl_logic_vector(6 downto 0);
        hex_fps_l       : out    vl_logic_vector(6 downto 0)
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of ONE_SEC : constant is 1;
end FpsMonitor;
