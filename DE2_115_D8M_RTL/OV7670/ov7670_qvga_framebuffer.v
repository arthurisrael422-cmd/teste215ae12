// Captura RGB565 da OV7670 em 320x240 e armazena quadros em tons de cinza.
// Dois bancos M9K sao alternados: a camera escreve em um banco enquanto a
// VGA le exclusivamente o ultimo quadro completo armazenado no outro banco.
module ov7670_qvga_framebuffer (
	input  wire        reset_n,
	input  wire        capture_enable,
	input  wire        pclk,
	input  wire        href,
	input  wire        vsync,
	input  wire [7:0]  pixel_data,
	input  wire        read_clk,
	input  wire        read_frame_start,
	input  wire [16:0] read_address,
	output wire [7:0]  read_gray
);

	localparam [16:0] FRAME_PIXELS = 17'd76800;

	reg       enable_meta;
	reg       enable_pclk;
	reg       href_d;
	reg       vsync_d;
	reg       byte_phase;
	reg [7:0] first_byte;
	reg [8:0] pixel_x;
	reg [7:0] line_y;
	reg [16:0] line_base;
	reg        memory_write_en;
	reg [16:0] memory_write_address;
	reg [7:0]  memory_write_data;
	reg        write_bank;
	reg        completed_bank;
	reg        completed_frame_toggle;
	reg        capture_frame_active;

	(* ASYNC_REG = "TRUE" *) reg display_toggle_sync_0;
	(* ASYNC_REG = "TRUE" *) reg display_toggle_sync_1;
	(* ASYNC_REG = "TRUE" *) reg display_toggle_sync_2;

	(* ASYNC_REG = "TRUE" *) reg frame_toggle_sync_0;
	(* ASYNC_REG = "TRUE" *) reg frame_toggle_sync_1;
	(* ASYNC_REG = "TRUE" *) reg frame_toggle_sync_2;
	(* ASYNC_REG = "TRUE" *) reg completed_bank_sync_0;
	(* ASYNC_REG = "TRUE" *) reg completed_bank_sync_1;
	(* ASYNC_REG = "TRUE" *) reg completed_bank_sync_2;
	reg display_bank;
	reg displayed_frame_toggle;
	reg display_valid;

	wire [7:0] bank_0_read_data;
	wire [7:0] bank_1_read_data;
	wire bank_0_write_en = memory_write_en && !write_bank;
	wire bank_1_write_en = memory_write_en &&  write_bank;
	wire write_bank_available =
		(display_toggle_sync_2 == completed_frame_toggle);

	assign read_gray = !display_valid ? 8'h00 :
	                   (display_bank ? bank_1_read_data : bank_0_read_data);

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
			vsync_d             <= 1'b0;
			byte_phase          <= 1'b0;
			first_byte          <= 8'h00;
			pixel_x             <= 9'd0;
			line_y              <= 8'd0;
			line_base           <= 17'd0;
			memory_write_en      <= 1'b0;
			memory_write_address <= 17'd0;
			memory_write_data    <= 8'h00;
			write_bank           <= 1'b0;
			completed_bank       <= 1'b0;
			completed_frame_toggle <= 1'b0;
			capture_frame_active <= 1'b0;
			display_toggle_sync_0 <= 1'b0;
			display_toggle_sync_1 <= 1'b0;
			display_toggle_sync_2 <= 1'b0;
		end else begin
			enable_meta    <= capture_enable;
			enable_pclk    <= enable_meta;
			href_d         <= href;
			vsync_d        <= vsync;
			memory_write_en <= 1'b0;
			display_toggle_sync_0 <= displayed_frame_toggle;
			display_toggle_sync_1 <= display_toggle_sync_0;
			display_toggle_sync_2 <= display_toggle_sync_1;

			if (!enable_pclk) begin
				capture_frame_active <= 1'b0;
				byte_phase <= 1'b0;
				pixel_x    <= 9'd0;
				line_y     <= 8'd0;
				line_base  <= 17'd0;
			end else if (vsync) begin
				// Publica somente um quadro que chegou completo. O ultimo pulso
				// de escrita ainda usa o banco antigo nesta mesma borda de PCLK.
				if (!vsync_d && capture_frame_active &&
				    (line_y == 8'd240)) begin
					completed_bank         <= write_bank;
					completed_frame_toggle <= ~completed_frame_toggle;
					write_bank             <= ~write_bank;
				end

				capture_frame_active <= 1'b0;
				byte_phase <= 1'b0;
				pixel_x    <= 9'd0;
				line_y     <= 8'd0;
				line_base  <= 17'd0;
			end else if (vsync_d) begin
				// Inicio de um novo quadro. Somente captura se a VGA ja
				// confirmou que passou a exibir o ultimo banco concluido.
				capture_frame_active <= write_bank_available;
				byte_phase <= 1'b0;
				pixel_x    <= 9'd0;
				line_y     <= 8'd0;
				line_base  <= 17'd0;
			end else if (!capture_frame_active) begin
				// O banco ainda esta ocupado pela VGA: descarta este quadro
				// inteiro, sem modificar nenhuma das duas memorias.
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

	// Sincroniza a notificacao e o numero do banco concluido para VGA_CLK.
	// completed_bank permanece estavel durante todo o quadro seguinte.
	always @(posedge read_clk or negedge reset_n) begin
		if (!reset_n) begin
			frame_toggle_sync_0     <= 1'b0;
			frame_toggle_sync_1     <= 1'b0;
			frame_toggle_sync_2     <= 1'b0;
			completed_bank_sync_0   <= 1'b0;
			completed_bank_sync_1   <= 1'b0;
			completed_bank_sync_2   <= 1'b0;
			display_bank            <= 1'b0;
			displayed_frame_toggle  <= 1'b0;
			display_valid           <= 1'b0;
		end else begin
			frame_toggle_sync_0   <= completed_frame_toggle;
			frame_toggle_sync_1   <= frame_toggle_sync_0;
			frame_toggle_sync_2   <= frame_toggle_sync_1;
			completed_bank_sync_0 <= completed_bank;
			completed_bank_sync_1 <= completed_bank_sync_0;
			completed_bank_sync_2 <= completed_bank_sync_1;

			// A VGA nunca troca de banco no meio da area visivel.
			if (read_frame_start &&
			    (frame_toggle_sync_2 != displayed_frame_toggle)) begin
				display_bank           <= completed_bank_sync_2;
				displayed_frame_toggle <= frame_toggle_sync_2;
				display_valid          <= 1'b1;
			end
		end
	end

	// Banco 0: porta A escrita por PCLK; porta B lida por VGA_CLK.
	altsyncram frame_ram_0 (
		.address_a      (memory_write_address),
		.address_b      (read_address),
		.clock0         (pclk),
		.clock1         (read_clk),
		.data_a         (memory_write_data),
		.wren_a         (bank_0_write_en),
		.q_b            (bank_0_read_data),

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
		frame_ram_0.address_aclr_b = "NONE",
		frame_ram_0.address_reg_b = "CLOCK1",
		frame_ram_0.clock_enable_input_a = "BYPASS",
		frame_ram_0.clock_enable_input_b = "BYPASS",
		frame_ram_0.clock_enable_output_b = "BYPASS",
		frame_ram_0.intended_device_family = "Cyclone IV E",
		frame_ram_0.lpm_type = "altsyncram",
		frame_ram_0.numwords_a = 76800,
		frame_ram_0.numwords_b = 76800,
		frame_ram_0.operation_mode = "DUAL_PORT",
		frame_ram_0.outdata_aclr_b = "NONE",
		frame_ram_0.outdata_reg_b = "UNREGISTERED",
		frame_ram_0.power_up_uninitialized = "TRUE",
		frame_ram_0.ram_block_type = "M9K",
		frame_ram_0.read_during_write_mode_mixed_ports = "DONT_CARE",
		frame_ram_0.widthad_a = 17,
		frame_ram_0.widthad_b = 17,
		frame_ram_0.width_a = 8,
		frame_ram_0.width_b = 8,
		frame_ram_0.width_byteena_a = 1;

	// Banco 1: identico ao banco 0, mas com habilitacao de escrita separada.
	altsyncram frame_ram_1 (
		.address_a      (memory_write_address),
		.address_b      (read_address),
		.clock0         (pclk),
		.clock1         (read_clk),
		.data_a         (memory_write_data),
		.wren_a         (bank_1_write_en),
		.q_b            (bank_1_read_data),
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
		frame_ram_1.address_aclr_b = "NONE",
		frame_ram_1.address_reg_b = "CLOCK1",
		frame_ram_1.clock_enable_input_a = "BYPASS",
		frame_ram_1.clock_enable_input_b = "BYPASS",
		frame_ram_1.clock_enable_output_b = "BYPASS",
		frame_ram_1.intended_device_family = "Cyclone IV E",
		frame_ram_1.lpm_type = "altsyncram",
		frame_ram_1.numwords_a = 76800,
		frame_ram_1.numwords_b = 76800,
		frame_ram_1.operation_mode = "DUAL_PORT",
		frame_ram_1.outdata_aclr_b = "NONE",
		frame_ram_1.outdata_reg_b = "UNREGISTERED",
		frame_ram_1.power_up_uninitialized = "TRUE",
		frame_ram_1.ram_block_type = "M9K",
		frame_ram_1.read_during_write_mode_mixed_ports = "DONT_CARE",
		frame_ram_1.widthad_a = 17,
		frame_ram_1.widthad_b = 17,
		frame_ram_1.width_a = 8,
		frame_ram_1.width_b = 8,
		frame_ram_1.width_byteena_a = 1;

endmodule
