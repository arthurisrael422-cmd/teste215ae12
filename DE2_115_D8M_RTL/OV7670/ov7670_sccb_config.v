// Minimal self-contained SCCB master and OV7670 VGA/YUV422 register table.
// Input clock: 50 MHz. SCCB bus: approximately 100 kHz.
module ov7670_sccb_config (
	input  wire clk,
	input  wire reset_n,
	output wire scl,
	inout  wire sda,
	output reg  config_done,
	output reg  config_error
);
	localparam integer TICK_DIV = 125;       // 50 MHz / 125 = 400 kHz
	localparam integer REG_COUNT = 78;
	localparam integer BOOT_TICKS = 8000;    // 20 ms
	localparam integer RESET_TICKS = 4000;   // 10 ms after COM7 reset

	localparam [3:0] ST_BOOT        = 4'd0,
	                 ST_START_1     = 4'd1,
	                 ST_START_2     = 4'd2,
	                 ST_BIT_LOW     = 4'd3,
	                 ST_BIT_HIGH    = 4'd4,
	                 ST_ACK_LOW     = 4'd5,
	                 ST_ACK_HIGH    = 4'd6,
	                 ST_STOP_LOW    = 4'd7,
	                 ST_STOP_HIGH   = 4'd8,
	                 ST_STOP_FREE   = 4'd9,
	                 ST_DELAY       = 4'd10,
	                 ST_DONE        = 4'd11;

	reg [7:0] div_count;
	reg [13:0] wait_count;
	reg [3:0] state;
	reg [6:0] reg_index;
	reg [1:0] byte_index;
	reg [2:0] bit_index;
	reg [7:0] shift_byte;
	reg scl_reg;
	reg sda_low;
	wire tick = (div_count == TICK_DIV-1);

	assign scl = scl_reg;
	assign sda = sda_low ? 1'b0 : 1'bz;

	function [15:0] register_word;
		input [6:0] index;
		begin
			case (index)
			 0: register_word=16'h12_80; // reset
			 1: register_word=16'h12_00; // COM7: VGA + YUV
			 2: register_word=16'h11_01; // CLKRC: stable VGA rate
			 3: register_word=16'h15_00; // normal VSYNC, free-running PCLK
			 4: register_word=16'h0C_00; // COM3: no scale/DCW
			 5: register_word=16'h3E_00; // COM14: normal PCLK
			 6: register_word=16'h04_00; // no CCIR656
			 7: register_word=16'h40_C0; // COM15: full output range, not RGB
			 8: register_word=16'h3A_04; // TSLB YLAST: U Y0 V Y1
			 9: register_word=16'h14_18;
			10: register_word=16'h4F_B3;
			11: register_word=16'h50_B3;
			12: register_word=16'h51_00;
			13: register_word=16'h52_3D;
			14: register_word=16'h53_A7;
			15: register_word=16'h54_E4;
			16: register_word=16'h58_9E;
			17: register_word=16'h3D_C0;
			18: register_word=16'h17_13; // VGA window
			19: register_word=16'h18_01;
			20: register_word=16'h32_B6;
			21: register_word=16'h19_02;
			22: register_word=16'h1A_7A;
			23: register_word=16'h03_0A;
			24: register_word=16'h0F_41;
			25: register_word=16'h1E_00; // no mirror/flip
			26: register_word=16'h33_0B;
			27: register_word=16'h3C_78;
			28: register_word=16'h69_00;
			29: register_word=16'h74_00;
			30: register_word=16'hB0_84;
			31: register_word=16'hB1_0C;
			32: register_word=16'hB2_0E;
			33: register_word=16'hB3_80;
			34: register_word=16'h70_3A;
			35: register_word=16'h71_35;
			36: register_word=16'h72_11;
			37: register_word=16'h73_F0;
			38: register_word=16'hA2_02;
			39: register_word=16'h7A_20;
			40: register_word=16'h7B_10;
			41: register_word=16'h7C_1E;
			42: register_word=16'h7D_35;
			43: register_word=16'h7E_5A;
			44: register_word=16'h7F_69;
			45: register_word=16'h80_76;
			46: register_word=16'h81_80;
			47: register_word=16'h82_88;
			48: register_word=16'h83_8F;
			49: register_word=16'h84_96;
			50: register_word=16'h85_A3;
			51: register_word=16'h86_AF;
			52: register_word=16'h87_C4;
			53: register_word=16'h88_D7;
			54: register_word=16'h89_E8;
			55: register_word=16'h13_E0;
			56: register_word=16'h00_00;
			57: register_word=16'h10_00;
			58: register_word=16'h0D_40;
			59: register_word=16'h14_18;
			60: register_word=16'hA5_05;
			61: register_word=16'hAB_07;
			62: register_word=16'h24_95;
			63: register_word=16'h25_33;
			64: register_word=16'h26_E3;
			65: register_word=16'h9F_78;
			66: register_word=16'hA0_68;
			67: register_word=16'hA1_03;
			68: register_word=16'hA6_D8;
			69: register_word=16'hA7_D8;
			70: register_word=16'hA8_F0;
			71: register_word=16'hA9_90;
			72: register_word=16'hAA_94;
			73: register_word=16'h13_E5;
			74: register_word=16'h1E_00;
			75: register_word=16'h69_06;
			76: register_word=16'h0C_00; // reaffirm no downscale
			77: register_word=16'h3E_00; // reaffirm normal PCLK
			default: register_word=16'h12_00;
			endcase
		end
	endfunction

	wire [15:0] selected_register = register_word(reg_index);

	always @(posedge clk or negedge reset_n) begin
		if (!reset_n) begin
			div_count    <= 8'd0;
			wait_count   <= 14'd0;
			state        <= ST_BOOT;
			reg_index    <= 7'd0;
			byte_index   <= 2'd0;
			bit_index    <= 3'd7;
			shift_byte   <= 8'h42;
			scl_reg      <= 1'b1;
			sda_low      <= 1'b0;
			config_done  <= 1'b0;
			config_error <= 1'b0;
		end else begin
			if (tick)
				div_count <= 8'd0;
			else
				div_count <= div_count + 1'b1;

			if (tick) begin
				case (state)
				ST_BOOT: begin
					scl_reg <= 1'b1;
					sda_low <= 1'b0;
					if (wait_count == BOOT_TICKS-1) begin
						wait_count <= 14'd0;
						state <= ST_START_1;
					end else wait_count <= wait_count + 1'b1;
				end
				ST_START_1: begin
					scl_reg <= 1'b1;
					sda_low <= 1'b0;
					state <= ST_START_2;
				end
				ST_START_2: begin
					sda_low <= 1'b1;
					byte_index <= 2'd0;
					bit_index <= 3'd7;
					shift_byte <= 8'h42;
					state <= ST_BIT_LOW;
				end
				ST_BIT_LOW: begin
					scl_reg <= 1'b0;
					sda_low <= ~shift_byte[bit_index];
					state <= ST_BIT_HIGH;
				end
				ST_BIT_HIGH: begin
					scl_reg <= 1'b1;
					if (bit_index == 0)
						state <= ST_ACK_LOW;
					else begin
						bit_index <= bit_index - 1'b1;
						state <= ST_BIT_LOW;
					end
				end
				ST_ACK_LOW: begin
					scl_reg <= 1'b0;
					sda_low <= 1'b0;
					state <= ST_ACK_HIGH;
				end
				ST_ACK_HIGH: begin
					scl_reg <= 1'b1;
					if (sda !== 1'b0)
						config_error <= 1'b1;
					if (byte_index == 2) begin
						state <= ST_STOP_LOW;
					end else begin
						byte_index <= byte_index + 1'b1;
						bit_index <= 3'd7;
						if (byte_index == 0)
							shift_byte <= selected_register[15:8];
						else
							shift_byte <= selected_register[7:0];
						state <= ST_BIT_LOW;
					end
				end
				ST_STOP_LOW: begin
					scl_reg <= 1'b0;
					sda_low <= 1'b1;
					state <= ST_STOP_HIGH;
				end
				ST_STOP_HIGH: begin
					scl_reg <= 1'b1;
					state <= ST_STOP_FREE;
				end
				ST_STOP_FREE: begin
					sda_low <= 1'b0;
					wait_count <= 14'd0;
					state <= ST_DELAY;
				end
				ST_DELAY: begin
					// COM7 reset needs 10 ms; other registers get 50 us.
					if (((reg_index == 0) && (wait_count == RESET_TICKS-1)) ||
					    ((reg_index != 0) && (wait_count == 14'd19))) begin
						wait_count <= 14'd0;
						if (reg_index == REG_COUNT-1) begin
							config_done <= 1'b1;
							state <= ST_DONE;
						end else begin
							reg_index <= reg_index + 1'b1;
							state <= ST_START_1;
						end
					end else wait_count <= wait_count + 1'b1;
				end
				default: begin
					state <= ST_DONE;
					config_done <= 1'b1;
					scl_reg <= 1'b1;
					sda_low <= 1'b0;
				end
				endcase
			end
		end
	end
endmodule
