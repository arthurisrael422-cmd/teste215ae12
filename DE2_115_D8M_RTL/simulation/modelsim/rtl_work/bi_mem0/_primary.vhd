library verilog;
use verilog.vl_types.all;
entity bi_mem0 is
    generic(
        ADDR_WIDTH      : integer := 4;
        DATA_WIDTH      : integer := 128;
        DEPTH           : integer := 16
    );
    port(
        clk             : in     vl_logic;
        addr_a          : in     vl_logic_vector;
        addr_b          : in     vl_logic_vector;
        q_a             : out    vl_logic_vector;
        q_b             : out    vl_logic_vector
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of ADDR_WIDTH : constant is 1;
    attribute mti_svvh_generic_type of DATA_WIDTH : constant is 1;
    attribute mti_svvh_generic_type of DEPTH : constant is 1;
end bi_mem0;
