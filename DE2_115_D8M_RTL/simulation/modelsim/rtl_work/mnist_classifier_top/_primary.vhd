library verilog;
use verilog.vl_types.all;
entity mnist_classifier_top is
    generic(
        H_BLANK_OFFSET  : integer := 160;
        V_BLANK_OFFSET  : integer := 45;
        W               : integer := 640;
        H               : integer := 480;
        PIC_DIM         : integer := 30;
        PIC_DIM_MULTIPLIER: integer := 3;
        THRESHOLD       : integer := 100
    );
    port(
        VGA_CLK         : in     vl_logic;
        RESET_N         : in     vl_logic;
        VGA_HS          : in     vl_logic;
        VGA_VS          : in     vl_logic;
        CONTOUR_MODE    : in     vl_logic;
        VGA_H_CNT       : in     vl_logic_vector(12 downto 0);
        VGA_V_CNT       : in     vl_logic_vector(12 downto 0);
        iVGA_R          : in     vl_logic_vector(7 downto 0);
        iVGA_G          : in     vl_logic_vector(7 downto 0);
        iVGA_B          : in     vl_logic_vector(7 downto 0);
        oVGA_R          : out    vl_logic_vector(7 downto 0);
        oVGA_G          : out    vl_logic_vector(7 downto 0);
        oVGA_B          : out    vl_logic_vector(7 downto 0);
        DIGIT_OUT       : out    vl_logic_vector(3 downto 0);
        HEX7            : out    vl_logic_vector(6 downto 0);
        DIGIT_VALID_OUTPUT: out    vl_logic;
        BOX_VALID       : out    vl_logic
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of H_BLANK_OFFSET : constant is 1;
    attribute mti_svvh_generic_type of V_BLANK_OFFSET : constant is 1;
    attribute mti_svvh_generic_type of W : constant is 1;
    attribute mti_svvh_generic_type of H : constant is 1;
    attribute mti_svvh_generic_type of PIC_DIM : constant is 1;
    attribute mti_svvh_generic_type of PIC_DIM_MULTIPLIER : constant is 1;
    attribute mti_svvh_generic_type of THRESHOLD : constant is 1;
end mnist_classifier_top;
