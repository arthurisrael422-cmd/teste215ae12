// OV7670 + preview VGA + ROI 90x90 + classificador MNIST.
// KEY[0]: reset; KEY[1]: classificar; KEY[2]/KEY[3]: navegar historico.
// SW[1]: ampliar ROI; SW[7:4]: rotulo real informado pelo usuario.
// SW[2]=1: mostra um dos 100 registros 30x30 armazenados.
module DE2_115_D8M_RTL (
 input CLOCK2_50,CLOCK3_50,CLOCK_50,
 output [8:0] LEDG,output [17:0] LEDR,
 input [3:0] KEY,input [17:0] SW,
 output [6:0] HEX0,HEX1,HEX2,HEX3,HEX4,HEX5,HEX6,HEX7,
 output VGA_BLANK_N,output [7:0] VGA_B,output VGA_CLK,
 output [7:0] VGA_G,output VGA_HS,output [7:0] VGA_R,
 output VGA_SYNC_N,output VGA_VS,
 output [12:0] DRAM_ADDR,output [1:0] DRAM_BA,
 output DRAM_CAS_N,DRAM_CKE,DRAM_CLK,DRAM_CS_N,
 inout [31:0] DRAM_DQ,output [3:0] DRAM_DQM,
 output DRAM_RAS_N,DRAM_WE_N,
 inout CAMERA_I2C_SCL,CAMERA_I2C_SDA,
 output CAMERA_PWDN_n,output MIPI_CS_n,
 inout MIPI_I2C_SCL,MIPI_I2C_SDA,output MIPI_MCLK,
 input MIPI_PIXEL_CLK,input [9:0] MIPI_PIXEL_D,
 input MIPI_PIXEL_HS,MIPI_PIXEL_VS,
 output MIPI_REFCLK,MIPI_RESET_n,inout [6:0] EX_IO
);
 wire reset_n=KEY[0];
 wire camera_config_done;
 wire [15:0] unused_dout,unused_pixel;
 wire [9:0] unused_count;
 wire unused_pixel_valid;
 wire [3:0] unused_camera_led;
 wire [7:0] camera_bus=MIPI_PIXEL_D[7:0];

 wire [16:0] preview_read_address;
 wire [13:0] vga_roi_read_address,cnn_roi_read_address;
 wire [13:0] shared_roi_read_address;
 wire [7:0] preview_gray,roi_gray;
 wire frame_complete,frame_seen_vga;
 wire completed_bank,frame_request,frame_ack,vga_read_bank;
 wire [7:0] cnn_pixel;
 wire cnn_pixel_valid,cnn_eof,roi_busy;
 wire [7:0] processed_cnn_pixel;
 wire processed_cnn_pixel_valid,preprocess_busy;
 wire [7:0] cnn_input_debug_pixel,cnn_debug_display_pixel;
 wire cnn_input_debug_valid;
 wire [9:0] cnn_debug_read_address;
 wire [6:0] history_selected_record;
 wire [3:0] history_actual_digit,history_predicted_digit;
 wire history_selected_valid,history_has_records;
 wire [6:0] history_record_count;
 wire processing_busy;
 wire [3:0] classified_digit;
 wire digit_valid;
 reg result_valid_latched;
 reg result_toggle;

 // Sincroniza KEY[1] no dominio VGA e detecta o pressionamento.
 reg key1_meta,key1_sync,key1_previous;
 always @(posedge VGA_CLK or negedge reset_n) begin
  if(!reset_n) begin
   key1_meta<=1'b1;key1_sync<=1'b1;key1_previous<=1'b1;
  end else begin
   key1_meta<=KEY[1];key1_sync<=key1_meta;key1_previous<=key1_sync;
  end
 end
 wire key_classify_request=key1_previous&&!key1_sync;

 // EX_IO[5] recebe do ESP32 um pulso de solicitacao de classificacao.
 // O sincronizador evita metastabilidade, pois o GPIO do ESP32 nao pertence
 // ao dominio de clock VGA. A borda de subida produz um unico ciclo de pulso,
 // mesmo que o ESP32 mantenha o pino alto por varios milissegundos.
 reg esp_trigger_meta,esp_trigger_sync,esp_trigger_previous;
 always @(posedge VGA_CLK or negedge reset_n) begin
  if(!reset_n) begin
   esp_trigger_meta<=1'b0;
   esp_trigger_sync<=1'b0;
   esp_trigger_previous<=1'b0;
  end else begin
   esp_trigger_meta<=EX_IO[5];
   esp_trigger_sync<=esp_trigger_meta;
   esp_trigger_previous<=esp_trigger_sync;
  end
 end
 wire esp_classify_request=esp_trigger_sync&&!esp_trigger_previous;

 // Mantem o botao manual e acrescenta o comando externo. Uma solicitacao
 // somente e aceita quando existe quadro valido e o caminho esta livre.
 wire classify_request=key_classify_request||esp_classify_request;
 wire classify_start=classify_request&&frame_seen_vga&&!processing_busy;

 // KEY[2]/KEY[3] passam por debounce para que um pressionamento fisico
 // corresponda exatamente a um passo no historico.
 wire key2_level_unused,key3_level_unused,key2_tick,key3_tick;
 debounce_explicit history_previous_button(
  .clk(VGA_CLK),.rst_n(reset_n),.sw(~KEY[2]),
  .db_level(key2_level_unused),.db_tick(key2_tick));
 debounce_explicit history_next_button(
  .clk(VGA_CLK),.rst_n(reset_n),.sw(~KEY[3]),
  .db_level(key3_level_unused),.db_tick(key3_tick));
 wire history_previous=key2_tick&&SW[2];
 wire history_next=key3_tick&&SW[2];

 // Indicador persistente de uma nova classificacao concluida. Ele e limpo
 // no disparo e volta a um quando a CNN produz digit_valid.
 always @(posedge VGA_CLK or negedge reset_n) begin
  if(!reset_n)result_valid_latched<=1'b0;
  else begin
   if(classify_start)result_valid_latched<=1'b0;
   if(digit_valid)result_valid_latched<=1'b1;
  end
 end

 // Interface de registro externo. O toggle muda uma unica vez para cada
 // nova classificacao e permanece estavel, portanto pode ser detectado por
 // um microcontrolador muito mais lento que o clock VGA.
 always @(posedge VGA_CLK or negedge reset_n) begin
  if(!reset_n)result_toggle<=1'b0;
  else if(digit_valid)result_toggle<=~result_toggle;
 end

 pll_test camera_clock_pll(.inclk0(CLOCK3_50),.areset(~reset_n),.c0(MIPI_REFCLK));
 VIDEO_PLL vga_clock_pll(.inclk0(CLOCK2_50),.areset(~reset_n),.c0(VGA_CLK));

 // Somente configuracao SCCB; o fluxo de pixels usa o framebuffer abaixo.
 camera_interface camera_configuration(
  .clk(CLOCK_50),.clk_100(CLOCK_50),.rst_n(reset_n),.key(4'b1111),
  .rd_en(1'b1),.data_count_r(unused_count),.dout(unused_dout),
  .pixel_out(unused_pixel),.pixel_valid(unused_pixel_valid),
  .config_done(camera_config_done),
  .cmos_pclk(MIPI_PIXEL_CLK),.cmos_href(MIPI_PIXEL_HS),
  .cmos_vsync(MIPI_PIXEL_VS),.cmos_db(camera_bus),
  .cmos_sda(CAMERA_I2C_SDA),.cmos_scl(CAMERA_I2C_SCL),
  .cmos_rst_n(),.cmos_pwdn(),.cmos_xclk(),.led(unused_camera_led)
 );

 // A CNN assume temporariamente a porta de leitura da ROI. A escrita da
 // camera e a leitura do preview permanecem exatamente como na versao testada.
 assign shared_roi_read_address=roi_busy?cnn_roi_read_address:
                                          vga_roi_read_address;

 ov7670_preview_roi_buffer framebuffer(
  .reset_n(reset_n),.capture_enable(camera_config_done),
  .pclk(MIPI_PIXEL_CLK),.href(MIPI_PIXEL_HS),.vsync(MIPI_PIXEL_VS),
  .pixel_data(camera_bus),.read_clk(VGA_CLK),.read_bank(vga_read_bank),
  .preview_read_address(preview_read_address),
  .roi_read_address(shared_roi_read_address),.frame_ack(frame_ack),
  .preview_gray(preview_gray),.roi_gray(roi_gray),
  .completed_bank(completed_bank),.frame_request(frame_request),
  .frame_complete(frame_complete)
 );

 vga_640x480_minimal display(
  .reset_n(reset_n),.pixel_clk(VGA_CLK),
  .preview_gray(preview_gray),.roi_gray(roi_gray),.roi_zoom(SW[1]),
  .cnn_debug_mode(SW[2]),.cnn_debug_pixel(cnn_debug_display_pixel),
  .cnn_debug_ready(history_selected_valid),
  .camera_frame_complete(frame_complete),.completed_bank(completed_bank),
  .frame_request(frame_request),.frame_ack(frame_ack),
  .hold_read_bank(roi_busy),.read_bank(vga_read_bank),
  .preview_read_address(preview_read_address),
  .roi_read_address(vga_roi_read_address),
  .cnn_debug_read_address(cnn_debug_read_address),
  .frame_seen(frame_seen_vga),.vga_hs(VGA_HS),.vga_vs(VGA_VS),
  .vga_blank_n(VGA_BLANK_N),.vga_sync_n(VGA_SYNC_N),
  .vga_r(VGA_R),.vga_g(VGA_G),.vga_b(VGA_B)
 );

 roi_cnn_reader #(.THRESHOLD(8'd100)) roi_reader(
  .clk(VGA_CLK),.reset_n(reset_n),.start(classify_start),
  .frame_available(frame_seen_vga),.roi_gray(roi_gray),
  .digit_valid(digit_valid),.roi_address(cnn_roi_read_address),
  .cnn_pixel(cnn_pixel),.cnn_pixel_valid(cnn_pixel_valid),
  .cnn_eof(cnn_eof),.busy(roi_busy),
  .result_valid_latched()
 );

 assign processing_busy=roi_busy||preprocess_busy;
 wire history_capture_start=classify_start&&frame_seen_vga&&!roi_busy;

 // Pos-processamento validado no modelo bit-accurate: ganho x2 com
 // saturacao e centralizacao pelo centro de massa ponderado.
 cnn_center_gain_30x30 cnn_preprocessor(
  .clk(VGA_CLK),.reset_n(reset_n),
  .pixel_in(cnn_pixel),.pixel_in_valid(cnn_pixel_valid),
  .pixel_out(processed_cnn_pixel),
  .pixel_out_valid(processed_cnn_pixel_valid),
  .busy(preprocess_busy)
 );

 // O fluxo entregue ao nucleo continua sendo exatamente 30x30 (900 pixels).
 cam2cnn #(.PIC_DIM_MULTIPLIER(1),.PIC_DIM(30)) classifier(
  .clk(VGA_CLK),.rst(reset_n),.EOF(cnn_eof),
  .raw_pixel(processed_cnn_pixel),
  .raw_pixel_valid(processed_cnn_pixel_valid),
  .test_mode(1'b0),.test_pixel(8'd0),
  .test_pixel_valid(1'b0),
  .digit(classified_digit),.digit_valid_output(digit_valid),
  .cnn_input_debug_pixel(cnn_input_debug_pixel),
  .cnn_input_debug_valid(cnn_input_debug_valid)
 );

 cnn_history_100 history_30x30(
  .clk(VGA_CLK),.reset_n(reset_n),
  .capture_start(history_capture_start),.actual_digit(SW[7:4]),
  .cnn_pixel(cnn_input_debug_pixel),
  .cnn_pixel_valid(cnn_input_debug_valid),
  .digit_valid(digit_valid),.predicted_digit(classified_digit),
  .previous_record(history_previous),.next_record(history_next),
  .display_pixel_address(cnn_debug_read_address),
  .display_pixel(cnn_debug_display_pixel),
  .selected_record(history_selected_record),
  .selected_actual_digit(history_actual_digit),
  .selected_predicted_digit(history_predicted_digit),
  .selected_record_valid(history_selected_valid),
  .has_records(history_has_records),.record_count(history_record_count)
 );

 wire [3:0] displayed_prediction=(SW[2]&&history_selected_valid)?
                                 history_predicted_digit:classified_digit;
 wire [3:0] history_index_tens=history_selected_record/7'd10;
 wire [3:0] history_index_units=history_selected_record%7'd10;
 wire [6:0] prediction_segments,index_tens_segments,index_units_segments;
 wire [6:0] actual_segments;
 segment7 prediction_display(.bcd(displayed_prediction),
                             .seg(prediction_segments));
 segment7 index_tens_display(.bcd(history_index_tens),
                             .seg(index_tens_segments));
 segment7 index_units_display(.bcd(history_index_units),
                              .seg(index_units_segments));
 segment7 actual_digit_display(.bcd(history_actual_digit),
                               .seg(actual_segments));
 assign HEX7=(SW[2]&&!history_selected_valid)?7'h7F:prediction_segments;
 assign HEX6=SW[2]?index_tens_segments:7'h7F;
 assign HEX5=SW[2]?index_units_segments:7'h7F;
 assign HEX4=(SW[2]&&history_selected_valid)?actual_segments:7'h7F;

 assign CAMERA_PWDN_n=1'b0;
 assign MIPI_RESET_n=reset_n;
 assign MIPI_CS_n=1'b1;assign MIPI_MCLK=1'b0;
 assign MIPI_I2C_SCL=1'bz;assign MIPI_I2C_SDA=1'bz;

 // Conector de 14 pinos EX_IO da DE2-115:
 // [3:0] classe prevista; [4] alterna a cada resultado novo;
 // [5] entrada de disparo vinda do ESP32; [6] quadro valido disponivel.
 assign EX_IO[3:0]=classified_digit;
 assign EX_IO[4]=result_toggle;
 assign EX_IO[6]=frame_seen_vga;

 // SDRAM externa inativa nesta arquitetura.
 assign DRAM_ADDR=13'b0;assign DRAM_BA=2'b0;
 assign DRAM_CAS_N=1'b1;assign DRAM_CKE=1'b0;assign DRAM_CLK=1'b0;
 assign DRAM_CS_N=1'b1;assign DRAM_DQ=32'bz;assign DRAM_DQM=4'hF;
 assign DRAM_RAS_N=1'b1;assign DRAM_WE_N=1'b1;

 // LEDR[0]: SCCB, [1]: quadro completo, [2]: quadro liberado ao VGA.
 // LEDG[0]: resultado valido, [1]: processamento ocupado,
 // [2]: quadro disponivel, [3]: configuracao da camera concluida,
 // [4]: reservado; [5]: existem registros; [6]: registro selecionado valido.
 assign LEDR={15'b0,frame_seen_vga,frame_complete,camera_config_done};
 assign LEDG={2'b0,history_selected_valid,history_has_records,1'b0,camera_config_done,frame_seen_vga,processing_busy,
             result_valid_latched};
 assign HEX0=7'h7F;assign HEX1=7'h7F;assign HEX2=7'h7F;assign HEX3=7'h7F;
 wire unused_sw=^{SW[17:8],SW[3],SW[0],history_record_count};
endmodule
