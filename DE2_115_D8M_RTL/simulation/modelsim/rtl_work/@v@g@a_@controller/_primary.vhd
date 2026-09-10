library verilog;
use verilog.vl_types.all;
entity VGA_Controller is
    generic(
        H_MARK          : integer := 17;
        H_MARK1         : integer := 10;
        V_MARK          : integer := 9;
        H_SYNC_CYC      : integer := 96;
        H_SYNC_BACK     : integer := 48;
        H_SYNC_ACT      : integer := 640;
        H_SYNC_FRONT    : integer := 16;
        H_SYNC_TOTAL    : integer := 800;
        V_SYNC_CYC      : integer := 2;
        V_SYNC_BACK     : integer := 33;
        V_SYNC_ACT      : integer := 480;
        V_SYNC_FRONT    : integer := 10;
        V_SYNC_TOTAL    : integer := 525;
        X_START         : vl_notype;
        Y_START         : vl_notype;
        H_BLANK         : vl_notype;
        V_BLANK         : vl_notype
    );
    port(
        iCLK            : in     vl_logic;
        iRST_N          : in     vl_logic;
        iRed            : in     vl_logic_vector(7 downto 0);
        iGreen          : in     vl_logic_vector(7 downto 0);
        iBlue           : in     vl_logic_vector(7 downto 0);
        oRequest        : out    vl_logic;
        oVGA_R          : out    vl_logic_vector(7 downto 0);
        oVGA_G          : out    vl_logic_vector(7 downto 0);
        oVGA_B          : out    vl_logic_vector(7 downto 0);
        oVGA_H_SYNC     : out    vl_logic;
        oVGA_V_SYNC     : out    vl_logic;
        oVGA_SYNC       : out    vl_logic;
        oVGA_BLANK      : out    vl_logic;
        H_Cont          : out    vl_logic_vector(12 downto 0);
        V_Cont          : out    vl_logic_vector(12 downto 0)
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of H_MARK : constant is 1;
    attribute mti_svvh_generic_type of H_MARK1 : constant is 1;
    attribute mti_svvh_generic_type of V_MARK : constant is 1;
    attribute mti_svvh_generic_type of H_SYNC_CYC : constant is 1;
    attribute mti_svvh_generic_type of H_SYNC_BACK : constant is 1;
    attribute mti_svvh_generic_type of H_SYNC_ACT : constant is 1;
    attribute mti_svvh_generic_type of H_SYNC_FRONT : constant is 1;
    attribute mti_svvh_generic_type of H_SYNC_TOTAL : constant is 1;
    attribute mti_svvh_generic_type of V_SYNC_CYC : constant is 1;
    attribute mti_svvh_generic_type of V_SYNC_BACK : constant is 1;
    attribute mti_svvh_generic_type of V_SYNC_ACT : constant is 1;
    attribute mti_svvh_generic_type of V_SYNC_FRONT : constant is 1;
    attribute mti_svvh_generic_type of V_SYNC_TOTAL : constant is 1;
    attribute mti_svvh_generic_type of X_START : constant is 3;
    attribute mti_svvh_generic_type of Y_START : constant is 3;
    attribute mti_svvh_generic_type of H_BLANK : constant is 3;
    attribute mti_svvh_generic_type of V_BLANK : constant is 3;
end VGA_Controller;
