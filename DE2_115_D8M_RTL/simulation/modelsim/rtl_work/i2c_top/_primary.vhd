library verilog;
use verilog.vl_types.all;
entity i2c_top is
    generic(
        freq            : integer := 100000
    );
    port(
        clk             : in     vl_logic;
        rst_n           : in     vl_logic;
        start           : in     vl_logic;
        stop            : in     vl_logic;
        wr_data         : in     vl_logic_vector(7 downto 0);
        rd_tick         : out    vl_logic;
        ack             : out    vl_logic_vector(1 downto 0);
        rd_data         : out    vl_logic_vector(7 downto 0);
        scl             : inout  vl_logic;
        sda             : inout  vl_logic;
        state           : out    vl_logic_vector(3 downto 0)
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of freq : constant is 1;
end i2c_top;
