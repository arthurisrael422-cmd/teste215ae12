library verilog;
use verilog.vl_types.all;
entity dual_port_sync is
    generic(
        ADDR_WIDTH      : integer := 11;
        DATA_WIDTH      : integer := 8
    );
    port(
        clk_r           : in     vl_logic;
        clk_w           : in     vl_logic;
        we              : in     vl_logic;
        din             : in     vl_logic_vector;
        addr_a          : in     vl_logic_vector;
        addr_b          : in     vl_logic_vector;
        dout            : out    vl_logic_vector
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of ADDR_WIDTH : constant is 1;
    attribute mti_svvh_generic_type of DATA_WIDTH : constant is 1;
end dual_port_sync;
