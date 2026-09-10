library verilog;
use verilog.vl_types.all;
entity cnn_sender is
    generic(
        LINE_BUF_GROUPS : integer := 16;
        LINE_BUFS       : integer := 2;
        KERNEL_DIM      : integer := 3
    );
    port(
        clk             : in     vl_logic;
        rst             : in     vl_logic;
        pixel_i         : in     vl_logic_vector(7 downto 0);
        pixel_i_valid   : in     vl_logic;
        addr_a          : out    vl_logic;
        addr_b          : out    vl_logic;
        q_a             : in     vl_logic;
        q_b             : in     vl_logic;
        fc_addr_a       : out    vl_logic;
        fc_addr_b       : out    vl_logic;
        fc_q_a          : in     vl_logic;
        fc_q_b          : in     vl_logic;
        line_buffer_rd_data: in     vl_logic;
        line_buffer_rd_addr: out    vl_logic;
        line_buffer_wr_addr: out    vl_logic;
        line_buffer_wr_data: out    vl_logic;
        line_buffer_wr_en: out    vl_logic;
        fmap_rd_addr_I  : out    vl_logic;
        fmap_rd_data_I  : in     vl_logic;
        fmap_rd_addr_II : out    vl_logic;
        fmap_rd_data_II : in     vl_logic;
        fmap_rd_addr_III: out    vl_logic_vector(63 downto 0);
        fmap_rd_data_III: in     vl_logic;
        valid_i_final   : out    vl_logic;
        wt              : out    vl_logic;
        ifmap_chunk     : out    vl_logic
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of LINE_BUF_GROUPS : constant is 1;
    attribute mti_svvh_generic_type of LINE_BUFS : constant is 1;
    attribute mti_svvh_generic_type of KERNEL_DIM : constant is 1;
end cnn_sender;
