// Fonte de autoteste da CNN com 30 imagens do conjunto oficial de teste MNIST.
// SW[7:4] seleciona o digito 0..9 e SW[9:8] seleciona a amostra 0..2.
// Cada imagem original 28x28 recebe uma borda preta de um pixel, formando
// exatamente a entrada 30x30 esperada pelo nucleo do projeto.
module cnn_selftest_source(
 input  wire       clk,
 input  wire       reset_n,
 input  wire       start,
 input  wire       digit_valid,
 input  wire [3:0] test_digit,
 input  wire [1:0] test_sample,
 output wire [3:0] expected_digit,
 output wire [7:0] pixel,
 output wire       pixel_valid,
 output wire       busy,
 output reg        done_pulse
);
 localparam [1:0] IDLE=2'd0, PRIME=2'd1, STREAM=2'd2, WAIT_RESULT=2'd3;

 // 30 imagens x 900 pixels x 8 bits = 216000 bits de ROM M9K.
 (* ramstyle = "M9K" *) reg [7:0] test_rom [0:26999];
 reg [7:0] rom_q;
 reg [14:0] rom_address;
 reg [14:0] image_base;
 reg [9:0] pixel_count;
 reg [1:0] state;

 wire [3:0] selected_digit=(test_digit<=4'd9)?test_digit:4'd0;
 wire [1:0] selected_sample=(test_sample<=2'd2)?test_sample:2'd0;
 // Ordem da ROM: digito 0 amostras 0..2, depois digito 1, etc.
 wire [14:0] selected_base=(selected_digit*15'd2700)+
                            (selected_sample*15'd900);

 initial begin
  $readmemh("CNN/mnist_test_30.hex",test_rom);
 end

 assign expected_digit=selected_digit;
 assign pixel=rom_q;
 assign pixel_valid=(state==STREAM);
 assign busy=(state!=IDLE);

 always @(posedge clk) begin
  rom_q<=test_rom[rom_address];
 end

 always @(posedge clk or negedge reset_n) begin
  if(!reset_n) begin
   state<=IDLE;
   rom_address<=15'd0;
   image_base<=15'd0;
   pixel_count<=10'd0;
   done_pulse<=1'b0;
  end else begin
   done_pulse<=1'b0;
   case(state)
    IDLE: begin
     pixel_count<=10'd0;
     if(start) begin
      image_base<=selected_base;
      rom_address<=selected_base;
      state<=PRIME;
     end
    end
    PRIME: begin
     // selected_base e capturado pela ROM neste flanco. O primeiro pixel
     // estara em rom_q quando STREAM gerar o primeiro pixel_valid.
     rom_address<=image_base+1'b1;
     state<=STREAM;
    end
    STREAM: begin
     if(pixel_count==10'd899) begin
      pixel_count<=10'd0;
      rom_address<=image_base;
      state<=WAIT_RESULT;
     end else begin
      pixel_count<=pixel_count+1'b1;
      rom_address<=rom_address+1'b1;
     end
    end
    WAIT_RESULT: begin
     if(digit_valid) begin
      done_pulse<=1'b1;
      state<=IDLE;
     end
    end
    default: state<=IDLE;
   endcase
  end
 end
endmodule
