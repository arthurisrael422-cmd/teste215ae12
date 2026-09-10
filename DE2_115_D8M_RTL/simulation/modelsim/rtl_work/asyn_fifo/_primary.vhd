library verilog;
use verilog.vl_types.all;
entity asyn_fifo is
    generic(
        DATA_WIDTH      : integer := 8;
        FIFO_DEPTH_WIDTH: integer := 11
    );
    port(
        rst_n           : in     vl_logic;
        clk_write       : in     vl_logic;
        clk_read        : in     vl_logic;
        write           : in     vl_logic;
        read            : in     vl_logic;
        data_write      : in     vl_logic_vector;
        data_read       : out    vl_logic_vector;
        full            : out    vl_logic;
        empty           : out    vl_logic;
        data_count_w    : out    vl_logic_vector;
        data_count_r    : out    vl_logic_vector
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of DATA_WIDTH : constant is 1;
    attribute mti_svvh_generic_type of FIFO_DEPTH_WIDTH : constant is 1;
end asyn_fifo;
