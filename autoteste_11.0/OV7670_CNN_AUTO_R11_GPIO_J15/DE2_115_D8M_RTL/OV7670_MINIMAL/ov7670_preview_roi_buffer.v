// Captura YUYV da OV7670 em dois conjuntos de bancos sincronizados:
// 1) preview 320x240x4 para a VGA; 2) ROI central 90x90x8 para a CNN.
module ov7670_preview_roi_buffer(
 input wire reset_n,capture_enable,pclk,href,vsync,
 input wire [7:0] pixel_data,
 input wire read_clk,read_bank,frame_ack,
 input wire [16:0] preview_read_address,
 input wire [13:0] roi_read_address,
 output wire [7:0] preview_gray,
 output wire [7:0] roi_gray,
 output reg completed_bank,frame_request,frame_complete
);
 localparam [9:0] ROI_X_MIN=10'd275,ROI_X_MAX=10'd364;
 localparam [9:0] ROI_Y_MIN=10'd195,ROI_Y_MAX=10'd284;

 reg vsync_d,href_d,byte_phase;
 reg [9:0] pixel_x,line_y;
 reg [16:0] preview_line_base;
 reg [13:0] roi_write_count;
 reg bad_frame,capture_armed,write_bank;
 reg preview_wren,roi_wren;
 reg [16:0] preview_write_address;
 reg [13:0] roi_write_address;
 reg [3:0] preview_write_data;
 reg [7:0] roi_write_data;
 reg ack_meta,ack_sync;

 wire vsync_start=!vsync_d&&vsync;
 wire href_end=href_d&&!href;
 wire [10:0] completed_lines={1'b0,line_y}+(href_end?11'd1:11'd0);
 wire final_line_ok=!href_end||(line_y>=10'd480)||
                    (!byte_phase&&(pixel_x>=10'd640));
 wire request_pending=frame_request!=ack_sync;
 wire valid_finished_frame=capture_armed&&!bad_frame&&final_line_ok&&
                           (completed_lines>=11'd480)&&
                           (roi_write_count>=14'd8100);
 wire roi_position=(pixel_x>=ROI_X_MIN)&&(pixel_x<=ROI_X_MAX)&&
                   (line_y>=ROI_Y_MIN)&&(line_y<=ROI_Y_MAX);

 always @(posedge pclk or negedge reset_n) begin
  if(!reset_n) begin
   vsync_d<=0;href_d<=0;byte_phase<=0;pixel_x<=0;line_y<=0;
   preview_line_base<=0;roi_write_count<=0;bad_frame<=0;
   capture_armed<=0;write_bank<=0;preview_wren<=0;roi_wren<=0;
   preview_write_address<=0;roi_write_address<=0;
   preview_write_data<=0;roi_write_data<=0;
   ack_meta<=0;ack_sync<=0;completed_bank<=0;frame_request<=0;
   frame_complete<=0;
  end else begin
   ack_meta<=frame_ack;ack_sync<=ack_meta;
   vsync_d<=vsync;href_d<=href;preview_wren<=0;roi_wren<=0;
   if(!capture_enable) begin
    byte_phase<=0;pixel_x<=0;line_y<=0;preview_line_base<=0;
    roi_write_count<=0;bad_frame<=0;capture_armed<=0;write_bank<=0;
    completed_bank<=0;frame_request<=ack_sync;frame_complete<=0;
   end else if(vsync_start) begin
    if(valid_finished_frame&&!request_pending) begin
     completed_bank<=write_bank;frame_request<=~frame_request;
     frame_complete<=1'b1;capture_armed<=1'b0;
    end else if(!request_pending&&!capture_armed) begin
     write_bank<=~completed_bank;capture_armed<=1'b1;
    end else capture_armed<=1'b0;
    byte_phase<=0;pixel_x<=0;line_y<=0;preview_line_base<=0;
    roi_write_count<=0;bad_frame<=0;
   end else if(vsync||!capture_armed) begin
    byte_phase<=0;pixel_x<=0;
   end else if(href) begin
    if(!byte_phase) begin
     // TSLB=04 e COM13=C0: Y U Y V. Este e sempre um byte Y.
     if((line_y<10'd480)&&(pixel_x<10'd640)) begin
      // Decimacao 2:1 em X e Y para o preview 320x240.
      if(!line_y[0]&&!pixel_x[0]) begin
       preview_wren<=1'b1;
       preview_write_address<=preview_line_base+pixel_x[9:1];
       preview_write_data<=pixel_data[7:4];
      end
      // ROI da CNN preservada em 8 bits e em resolucao 90x90.
      if(roi_position) begin
       roi_wren<=1'b1;roi_write_address<=roi_write_count;
       roi_write_data<=pixel_data;roi_write_count<=roi_write_count+1'b1;
      end
      pixel_x<=pixel_x+1'b1;
     end
     byte_phase<=1'b1;
    end else byte_phase<=1'b0;
   end else begin
    byte_phase<=0;
    if(href_end) begin
     if((line_y<10'd480)&&(byte_phase||(pixel_x<10'd640)))bad_frame<=1;
     pixel_x<=0;
     if(line_y<10'd480) begin
      line_y<=line_y+1'b1;
      if(line_y[0]&&(line_y<10'd479))
       preview_line_base<=preview_line_base+17'd320;
     end
    end
   end
  end
 end

 wire [3:0] preview_q0,preview_q1;
 wire [7:0] roi_q0,roi_q1;
 assign preview_gray=read_bank?{preview_q1,preview_q1}:{preview_q0,preview_q0};
 assign roi_gray=read_bank?roi_q1:roi_q0;

 ov7670_dc_m9k_ram #(.DATA_WIDTH(4),.ADDR_WIDTH(17),.DEPTH(76800)) p0(
  .wr_clk(pclk),.wr_en(preview_wren&&!write_bank),
  .wr_addr(preview_write_address),.wr_data(preview_write_data),
  .rd_clk(read_clk),.rd_addr(preview_read_address),.rd_data(preview_q0));
 ov7670_dc_m9k_ram #(.DATA_WIDTH(4),.ADDR_WIDTH(17),.DEPTH(76800)) p1(
  .wr_clk(pclk),.wr_en(preview_wren&&write_bank),
  .wr_addr(preview_write_address),.wr_data(preview_write_data),
  .rd_clk(read_clk),.rd_addr(preview_read_address),.rd_data(preview_q1));
 ov7670_dc_m9k_ram #(.DATA_WIDTH(8),.ADDR_WIDTH(14),.DEPTH(8100)) r0(
  .wr_clk(pclk),.wr_en(roi_wren&&!write_bank),
  .wr_addr(roi_write_address),.wr_data(roi_write_data),
  .rd_clk(read_clk),.rd_addr(roi_read_address),.rd_data(roi_q0));
 ov7670_dc_m9k_ram #(.DATA_WIDTH(8),.ADDR_WIDTH(14),.DEPTH(8100)) r1(
  .wr_clk(pclk),.wr_en(roi_wren&&write_bank),
  .wr_addr(roi_write_address),.wr_data(roi_write_data),
  .rd_clk(read_clk),.rd_addr(roi_read_address),.rd_data(roi_q1));
endmodule

module ov7670_dc_m9k_ram #(
 parameter DATA_WIDTH=4,ADDR_WIDTH=17,DEPTH=76800
)(
 input wire wr_clk,wr_en,input wire [ADDR_WIDTH-1:0] wr_addr,
 input wire [DATA_WIDTH-1:0] wr_data,input wire rd_clk,
 input wire [ADDR_WIDTH-1:0] rd_addr,output wire [DATA_WIDTH-1:0] rd_data
);
 altsyncram ram(
  .address_a(wr_addr),.address_b(rd_addr),.clock0(wr_clk),.clock1(rd_clk),
  .data_a(wr_data),.wren_a(wr_en),.q_b(rd_data),.aclr0(1'b0),.aclr1(1'b0),
  .addressstall_a(1'b0),.addressstall_b(1'b0),
  .byteena_a(1'b1),.byteena_b(1'b1),
  .clocken0(1'b1),.clocken1(1'b1),.clocken2(1'b1),.clocken3(1'b1),
  .data_b({DATA_WIDTH{1'b0}}),.eccstatus(),.q_a(),
  .rden_a(1'b1),.rden_b(1'b1),.wren_b(1'b0));
 defparam
  ram.address_aclr_b="NONE",ram.address_reg_b="CLOCK1",
  ram.clock_enable_input_a="BYPASS",ram.clock_enable_input_b="BYPASS",
  ram.clock_enable_output_b="BYPASS",
  ram.intended_device_family="Cyclone IV E",ram.lpm_type="altsyncram",
  ram.numwords_a=DEPTH,ram.numwords_b=DEPTH,
  ram.operation_mode="DUAL_PORT",ram.outdata_aclr_b="NONE",
  ram.outdata_reg_b="UNREGISTERED",ram.power_up_uninitialized="TRUE",
  ram.ram_block_type="M9K",ram.read_during_write_mode_mixed_ports="DONT_CARE",
  ram.widthad_a=ADDR_WIDTH,ram.widthad_b=ADDR_WIDTH,
  ram.width_a=DATA_WIDTH,ram.width_b=DATA_WIDTH,ram.width_byteena_a=1;
endmodule
