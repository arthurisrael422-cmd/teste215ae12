module ov7670_vga_capture #(parameter H_PIXELS=640, V_LINES=480) (
 input wire reset_n, capture_enable, pclk, href, vsync,
 input wire [7:0] pixel_data,
 output reg [9:0] sdram_data,
 output reg sdram_write, frame_done, frame_valid,
 output reg [9:0] pixels_last_line, lines_last_frame
);
 reg enable_meta, enable_pclk, href_d, vsync_d, byte_phase;
 reg [7:0] first_byte;
 reg [9:0] pixel_x, line_y;
 reg bad_frame, capture_armed;
 wire href_end = href_d && !href;
 wire vsync_start = !vsync_d && vsync;
 wire [7:0] red_8={first_byte[7:3],first_byte[7:5]};
 wire [7:0] green_8={first_byte[2:0],pixel_data[7:5],first_byte[2:1]};
 wire [7:0] blue_8={pixel_data[4:0],pixel_data[4:2]};
 wire [17:0] gray_sum=red_8*10'd306+green_8*10'd601+blue_8*10'd117;
 wire [7:0] gray_8=gray_sum[17:10];
 always @(posedge pclk or negedge reset_n) begin
  if(!reset_n) begin
   enable_meta<=0; enable_pclk<=0; href_d<=0; vsync_d<=0; byte_phase<=0;
   first_byte<=0; pixel_x<=0; line_y<=0; bad_frame<=0; capture_armed<=0;
   sdram_data<=0; sdram_write<=0; frame_done<=0; frame_valid<=0;
   pixels_last_line<=0; lines_last_frame<=0;
  end else begin
   enable_meta<=capture_enable; enable_pclk<=enable_meta; href_d<=href; vsync_d<=vsync;
   sdram_write<=0; frame_done<=0;
   if(!enable_pclk) begin byte_phase<=0; pixel_x<=0; line_y<=0; bad_frame<=0; capture_armed<=0; end
   else if(vsync_start) begin
    frame_done<=capture_armed;
    frame_valid<=capture_armed && !bad_frame && (line_y==V_LINES);
    lines_last_frame<=line_y; byte_phase<=0; pixel_x<=0; line_y<=0; bad_frame<=0; capture_armed<=1;
   end else if(vsync) begin
    byte_phase<=0; pixel_x<=0; line_y<=0; bad_frame<=0; capture_armed<=1;
   end else if(!capture_armed) begin byte_phase<=0; pixel_x<=0; line_y<=0; end
   else if(href) begin
    if(!byte_phase) begin first_byte<=pixel_data; byte_phase<=1; end
    else begin
     byte_phase<=0;
     if((pixel_x<H_PIXELS)&&(line_y<V_LINES)) begin
      sdram_data<={gray_8,2'b00}; sdram_write<=1; pixel_x<=pixel_x+1'b1;
     end else bad_frame<=1;
    end
   end else begin
    byte_phase<=0;
    if(href_end) begin
     pixels_last_line<=pixel_x;
     if(byte_phase||(pixel_x!=H_PIXELS)) bad_frame<=1;
     pixel_x<=0;
     if(line_y<V_LINES) line_y<=line_y+1'b1; else bad_frame<=1;
    end
   end
  end
 end
endmodule
