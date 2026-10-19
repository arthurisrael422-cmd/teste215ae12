// Historico circular das ultimas 32 entradas entregues ao nucleo CNN.
// Cada registro possui 900 pixels de 8 bits, rotulo real e classe prevista.
// A mesma M9K pode ser exportada pelo In-System Sources and Probes via JTAG.
// A RAM e volatil: seu conteudo permanece apenas enquanto a FPGA esta ligada.
module cnn_history_32(
 input  wire        clk,
 input  wire        reset_n,
 input  wire        capture_start,
 input  wire [3:0]  actual_digit,
 input  wire [7:0]  cnn_pixel,
 input  wire        cnn_pixel_valid,
 input  wire        digit_valid,
 input  wire [3:0]  predicted_digit,
 input  wire        previous_record,
 input  wire        next_record,
 input  wire [9:0]  display_pixel_address,
 output wire [7:0]  display_pixel,
 output wire [4:0]  selected_record,
 output wire [3:0]  selected_actual_digit,
 output wire [3:0]  selected_predicted_digit,
 output wire        selected_record_valid,
 output wire        has_records,
 output reg  [5:0]  record_count
);
 reg [3:0] actual_mem [0:31];
 reg [3:0] predicted_mem [0:31];
 reg [31:0] valid_records;

 reg [4:0] write_record;
 reg [4:0] pending_record;
 reg [4:0] browse_record;
 reg [9:0] write_pixel_address;
 reg capture_active;
 reg awaiting_result;
 reg [3:0] metadata_state;
 reg [4:0] metadata_record;
 reg [3:0] metadata_actual;
 reg [3:0] metadata_predicted;
 reg [5:0] metadata_count;

 // Mapa da RAM exportada:
 //   0..28799      : 32 imagens, 900 bytes por registro
 //   28800..28831  : rotulo real; bit 7 indica registro valido
 //   28832..28863  : classe prevista
 //   28864..28871  : cabecalho "H32R", versao, quantidade, proximo, ultimo
 localparam [14:0] ACTUAL_BASE    = 15'd28800;
 localparam [14:0] PREDICTED_BASE = 15'd28832;
 localparam [14:0] HEADER_BASE    = 15'd28864;

 wire [14:0] write_record_ext={10'd0,pending_record};
 wire [14:0] browse_record_ext={10'd0,browse_record};
 // 900 = 512 + 256 + 128 + 4. O deslocamento evita multiplicador.
 wire [14:0] write_record_base=(write_record_ext<<9)+
                               (write_record_ext<<8)+
                               (write_record_ext<<7)+
                               (write_record_ext<<2);
 wire [14:0] browse_record_base=(browse_record_ext<<9)+
                                (browse_record_ext<<8)+
                                (browse_record_ext<<7)+
                                (browse_record_ext<<2);
 wire [14:0] write_linear_address=write_record_base+write_pixel_address;
 wire [14:0] display_linear_address=browse_record_base+
                                              display_pixel_address;

 // A fonte JTAG possui um bit de selecao e o endereco completo da RAM.
 // Durante a exportacao, ela assume temporariamente a porta B. Fora da
 // exportacao, a visualizacao VGA continua usando essa porta normalmente.
 wire [15:0] jtag_source;
 wire        jtag_export_enable=jtag_source[15];
 wire [14:0] ram_read_address=jtag_export_enable?jtag_source[14:0]:
                                                    display_linear_address;

 reg        ram_write_enable;
 reg [14:0] ram_write_address;
 reg [7:0]  ram_write_data;

 // Pixels possuem prioridade. Os metadados sao escritos nos dez ciclos
 // seguintes a digit_valid, quando o fluxo de 900 pixels ja terminou.
 always @(*) begin
  ram_write_enable=1'b0;
  ram_write_address=15'd0;
  ram_write_data=8'd0;
  if(capture_active&&cnn_pixel_valid) begin
   ram_write_enable=1'b1;
   ram_write_address=write_linear_address;
   ram_write_data=cnn_pixel;
  end else begin
   case(metadata_state)
    4'd1: begin
     ram_write_enable=1'b1;
     ram_write_address=ACTUAL_BASE+metadata_record;
     ram_write_data={1'b1,3'b000,metadata_actual};
    end
    4'd2: begin
     ram_write_enable=1'b1;
     ram_write_address=PREDICTED_BASE+metadata_record;
     ram_write_data={4'b0000,metadata_predicted};
    end
    4'd3: begin ram_write_enable=1'b1;ram_write_address=HEADER_BASE;      ram_write_data=8'h48;end // H
    4'd4: begin ram_write_enable=1'b1;ram_write_address=HEADER_BASE+1'b1;ram_write_data=8'h33;end // 3
    4'd5: begin ram_write_enable=1'b1;ram_write_address=HEADER_BASE+2'd2;ram_write_data=8'h32;end // 2
    4'd6: begin ram_write_enable=1'b1;ram_write_address=HEADER_BASE+2'd3;ram_write_data=8'h52;end // R
    4'd7: begin ram_write_enable=1'b1;ram_write_address=HEADER_BASE+3'd4;ram_write_data=8'd3;end
    4'd8: begin ram_write_enable=1'b1;ram_write_address=HEADER_BASE+3'd5;ram_write_data={2'b00,metadata_count};end
    4'd9: begin ram_write_enable=1'b1;ram_write_address=HEADER_BASE+3'd6;ram_write_data={3'b000,metadata_record+1'b1};end
    4'd10:begin ram_write_enable=1'b1;ram_write_address=HEADER_BASE+3'd7;ram_write_data={3'b000,metadata_record};end
    default: begin end
   endcase
  end
 end

 assign selected_record=browse_record;
 assign selected_actual_digit=actual_mem[browse_record];
 assign selected_predicted_digit=predicted_mem[browse_record];
 assign selected_record_valid=valid_records[browse_record];
 assign has_records=(record_count!=6'd0);

 always @(posedge clk or negedge reset_n) begin
  if(!reset_n) begin
   valid_records<=32'd0;
   write_record<=5'd0;
   pending_record<=5'd0;
   browse_record<=5'd0;
   write_pixel_address<=10'd0;
   capture_active<=1'b0;
   awaiting_result<=1'b0;
   metadata_state<=4'd0;
   metadata_record<=5'd0;
   metadata_actual<=4'd0;
   metadata_predicted<=4'd0;
   metadata_count<=6'd0;
   record_count<=6'd0;
  end else begin
   // Navegacao fisica pelos 32 enderecos. Registros ainda nao preenchidos
   // aparecem pretos e selected_record_valid fica em zero.
   if(previous_record)browse_record<=browse_record-1'b1;
   else if(next_record)browse_record<=browse_record+1'b1;

   // Um novo registro somente e aceito quando o anterior terminou.
   if(capture_start&&!capture_active&&!awaiting_result&&
                    (metadata_state==4'd0)) begin
    pending_record<=write_record;
    actual_mem[write_record]<=actual_digit;
    valid_records[write_record]<=1'b0;
    write_pixel_address<=10'd0;
    capture_active<=1'b1;
   end else if(capture_active&&cnn_pixel_valid) begin
    if(write_pixel_address==10'd899) begin
     write_pixel_address<=10'd0;
     capture_active<=1'b0;
     awaiting_result<=1'b1;
    end else write_pixel_address<=write_pixel_address+1'b1;
   end

   // Associa o resultado somente depois que os 900 pixels foram gravados.
   if(awaiting_result&&digit_valid) begin
    predicted_mem[pending_record]<=predicted_digit;
    valid_records[pending_record]<=1'b1;
    browse_record<=pending_record;
    write_record<=pending_record+1'b1;
    awaiting_result<=1'b0;
    metadata_state<=4'd1;
    metadata_record<=pending_record;
    metadata_actual<=actual_mem[pending_record];
    metadata_predicted<=predicted_digit;
    if(record_count<6'd32) begin
     record_count<=record_count+1'b1;
     metadata_count<=record_count+1'b1;
    end else metadata_count<=6'd32;
   end

   if(metadata_state!=4'd0) begin
    if(metadata_state==4'd10)metadata_state<=4'd0;
    else metadata_state<=metadata_state+1'b1;
   end
  end
 end

 // RAM explicita: evita que o Quartus 18.1 transforme os 230.400 bits em
 // registradores quando a inferencia comportamental nao e reconhecida.
 cnn_history_m9k_ram history_pixels(
  .clk(clk),
  .write_enable(ram_write_enable),
  .write_address(ram_write_address),.write_data(ram_write_data),
  .read_address(ram_read_address),.read_data(display_pixel)
 );

 // Interface leve de depuracao. Diferentemente do Memory Content Editor,
 // nao tenta acrescentar uma porta fisica a M9K: apenas controla o mux acima.
 altsource_probe #(
  .sld_auto_instance_index("YES"),.sld_instance_index(0),
  .instance_id("H32D"),.probe_width(8),.source_width(16),
  .source_initial_value("0"),.enable_metastability("NO")
 ) history_jtag_access(
  .source(jtag_source),.probe(display_pixel),
  .source_clk(clk),.source_ena(1'b1)
 );
endmodule

// 32.768 x 8 bits. Pixels e metadados ocupam os enderecos 0..28.871.
// A profundidade em potencia de dois torna o mapeamento para M9K determinista.
module cnn_history_m9k_ram(
 input  wire        clk,
 input  wire        write_enable,
 input  wire [14:0] write_address,
 input  wire [7:0]  write_data,
 input  wire [14:0] read_address,
 output wire [7:0]  read_data
);
 altsyncram history_ram(
  .address_a(write_address),.address_b(read_address),
  .clock0(clk),.clock1(clk),
  .data_a(write_data),.wren_a(write_enable),.q_b(read_data),
  .aclr0(1'b0),.aclr1(1'b0),
  .addressstall_a(1'b0),.addressstall_b(1'b0),
  .byteena_a(1'b1),.byteena_b(1'b1),
  .clocken0(1'b1),.clocken1(1'b1),.clocken2(1'b1),.clocken3(1'b1),
  .data_b(8'd0),.eccstatus(),.q_a(),
  .rden_a(1'b1),.rden_b(1'b1),.wren_b(1'b0)
 );
 defparam
  history_ram.address_aclr_b="NONE",
  history_ram.address_reg_b="CLOCK1",
  history_ram.clock_enable_input_a="BYPASS",
  history_ram.clock_enable_input_b="BYPASS",
  history_ram.clock_enable_output_b="BYPASS",
  history_ram.intended_device_family="Cyclone IV E",
  history_ram.lpm_hint="ENABLE_RUNTIME_MOD=NO",
  history_ram.lpm_type="altsyncram",
  history_ram.numwords_a=32768,
  history_ram.numwords_b=32768,
  history_ram.operation_mode="DUAL_PORT",
  history_ram.outdata_aclr_b="NONE",
  history_ram.outdata_reg_b="UNREGISTERED",
  history_ram.power_up_uninitialized="TRUE",
  history_ram.ram_block_type="M9K",
  history_ram.read_during_write_mode_mixed_ports="DONT_CARE",
  history_ram.widthad_a=15,
  history_ram.widthad_b=15,
  history_ram.width_a=8,
  history_ram.width_b=8,
  history_ram.width_byteena_a=1;
endmodule
