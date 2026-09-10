library verilog;
use verilog.vl_types.all;
entity cam2cnn is
    generic(
        PIC_DIM_MULTIPLIER: integer := 3;
        PIC_DIM         : integer := 30
    );
    port(
        clk             : in     vl_logic;
        rst             : in     vl_logic;
        EOF             : in     vl_logic;
        raw_pixel       : in     vl_logic_vector(7 downto 0);
        raw_pixel_valid : in     vl_logic;
        digit           : out    vl_logic_vector(3 downto 0);
        digit_valid_output: out    vl_logic
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of PIC_DIM_MULTIPLIER : constant is 1;
    attribute mti_svvh_generic_type of PIC_DIM : constant is 1;
end cam2cnn;
