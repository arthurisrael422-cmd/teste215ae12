library verilog;
use verilog.vl_types.all;
entity sram is
    generic(
        ADDR_WIDTH      : integer := 8;
        DATA_WIDTH      : integer := 16;
        DEPTH           : integer := 256
    );
    port(
        clk             : in     vl_logic;
        wr_addr         : in     vl_logic_vector;
        rd_addr         : in     vl_logic_vector;
        write_en        : in     vl_logic;
        wr_data         : in     vl_logic_vector;
        rd_data         : out    vl_logic_vector
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of ADDR_WIDTH : constant is 1;
    attribute mti_svvh_generic_type of DATA_WIDTH : constant is 1;
    attribute mti_svvh_generic_type of DEPTH : constant is 1;
end sram;
