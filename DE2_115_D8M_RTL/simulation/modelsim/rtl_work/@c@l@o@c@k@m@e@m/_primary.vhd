library verilog;
use verilog.vl_types.all;
entity CLOCKMEM is
    port(
        CLK             : in     vl_logic;
        CLK_FREQ        : in     vl_logic_vector(31 downto 0);
        CK_1HZ          : out    vl_logic
    );
end CLOCKMEM;
