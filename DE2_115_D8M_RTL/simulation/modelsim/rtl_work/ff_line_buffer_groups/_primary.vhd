library verilog;
use verilog.vl_types.all;
entity ff_line_buffer_groups is
    generic(
        LINE_BUF_GROUPS : integer := 16;
        LINE_BUFS_PER_GROUP: integer := 2;
        LINE_BUF_ADDR_BITS: integer := 5;
        D_WIDTH         : integer := 16;
        LINE_BUF_DEPTH  : integer := 30
    );
    port(
        clk             : in     vl_logic;
        line_buffer_rd_addr: in     vl_logic;
        line_buffer_wr_addr: in     vl_logic;
        line_buffer_wr_data: in     vl_logic;
        line_buffer_wr_en: in     vl_logic;
        line_buffer_rd_data: out    vl_logic
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of LINE_BUF_GROUPS : constant is 1;
    attribute mti_svvh_generic_type of LINE_BUFS_PER_GROUP : constant is 1;
    attribute mti_svvh_generic_type of LINE_BUF_ADDR_BITS : constant is 1;
    attribute mti_svvh_generic_type of D_WIDTH : constant is 1;
    attribute mti_svvh_generic_type of LINE_BUF_DEPTH : constant is 1;
end ff_line_buffer_groups;
