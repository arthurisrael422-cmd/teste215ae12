library verilog;
use verilog.vl_types.all;
entity RGB2GRAY is
    port(
        i_RED           : in     vl_logic_vector(7 downto 0);
        i_BLUE          : in     vl_logic_vector(7 downto 0);
        i_GREEN         : in     vl_logic_vector(7 downto 0);
        o_GRAYSCALE     : out    vl_logic_vector(7 downto 0)
    );
end RGB2GRAY;
