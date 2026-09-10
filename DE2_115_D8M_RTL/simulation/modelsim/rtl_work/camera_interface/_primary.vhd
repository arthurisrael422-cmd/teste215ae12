library verilog;
use verilog.vl_types.all;
entity camera_interface is
    port(
        clk             : in     vl_logic;
        clk_100         : in     vl_logic;
        rst_n           : in     vl_logic;
        key             : in     vl_logic_vector(3 downto 0);
        rd_en           : in     vl_logic;
        data_count_r    : out    vl_logic_vector(9 downto 0);
        dout            : out    vl_logic_vector(15 downto 0);
        cmos_pclk       : in     vl_logic;
        cmos_href       : in     vl_logic;
        cmos_vsync      : in     vl_logic;
        cmos_db         : in     vl_logic_vector(7 downto 0);
        cmos_sda        : inout  vl_logic;
        cmos_scl        : inout  vl_logic;
        cmos_rst_n      : out    vl_logic;
        cmos_pwdn       : out    vl_logic;
        cmos_xclk       : out    vl_logic;
        led             : out    vl_logic_vector(3 downto 0)
    );
end camera_interface;
