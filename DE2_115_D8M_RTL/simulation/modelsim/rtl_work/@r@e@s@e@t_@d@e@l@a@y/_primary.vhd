library verilog;
use verilog.vl_types.all;
entity RESET_DELAY is
    port(
        iCLK            : in     vl_logic;
        iRST            : in     vl_logic;
        oRST_0          : out    vl_logic;
        oRST_1          : out    vl_logic;
        oRST_2          : out    vl_logic;
        oREADY          : out    vl_logic
    );
end RESET_DELAY;
