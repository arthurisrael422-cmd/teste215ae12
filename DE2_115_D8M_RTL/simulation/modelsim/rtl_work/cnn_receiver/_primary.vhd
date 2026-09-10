library verilog;
use verilog.vl_types.all;
entity cnn_receiver is
    port(
        clk             : in     vl_logic;
        rst             : in     vl_logic;
        bi_addr_a       : out    vl_logic_vector(3 downto 0);
        bi_addr_b       : out    vl_logic_vector(3 downto 0);
        bi_q_a          : in     vl_logic_vector(127 downto 0);
        bi_q_b          : in     vl_logic_vector(127 downto 0);
        fmap_wr_addr_I  : out    vl_logic;
        fmap_wr_en_I    : out    vl_logic_vector(15 downto 0);
        fmap_wr_data_I  : out    vl_logic;
        fmap_wr_addr_II : out    vl_logic;
        fmap_wr_en_II   : out    vl_logic_vector(143 downto 0);
        fmap_wr_data_II : out    vl_logic;
        fmap_wr_addr_III: out    vl_logic_vector(63 downto 0);
        fmap_wr_en_III  : out    vl_logic_vector(63 downto 0);
        fmap_wr_data_III: out    vl_logic;
        digit_o         : out    vl_logic_vector(3 downto 0);
        digit_o_valid   : out    vl_logic;
        valid_o         : in     vl_logic;
        accum_o         : in     vl_logic;
        RCV_L2          : out    vl_logic
    );
end cnn_receiver;
