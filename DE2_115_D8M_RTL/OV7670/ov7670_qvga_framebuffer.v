// Captura RGB565 da OV7670 em 320x240 e armazena um quadro em tons de cinza
// na memoria interna da FPGA. A escrita usa PCLK e a leitura usa VGA_CLK.
// A memoria e instanciada explicitamente como altsyncram de porta dupla,
// evitando que o Quartus tente implementar o quadro em registradores.
module ov7670_qvga_framebuffer (
	input  wire        reset_n,
	input  wire        capture_enable,
	input  wire        pclk,
	input  wire        href,
	input  wire        vsync,
	input  wire [7:0]  pixel_data,
	input  wire        read_clk,
	input  wire [16:0] read_address,
	output wire [7:0]  read_gray
);

	localparam [16:0] FRAME_PIXELS = 17'd76800;

	reg       enable_meta;
	reg       enable_pclk;
	reg       href_d;
	reg       byte_phase;
	reg [7:0] first_byte;
	reg [8:0] pixel_x;
	reg [7:0] line_y;
	reg [16:0] line_base;
	reg        memory_write_en;
	reg [16:0] memory_write_address;
	reg [7:0]  memory_write_data;

	wire [7:0] red_8 = {
		first_byte[7:3],
		first_byte[7:5]
	};

	wire [7:0] green_8 = {
		first_byte[2:0],
		pixel_data[7:5],
		first_byte[2:1]
	};

	wire [7:0] blue_8 = {
		pixel_data[4:0],
		pixel_data[4:2]
	};

	wire [17:0] gray_sum =
		red_8   * 10'd306 +
		green_8 * 10'd601 +
		blue_8  * 10'd117;

	wire [7:0] pixel_gray = gray_sum[17:10];
	wire [16:0] write_address = line_base + pixel_x;

	always @(posedge pclk or negedge reset_n) begin
		if (!reset_n) begin
			enable_meta         <= 1'b0;
			enable_pclk         <= 1'b0;
			href_d              <= 1'b0;
			byte_phase          <= 1'b0;
			first_byte          <= 8'h00;
			pixel_x             <= 9'd0;
			line_y              <= 8'd0;
			line_base           <= 17'd0;
			memory_write_en      <= 1'b0;
			memory_write_address <= 17'd0;
			memory_write_data    <= 8'h00;
		end else begin
			enable_meta    <= capture_enable;
			enable_pclk    <= enable_meta;
			href_d         <= href;
			memory_write_en <= 1'b0;

			if (!enable_pclk || vsync) begin
				byte_phase <= 1'b0;
				pixel_x    <= 9'd0;
				line_y     <= 8'd0;
				line_base  <= 17'd0;
			end else if (href) begin
				if (!byte_phase) begin
					first_byte <= pixel_data;
					byte_phase <= 1'b1;
				end else begin
					byte_phase <= 1'b0;

					if ((pixel_x < 9'd320) &&
					    (line_y < 8'd240) &&
					    (write_address < FRAME_PIXELS)) begin
						memory_write_en      <= 1'b1;
						memory_write_address <= write_address;
						memory_write_data    <= pixel_gray;
						pixel_x              <= pixel_x + 1'b1;
					end
				end
			end else begin
				byte_phase <= 1'b0;
				pixel_x    <= 9'd0;

				if (href_d && (line_y < 8'd240)) begin
					line_y <= line_y + 1'b1;

					if (line_y < 8'd239)
						line_base <= line_base + 17'd320;
				end
			end
		end
	end

	// Memoria de quadro explicitamente implementada nos blocos M9K.
	altsyncram frame_ram (
		.address_a      (memory_write_address),
		.address_b      (read_address),
		.clock0         (pclk),
		.clock1         (read_clk),
		.data_a         (memory_write_data),
		.wren_a         (memory_write_en),
		.q_b            (read_gray),

		.aclr0          (1'b0),
		.aclr1          (1'b0),
		.addressstall_a (1'b0),
		.addressstall_b (1'b0),
		.byteena_a      (1'b1),
		.byteena_b      (1'b1),
		.clocken0       (1'b1),
		.clocken1       (1'b1),
		.clocken2       (1'b1),
		.clocken3       (1'b1),
		.data_b         (8'h00),
		.eccstatus      (),
		.q_a            (),
		.rden_a         (1'b1),
		.rden_b         (1'b1),
		.wren_b         (1'b0)
	);

	defparam
		frame_ram.address_aclr_b = "NONE",
		frame_ram.address_reg_b = "CLOCK1",
		frame_ram.clock_enable_input_a = "BYPASS",
		frame_ram.clock_enable_input_b = "BYPASS",
		frame_ram.clock_enable_output_b = "BYPASS",
		frame_ram.intended_device_family = "Cyclone IV E",
		frame_ram.lpm_type = "altsyncram",
		frame_ram.numwords_a = 76800,
		frame_ram.numwords_b = 76800,
		frame_ram.operation_mode = "DUAL_PORT",
		frame_ram.outdata_aclr_b = "NONE",
		frame_ram.outdata_reg_b = "UNREGISTERED",
		frame_ram.power_up_uninitialized = "TRUE",
		frame_ram.ram_block_type = "M9K",
		frame_ram.read_during_write_mode_mixed_ports = "DONT_CARE",
		frame_ram.widthad_a = 17,
		frame_ram.widthad_b = 17,
		frame_ram.width_a = 8,
		frame_ram.width_b = 8,
		frame_ram.width_byteena_a = 1;

endmodule