library verilog;
use verilog.vl_types.all;
entity fmap_II is
    generic(
        ADDR_WIDTH      : integer := 3;
        DATA_WIDTH      : integer := 16;
        DEPTH           : integer := 8
    );
    port(
        clk             : in     vl_logic;
        fmap_wr_addr    : in     vl_logic;
        fmap_rd_addr    : in     vl_logic;
        fmap_wr_en      : in     vl_logic_vector(143 downto 0);
        fmap_wr_data    : in     vl_logic;
        fmap_rd_data    : out    vl_logic
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of ADDR_WIDTH : constant is 1;
    attribute mti_svvh_generic_type of DATA_WIDTH : constant is 1;
    attribute mti_svvh_generic_type of DEPTH : constant is 1;
end fmap_II;
