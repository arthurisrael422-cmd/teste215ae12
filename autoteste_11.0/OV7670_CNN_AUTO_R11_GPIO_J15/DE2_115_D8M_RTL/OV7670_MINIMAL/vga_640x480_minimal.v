// VGA 640x480. Normal: preview 320x240 ampliado 2x com ROI verde.
// SW1: mostra o ROI 90x90 ampliado 4x para validar a entrada da CNN.
module vga_640x480_minimal(
 input reset_n,pixel_clk,input [7:0] preview_gray,roi_gray,
 input roi_zoom,cnn_debug_mode,input [7:0] cnn_debug_pixel,
 input cnn_debug_ready,
 input camera_frame_complete,completed_bank,frame_request,
 input hold_read_bank,
 output reg frame_ack,read_bank,
 output reg [16:0] preview_read_address,
 output reg [13:0] roi_read_address,
 output reg [9:0] cnn_debug_read_address,
 output reg frame_seen,vga_hs,vga_vs,vga_blank_n,
 output vga_sync_n,output reg [7:0] vga_r,vga_g,vga_b
);
 reg [9:0] h_count,v_count;
 reg active_d,border_d,zoom_valid_d,debug_valid_d;
 reg request_meta,request_sync,bank_meta,bank_sync;
 wire active_now=(h_count<10'd640)&&(v_count<10'd480);
 wire frame_end=(h_count==10'd799)&&(v_count==10'd524);
 wire [8:0] preview_x=h_count[9:1];
 wire [8:0] preview_y=v_count[9:1];
 wire [16:0] preview_row={preview_y,8'b0}+{preview_y,6'b0};
 wire box_x=(h_count>=10'd275)&&(h_count<=10'd364);
 wire box_y=(v_count>=10'd195)&&(v_count<=10'd284);
 wire border_now=(box_x&&((v_count==10'd195)||(v_count==10'd284)))||
                 (box_y&&((h_count==10'd275)||(h_count==10'd364)));
 wire zoom_valid_now=(h_count>=10'd140)&&(h_count<10'd500)&&
                     (v_count>=10'd60)&&(v_count<10'd420);
 wire [6:0] zoom_x=(h_count-10'd140)>>2;
 wire [6:0] zoom_y=(v_count-10'd60)>>2;
 wire [13:0] zoom_row={zoom_y,6'b0}+{zoom_y,4'b0}+
                      {zoom_y,3'b0}+{zoom_y,1'b0};
 // A matriz 30x30 e ampliada 16 vezes: 480x480, centralizada na tela.
 wire debug_valid_now=(h_count>=10'd80)&&(h_count<10'd560)&&
                      (v_count<10'd480);
 wire [4:0] debug_x=(h_count-10'd80)>>4;
 wire [4:0] debug_y=v_count>>4;
 wire [9:0] debug_row={debug_y,5'b0}-{debug_y,1'b0};
 assign vga_sync_n=1'b0;

 always @(posedge pixel_clk or negedge reset_n) begin
  if(!reset_n) begin
   h_count<=0;v_count<=0;preview_read_address<=0;roi_read_address<=0;
   cnn_debug_read_address<=0;
   active_d<=0;border_d<=0;zoom_valid_d<=0;debug_valid_d<=0;
   vga_hs<=1;vga_vs<=1;vga_blank_n<=0;vga_r<=0;vga_g<=0;vga_b<=0;
   request_meta<=0;request_sync<=0;bank_meta<=0;bank_sync<=0;
   frame_ack<=0;read_bank<=0;frame_seen<=0;
  end else begin
   request_meta<=frame_request;request_sync<=request_meta;
   bank_meta<=completed_bank;bank_sync<=bank_meta;
   // Durante a leitura da CNN o banco fica congelado para impedir que os
   // 8100 pixels sejam formados por partes de dois quadros diferentes.
   if(frame_end&&!hold_read_bank&&(request_sync!=frame_ack)) begin
    read_bank<=bank_sync;frame_ack<=request_sync;
    frame_seen<=camera_frame_complete;
   end
   if(h_count==10'd799) begin
    h_count<=0;
    if(v_count==10'd524)v_count<=0;else v_count<=v_count+1'b1;
   end else h_count<=h_count+1'b1;

   if(active_now)preview_read_address<=preview_row+preview_x;
   else preview_read_address<=0;
   if(zoom_valid_now)roi_read_address<=zoom_row+zoom_x;
   else roi_read_address<=0;
   if(debug_valid_now)
    cnn_debug_read_address<=debug_row+debug_x;
   else cnn_debug_read_address<=0;
   active_d<=active_now;border_d<=border_now;zoom_valid_d<=zoom_valid_now;
   debug_valid_d<=debug_valid_now;
   vga_hs<=~((h_count>=10'd656)&&(h_count<10'd752));
   vga_vs<=~((v_count>=10'd490)&&(v_count<10'd492));
   vga_blank_n<=active_d;

   if(cnn_debug_mode) begin
    if(active_d&&debug_valid_d&&cnn_debug_ready) begin
     vga_r<=cnn_debug_pixel;vga_g<=cnn_debug_pixel;vga_b<=cnn_debug_pixel;
    end else begin
     vga_r<=0;vga_g<=0;vga_b<=0;
    end
   end else if(!(active_d&&frame_seen)) begin
    vga_r<=0;vga_g<=0;vga_b<=0;
   end else if(roi_zoom) begin
    if(zoom_valid_d) begin
     vga_r<=roi_gray;vga_g<=roi_gray;vga_b<=roi_gray;
    end else begin
     vga_r<=0;vga_g<=0;vga_b<=0;
    end
   end else if(border_d) begin
    vga_r<=8'h00;vga_g<=8'hff;vga_b<=8'h00;
   end else begin
    vga_r<=preview_gray;vga_g<=preview_gray;vga_b<=preview_gray;
   end
  end
 end
endmodule
