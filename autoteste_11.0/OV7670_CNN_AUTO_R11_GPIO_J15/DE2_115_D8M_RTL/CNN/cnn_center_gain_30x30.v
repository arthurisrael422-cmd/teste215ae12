// Pos-processamento da imagem 30x30 antes da CNN.
//
// 1) aplica ganho x2 com saturacao em 255;
// 2) calcula o centro de massa ponderado pelas intensidades;
// 3) desloca a imagem para o centro geometrico (14,5;14,5);
// 4) transmite novamente os 900 pixels, preenchendo com zero as bordas.
//
// O buffer possui somente 900 bytes e deve ser implementado em M9K.
module cnn_center_gain_30x30 (
 input  wire       clk,
 input  wire       reset_n,
 input  wire [7:0] pixel_in,
 input  wire       pixel_in_valid,
 output wire [7:0] pixel_out,
 output wire       pixel_out_valid,
 output wire       busy
);
 localparam [3:0] IDLE       = 4'd0,
                  CAPTURE    = 4'd1,
                  PREP_X     = 4'd2,
                  SEARCH_X   = 4'd3,
                  PREP_Y     = 4'd4,
                  SEARCH_Y   = 4'd5,
                  OUT_SETUP  = 4'd6,
                  OUT_PRIME  = 4'd7,
                  OUT_SEND   = 4'd8;

 (* ramstyle = "M9K" *) reg [7:0] image_mem [0:899];
 reg [9:0] read_address;
 reg [7:0] memory_q;

 reg [3:0] state;
 reg [9:0] capture_address;
 reg [17:0] mass_sum;
 reg [22:0] mass_x;
 reg [22:0] mass_y;
 reg [4:0] capture_x;
 reg [4:0] capture_y;

 reg signed [5:0] candidate_shift;
 reg signed [5:0] shift_x;
 reg signed [5:0] shift_y;
 reg signed [27:0] search_error;
 reg [27:0] best_error_abs;

 reg [4:0] output_x;
 reg [4:0] output_y;
 reg source_inside;

 wire [8:0] doubled_pixel={pixel_in,1'b0};
 wire [7:0] gained_pixel=doubled_pixel[8]?8'hFF:doubled_pixel[7:0];

 wire [27:0] current_error_abs=search_error[27]?
                                     (~search_error+1'b1):search_error;

 wire signed [6:0] source_x_calc=$signed({2'b00,output_x})-
                                  $signed({shift_x[5],shift_x});
 wire signed [6:0] source_y_calc=$signed({2'b00,output_y})-
                                  $signed({shift_y[5],shift_y});
 wire source_calc_inside=(source_x_calc>=0)&&(source_x_calc<=7'sd29)&&
                         (source_y_calc>=0)&&(source_y_calc<=7'sd29);
 wire [9:0] source_calc_address=source_y_calc*7'sd30+source_x_calc;

 assign pixel_out=source_inside?memory_q:8'd0;
 assign pixel_out_valid=(state==OUT_SEND);
 assign busy=(state!=IDLE);

 // RAM de uma escrita e uma leitura no mesmo clock. A leitura registrada
 // acrescenta um ciclo, absorvido pelo estado OUT_PRIME.
 always @(posedge clk) begin
  if(pixel_in_valid&&((state==IDLE)||(state==CAPTURE)))
   image_mem[(state==IDLE)?10'd0:capture_address]<=gained_pixel;
  memory_q<=image_mem[read_address];
 end

 always @(posedge clk or negedge reset_n) begin
  if(!reset_n) begin
   state<=IDLE;
   capture_address<=10'd0;capture_x<=5'd0;capture_y<=5'd0;
   mass_sum<=18'd0;mass_x<=23'd0;mass_y<=23'd0;
   candidate_shift<=6'sd0;shift_x<=6'sd0;shift_y<=6'sd0;
   search_error<=28'sd0;best_error_abs<=28'hFFFFFFF;
   output_x<=5'd0;output_y<=5'd0;
   read_address<=10'd0;source_inside<=1'b0;
  end else begin
   case(state)
    IDLE: begin
     capture_address<=10'd0;capture_x<=5'd0;capture_y<=5'd0;
     output_x<=5'd0;output_y<=5'd0;
     if(pixel_in_valid) begin
      mass_sum<=gained_pixel;
      mass_x<=23'd0;
      mass_y<=23'd0;
      capture_address<=10'd1;
      capture_x<=5'd1;
      state<=CAPTURE;
     end
    end

    CAPTURE: begin
     if(pixel_in_valid) begin
      mass_sum<=mass_sum+gained_pixel;
      mass_x<=mass_x+(capture_x*gained_pixel);
      mass_y<=mass_y+(capture_y*gained_pixel);
      if(capture_address==10'd899) begin
       state<=PREP_X;
      end else begin
       capture_address<=capture_address+1'b1;
       if(capture_x==5'd29) begin
        capture_x<=5'd0;
        capture_y<=capture_y+1'b1;
       end else capture_x<=capture_x+1'b1;
      end
     end
    end

    PREP_X: begin
     if(mass_sum==0) begin
      shift_x<=6'sd0;
      state<=PREP_Y;
     end else begin
      // Erro dobrado para deslocamento -15:
      // 2*sum(x*I) + 2*(-15)*sum(I) - 29*sum(I).
      search_error<=($signed({1'b0,mass_x})*28'sd2)-
                    ($signed({1'b0,mass_sum})*28'sd59);
      candidate_shift<=-6'sd15;
      shift_x<=-6'sd15;
      best_error_abs<=28'hFFFFFFF;
      state<=SEARCH_X;
     end
    end

    SEARCH_X: begin
     // Em empate escolhe o deslocamento par, igual ao round() do Python.
     if((current_error_abs<best_error_abs)||
        ((current_error_abs==best_error_abs)&&!candidate_shift[0])) begin
      best_error_abs<=current_error_abs;
      shift_x<=candidate_shift;
     end
     if(candidate_shift==6'sd15) begin
      state<=PREP_Y;
     end else begin
      candidate_shift<=candidate_shift+1'b1;
      search_error<=search_error+($signed({1'b0,mass_sum})*28'sd2);
     end
    end

    PREP_Y: begin
     if(mass_sum==0) begin
      shift_y<=6'sd0;
      output_x<=5'd0;output_y<=5'd0;
      state<=OUT_SETUP;
     end else begin
      search_error<=($signed({1'b0,mass_y})*28'sd2)-
                    ($signed({1'b0,mass_sum})*28'sd59);
      candidate_shift<=-6'sd15;
      shift_y<=-6'sd15;
      best_error_abs<=28'hFFFFFFF;
      state<=SEARCH_Y;
     end
    end

    SEARCH_Y: begin
     if((current_error_abs<best_error_abs)||
        ((current_error_abs==best_error_abs)&&!candidate_shift[0])) begin
      best_error_abs<=current_error_abs;
      shift_y<=candidate_shift;
     end
     if(candidate_shift==6'sd15) begin
      output_x<=5'd0;output_y<=5'd0;
      state<=OUT_SETUP;
     end else begin
      candidate_shift<=candidate_shift+1'b1;
      search_error<=search_error+($signed({1'b0,mass_sum})*28'sd2);
     end
    end

    OUT_SETUP: begin
     source_inside<=source_calc_inside;
     if(source_calc_inside)
      read_address<=source_calc_address;
     else
      read_address<=10'd0;
     state<=OUT_PRIME;
    end

    OUT_PRIME: state<=OUT_SEND;

    OUT_SEND: begin
     if((output_x==5'd29)&&(output_y==5'd29)) begin
      state<=IDLE;
     end else begin
      if(output_x==5'd29) begin
       output_x<=5'd0;output_y<=output_y+1'b1;
      end else output_x<=output_x+1'b1;
      state<=OUT_SETUP;
     end
    end

    default: state<=IDLE;
   endcase
  end
 end
endmodule
