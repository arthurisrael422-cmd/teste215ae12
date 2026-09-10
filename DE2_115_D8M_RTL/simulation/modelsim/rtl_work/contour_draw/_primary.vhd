library verilog;
use verilog.vl_types.all;
entity contour_draw is
    generic(
        X_MIN           : integer := 305;
        Y_MIN           : integer := 225;
        X_MAX           : integer := 334;
        Y_MAX           : integer := 254;
        H_BLANK_OFFSET  : integer := 160;
        V_BLANK_OFFSET  : integer := 45;
        THRESHOLD       : integer := 100
    );
    port(
        CONTOUR_MODE    : in     vl_logic;
        VGA_H_CNT       : in     vl_logic_vector(12 downto 0);
        VGA_V_CNT       : in     vl_logic_vector(12 downto 0);
        iVGA_R          : in     vl_logic_vector(7 downto 0);
        iVGA_G          : in     vl_logic_vector(7 downto 0);
        iVGA_B          : in     vl_logic_vector(7 downto 0);
        oVGA_R          : out    vl_logic_vector(7 downto 0);
        oVGA_G          : out    vl_logic_vector(7 downto 0);
        oVGA_B          : out    vl_logic_vector(7 downto 0);
        BOX_VALID       : out    vl_logic;
        BIN_PIXVAL      : out    vl_logic_vector(7 downto 0)
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of X_MIN : constant is 1;
    attribute mti_svvh_generic_type of Y_MIN : constant is 1;
    attribute mti_svvh_generic_type of X_MAX : constant is 1;
    attribute mti_svvh_generic_type of Y_MAX : constant is 1;
    attribute mti_svvh_generic_type of H_BLANK_OFFSET : constant is 1;
    attribute mti_svvh_generic_type of V_BLANK_OFFSET : constant is 1;
    attribute mti_svvh_generic_type of THRESHOLD : constant is 1;
end contour_draw;
