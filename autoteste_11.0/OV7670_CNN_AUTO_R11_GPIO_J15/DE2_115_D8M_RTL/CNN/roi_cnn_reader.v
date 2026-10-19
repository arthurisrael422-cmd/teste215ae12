// Normaliza a ROI 90x90 antes de entrega-la a CNN.
//
// Passagem 1: encontra a caixa delimitadora dos pixels escuros.
// Passagem 2: preserva a proporcao, ajusta o maior lado para 20 pixels,
//             centraliza em 30x30 e calcula a intensidade media da celula.
//
// A porta de leitura da ROI tem endereco registrado. SCAN_PRIME e CELL_PRIME
// absorvem exatamente esse ciclo de latencia.
module roi_cnn_reader #(
 parameter THRESHOLD = 8'd100
)(
 input  wire        clk,
 input  wire        reset_n,
 input  wire        start,
 input  wire        frame_available,
 input  wire [7:0]  roi_gray,
 input  wire        digit_valid,
 output reg  [13:0] roi_address,
 output reg  [7:0]  cnn_pixel,
 output wire        cnn_pixel_valid,
 output reg         cnn_eof,
 output wire        busy,
 output reg         result_valid_latched
);
 localparam [3:0] IDLE        =4'd0,
                  SCAN_PRIME  =4'd1,
                  SCAN        =4'd2,
                  PREPARE     =4'd3,
                  OUT_SETUP   =4'd4,
                  CELL_PRIME  =4'd5,
                  CELL_READ   =4'd6,
                  AVERAGE     =4'd7,
                  SEND_PIXEL  =4'd8,
                  WAIT_RESULT =4'd9;

 reg [3:0] state;
 reg [13:0] scan_count;
 reg [6:0] scan_x,scan_y;
 reg       ink_found;
 reg [6:0] min_x,max_x,min_y,max_y;

 reg [4:0] out_x,out_y;
 reg [6:0] square_side;
 reg signed [9:0] square_x0,square_y0;
 reg [6:0] cell_x0,cell_x1,cell_y0,cell_y1;
 reg [6:0] cell_x,cell_y;
 reg [12:0] ink_sum;
 reg [5:0] sample_count;
 reg [12:0] avg_dividend;
 reg [5:0] avg_divisor;
 reg [7:0] avg_quotient;

 wire ink_detected=(roi_gray<=THRESHOLD);
 wire [7:0] ink_value=ink_detected?(8'd255-roi_gray):8'd0;

 wire [6:0] bbox_width=max_x-min_x+1'b1;
 wire [6:0] bbox_height=max_y-min_y+1'b1;
 wire [6:0] bbox_side=(bbox_width>=bbox_height)?bbox_width:bbox_height;
 wire signed [9:0] initial_square_x0=
      $signed({3'b000,min_x})-
      $signed({3'b000,((bbox_side-bbox_width)>>1)});
 wire signed [9:0] initial_square_y0=
      $signed({3'b000,min_y})-
      $signed({3'b000,((bbox_side-bbox_height)>>1)});

 // A area normalizada ocupa x=5..24 e y=5..24. Para cada pixel de
 // destino, os limites abaixo identificam a celula correspondente da caixa
 // quadrada de origem. A divisao e por uma constante (20), nao por variavel.
 wire active_output=(out_x>=5'd5)&&(out_x<=5'd24)&&
                    (out_y>=5'd5)&&(out_y<=5'd24);
 wire [4:0] norm_x=out_x-5'd5;
 wire [4:0] norm_y=out_y-5'd5;
 wire [11:0] x_product0=norm_x*square_side;
 wire [11:0] y_product0=norm_y*square_side;
 wire [11:0] x_product1=((norm_x+1'b1)*square_side)-1'b1;
 wire [11:0] y_product1=((norm_y+1'b1)*square_side)-1'b1;
 wire [6:0] scaled_x0=x_product0/12'd20;
 wire [6:0] scaled_x1=x_product1/12'd20;
 wire [6:0] scaled_y0=y_product0/12'd20;
 wire [6:0] scaled_y1=y_product1/12'd20;
 wire signed [10:0] calc_x0=$signed({square_x0[9],square_x0})+
                                  $signed({4'b0000,scaled_x0});
 wire signed [10:0] calc_x1=$signed({square_x0[9],square_x0})+
                                  $signed({4'b0000,scaled_x1});
 wire signed [10:0] calc_y0=$signed({square_y0[9],square_y0})+
                                  $signed({4'b0000,scaled_y0});
 wire signed [10:0] calc_y1=$signed({square_y0[9],square_y0})+
                                  $signed({4'b0000,scaled_y1});
 wire cell_outside=(calc_x1<0)||(calc_y1<0)||(calc_x0>11'sd89)||
                   (calc_y0>11'sd89);
 wire [6:0] clamped_x0=(calc_x0<0)?7'd0:
                       (calc_x0>11'sd89)?7'd89:calc_x0[6:0];
 wire [6:0] clamped_x1=(calc_x1<0)?7'd0:
                       (calc_x1>11'sd89)?7'd89:calc_x1[6:0];
 wire [6:0] clamped_y0=(calc_y0<0)?7'd0:
                       (calc_y0>11'sd89)?7'd89:calc_y0[6:0];
 wire [6:0] clamped_y1=(calc_y1<0)?7'd0:
                       (calc_y1>11'sd89)?7'd89:calc_y1[6:0];

 assign busy=(state!=IDLE);
 assign cnn_pixel_valid=(state==SEND_PIXEL);

 always @(posedge clk or negedge reset_n) begin
  if(!reset_n) begin
   state<=IDLE;scan_count<=14'd0;scan_x<=7'd0;scan_y<=7'd0;
   ink_found<=1'b0;min_x<=7'd89;max_x<=7'd0;min_y<=7'd89;max_y<=7'd0;
   out_x<=5'd0;out_y<=5'd0;square_side<=7'd1;
   square_x0<=10'sd0;square_y0<=10'sd0;
   cell_x0<=7'd0;cell_x1<=7'd0;cell_y0<=7'd0;cell_y1<=7'd0;
   cell_x<=7'd0;cell_y<=7'd0;ink_sum<=13'd0;sample_count<=6'd0;
   avg_dividend<=13'd0;avg_divisor<=6'd1;avg_quotient<=8'd0;
   roi_address<=14'd0;cnn_pixel<=8'd0;cnn_eof<=1'b0;
   result_valid_latched<=1'b0;
  end else begin
   cnn_eof<=1'b0;
   case(state)
    IDLE: begin
     roi_address<=14'd0;scan_count<=14'd0;scan_x<=7'd0;scan_y<=7'd0;
     out_x<=5'd0;out_y<=5'd0;
     if(start&&frame_available) begin
      ink_found<=1'b0;min_x<=7'd89;max_x<=7'd0;
      min_y<=7'd89;max_y<=7'd0;
      result_valid_latched<=1'b0;
      state<=SCAN_PRIME;
     end
    end

    SCAN_PRIME: begin
     // O endereco zero chega a saida; deixa o endereco 1 preparado para que
     // a passagem sequencial continue com um pixel correto por ciclo.
     roi_address<=14'd1;
     state<=SCAN;
    end

    SCAN: begin
     if(ink_detected) begin
      ink_found<=1'b1;
      if(!ink_found||scan_x<min_x)min_x<=scan_x;
      if(!ink_found||scan_x>max_x)max_x<=scan_x;
      if(!ink_found||scan_y<min_y)min_y<=scan_y;
      if(!ink_found||scan_y>max_y)max_y<=scan_y;
     end
     if(scan_count==14'd8099) begin
      state<=PREPARE;
     end else begin
      scan_count<=scan_count+1'b1;
      // No penultimo ciclo, 8099 ja esta apresentado para a RAM.
      // Mantemos esse endereco para nao selecionar a posicao inexistente 8100.
      if(scan_count<14'd8098)
       roi_address<=roi_address+1'b1;
      if(scan_x==7'd89) begin
       scan_x<=7'd0;scan_y<=scan_y+1'b1;
      end else scan_x<=scan_x+1'b1;
     end
    end

    PREPARE: begin
     out_x<=5'd0;out_y<=5'd0;cnn_pixel<=8'd0;
     if(ink_found) begin
      square_side<=bbox_side;
      square_x0<=initial_square_x0;
      square_y0<=initial_square_y0;
     end else begin
      square_side<=7'd1;square_x0<=10'sd0;square_y0<=10'sd0;
     end
     state<=OUT_SETUP;
    end

    OUT_SETUP: begin
     ink_sum<=13'd0;
     sample_count<=6'd0;
     if(!ink_found||!active_output||cell_outside) begin
      cnn_pixel<=8'd0;
      state<=SEND_PIXEL;
     end else begin
      cell_x0<=clamped_x0;cell_x1<=clamped_x1;
      cell_y0<=clamped_y0;cell_y1<=clamped_y1;
      cell_x<=clamped_x0;cell_y<=clamped_y0;
      roi_address<=clamped_y0*14'd90+clamped_x0;
      state<=CELL_PRIME;
     end
    end

    CELL_PRIME: begin
     // O primeiro endereco da celula e registrado pela M9K neste flanco.
     state<=CELL_READ;
    end

    CELL_READ: begin
     if((cell_x==cell_x1)&&(cell_y==cell_y1)) begin
      // Inclui a amostra atual nos dois operandos. A divisao e executada
      // sequencialmente no estado AVERAGE para evitar um divisor combinacional.
      avg_dividend<=ink_sum+ink_value;
      avg_divisor<=sample_count+1'b1;
      avg_quotient<=8'd0;
      state<=AVERAGE;
     end else if(cell_x<cell_x1) begin
      ink_sum<=ink_sum+ink_value;
      sample_count<=sample_count+1'b1;
      cell_x<=cell_x+1'b1;
      roi_address<=cell_y*14'd90+(cell_x+1'b1);
      state<=CELL_PRIME;
     end else begin
      ink_sum<=ink_sum+ink_value;
      sample_count<=sample_count+1'b1;
      cell_x<=cell_x0;cell_y<=cell_y+1'b1;
      roi_address<=(cell_y+1'b1)*14'd90+cell_x0;
      state<=CELL_PRIME;
     end
    end

    AVERAGE: begin
     // Quociente inteiro: soma das intensidades / numero de amostras.
     // O resultado fica entre 0 e 255 e produz tons intermediarios nas bordas.
     if(avg_dividend>=avg_divisor) begin
      avg_dividend<=avg_dividend-avg_divisor;
      if(avg_quotient<8'd255)
       avg_quotient<=avg_quotient+1'b1;
     end else begin
      cnn_pixel<=avg_quotient;
      state<=SEND_PIXEL;
     end
    end

    SEND_PIXEL: begin
     // cnn_pixel_valid fica alto durante este estado. O nucleo amostra o
     // valor neste flanco; em seguida preparamos o proximo pixel.
     if((out_x==5'd29)&&(out_y==5'd29)) begin
      state<=WAIT_RESULT;
     end else begin
      if(out_x==5'd29) begin out_x<=5'd0;out_y<=out_y+1'b1;end
      else out_x<=out_x+1'b1;
      state<=OUT_SETUP;
     end
    end

    WAIT_RESULT: begin
     if(digit_valid) begin
      // Rearma o cam2cnn depois que a classificacao terminou.
      cnn_eof<=1'b1;
      result_valid_latched<=1'b1;
      state<=IDLE;
     end
    end
    default: state<=IDLE;
   endcase
  end
 end
endmodule
