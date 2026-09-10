library verilog;
use verilog.vl_types.all;
entity contour is
    generic(
        THRESHOLD       : integer := 100
    );
    port(
        iVGA_R          : in     vl_logic_vector(7 downto 0);
        iVGA_G          : in     vl_logic_vector(7 downto 0);
        iVGA_B          : in     vl_logic_vector(7 downto 0);
        bin_pixval      : out    vl_logic_vector(7 downto 0)
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of THRESHOLD : constant is 1;
end contour;
