// OV7670 VGA YUV422 capture in the camera PCLK domain.
// TSLB=0x04 selects U Y0 V Y1, so every second byte is luminance (Y).
// Produces exactly one 10-bit grayscale word for every two input bytes.
// A frame is accepted only after a complete VSYNC boundary. No system clock
// is used to sample camera data.
module ov7670_native_capture #(
	parameter H_PIXELS = 640,
	parameter V_LINES  = 480
) (
	input  wire       reset_n,
	input  wire       enable,
	input  wire       pclk,
	input  wire       href,
	input  wire       vsync,
	input  wire [7:0] pixel_data,
	output reg  [9:0] pixel_word,
	output reg        pixel_write,
	output reg        frame_done,
	output reg        frame_valid,
	output reg  [9:0] pixels_last_line,
	output reg  [9:0] lines_last_frame
);

	reg enable_meta;
	reg enable_pclk;
	reg href_d;
	reg vsync_d;
	reg armed;
	reg in_frame;
	reg byte_phase;
	reg [9:0] pixel_count;
	reg [9:0] line_count;
	reg frame_error;

	wire vsync_rise =  vsync & ~vsync_d;
	wire vsync_fall = ~vsync &  vsync_d;
	wire href_fall  = ~href  &  href_d;

	always @(posedge pclk or negedge reset_n) begin
		if (!reset_n) begin
			enable_meta      <= 1'b0;
			enable_pclk      <= 1'b0;
			href_d           <= 1'b0;
			vsync_d          <= 1'b0;
			armed            <= 1'b0;
			in_frame         <= 1'b0;
			byte_phase       <= 1'b0;
			pixel_count      <= 10'd0;
			line_count       <= 10'd0;
			frame_error      <= 1'b0;
			pixel_word       <= 10'd0;
			pixel_write      <= 1'b0;
			frame_done       <= 1'b0;
			frame_valid      <= 1'b0;
			pixels_last_line <= 10'd0;
			lines_last_frame <= 10'd0;
		end else begin
			enable_meta <= enable;
			enable_pclk <= enable_meta;
			href_d      <= href;
			vsync_d     <= vsync;
			pixel_write <= 1'b0;
			frame_done  <= 1'b0;

			if (!enable_pclk) begin
				armed       <= 1'b0;
				in_frame    <= 1'b0;
				byte_phase  <= 1'b0;
				pixel_count <= 10'd0;
				line_count  <= 10'd0;
				frame_error <= 1'b0;
			end else begin
				// Do not start in the middle of a frame. The first falling edge
				// after configuration is the only point that arms capture.
				if (vsync_fall) begin
					armed       <= 1'b1;
					in_frame    <= 1'b1;
					byte_phase  <= 1'b0;
					pixel_count <= 10'd0;
					line_count  <= 10'd0;
					frame_error <= 1'b0;
				end

				if (vsync_rise && armed && in_frame) begin
					in_frame         <= 1'b0;
					byte_phase       <= 1'b0;
					frame_done       <= 1'b1;
					lines_last_frame <= line_count;
					frame_valid      <= !frame_error &&
					                    (line_count == V_LINES);
				end else if (in_frame && !vsync) begin
					if (href) begin
						if (!byte_phase) begin
							// First byte is U or V chrominance; the CNN does not use it.
							byte_phase <= 1'b1;
						end else begin
							// Second byte is Y luminance; store it without RGB conversion.
							byte_phase <= 1'b0;
							if ((pixel_count < H_PIXELS) &&
							    (line_count < V_LINES)) begin
								pixel_word  <= {pixel_data, 2'b00};
								pixel_write <= 1'b1;
								pixel_count <= pixel_count + 1'b1;
							end else begin
								frame_error <= 1'b1;
							end
						end
					end

					if (href_fall) begin
						pixels_last_line <= pixel_count;
						if (byte_phase || (pixel_count != H_PIXELS))
							frame_error <= 1'b1;
						byte_phase  <= 1'b0;
						pixel_count <= 10'd0;
						if (line_count < V_LINES)
							line_count <= line_count + 1'b1;
						else
							frame_error <= 1'b1;
					end
				end
			end
		end
	end
endmodule
