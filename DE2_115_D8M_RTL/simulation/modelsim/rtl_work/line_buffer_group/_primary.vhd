library verilog;
use verilog.vl_types.all;
entity line_buffer_group is
    generic(
        ADDR_WIDTH      : integer := 5;
        DATA_WIDTH      : integer := 16;
        DEPTH           : integer := 30
    );
    port(
        clk             : in     vl_logic;
        wr_addr_I       : in     vl_logic_vector;
        wr_addr_II      : in     vl_logic_vector;
        rd_addr_I       : in     vl_logic_vector;
        rd_addr_II      : in     vl_logic_vector;
        wr_en_I         : in     vl_logic;
        wr_en_II        : in     vl_logic;
        wr_data_I       : in     vl_logic_vector;
        wr_data_II      : in     vl_logic_vector;
        rd_data_I       : out    vl_logic_vector;
        rd_data_II      : out    vl_logic_vector
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of ADDR_WIDTH : constant is 1;
    attribute mti_svvh_generic_type of DATA_WIDTH : constant is 1;
    attribute mti_svvh_generic_type of DEPTH : constant is 1;
end line_buffer_group;
