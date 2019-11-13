// Snake VGA game
// Nathan Riding and Dylan Maxfield

module pong(clk_16, vga_h_sync, vga_v_sync, vga_R, vga_G, vga_B, btn1, btn2, btn3, btn4, reset, USBPU);
input clk_16;
output vga_h_sync, vga_v_sync, vga_R, vga_G, vga_B;
input btn1, btn2, btn3, btn4, reset;
output USBPU;

wire inDisplayArea;
wire [9:0] CounterX;
wire [8:0] CounterY;
wire locked, clk;

assign USBPU = 0;

reg [1:0] move_direction;

 SB_PLL40_CORE #(
                .FEEDBACK_PATH("SIMPLE"),
                .DIVR(4'b0000),         // DIVR =  0
                .DIVF(7'b0110001),      // DIVF = 49
                .DIVQ(3'b101),          // DIVQ =  5
                .FILTER_RANGE(3'b001)   // FILTER_RANGE = 1
        ) uut (
                .LOCK(locked),
                .RESETB(1'b1),
                .BYPASS(1'b0),
                .REFERENCECLK(clk_16),
                .PLLOUTCORE(clk)
                );


hvsync_generator syncgen(.clk(clk), .vga_h_sync(vga_h_sync), .vga_v_sync(vga_v_sync),
  .inDisplayArea(inDisplayArea), .CounterX(CounterX), .CounterY(CounterY));

/////////////////////////////////////////////////////////////////

reg [3:0] bodyPositionX[0:15];
reg [3:0] bodyPositionY[0:15];
reg [15:0] bodyMap[0:13];

reg [3:0] headPosition;
reg [3:0] tailPosition;

  //bodyPositionX[1] = 2;
  //bodyPositionY[1] = 3;
  //bodyMap[3][2] = 1;
integer clk_counter;

  always @(btn1 or btn2 or btn3 or btn4 or reset) begin
    if (~btn1) begin //left
      if (move_direction != 2) begin
        move_direction = 0;
      end
    end
    else if (~btn2) begin // up
        if (move_direction != 3) begin
          move_direction = 1;
        end
      end
    else if (~btn3) begin //right
        if (move_direction != 0) begin
          move_direction = 2;
        end
      end
    else if (~btn4) begin //down
        if (move_direction != 1) begin
          move_direction = 3;
        end
      end
end
always @(posedge clk) begin
clk_counter <= clk_counter + 1;
if (~reset) begin
  bodyPositionX[0] <= 2;
  bodyPositionY[0] <= 2;
  bodyPositionX[1] <= 3;
  bodyPositionX[1] <= 2;
  bodyPositionX[2] <= 4;
  bodyPositionY[2] <= 2;
  bodyPositionX[3] <= 5;
  bodyPositionY[3] <= 2;

  bodyMap[0] <= 0;
  bodyMap[1] <= 0;
  bodyMap[2] <= 0;
  bodyMap[3] <= 0;
  bodyMap[4] <= 0;
  bodyMap[5] <= 0;
  bodyMap[6] <= 0;
  bodyMap[7] <= 0;
  bodyMap[8] <= 0;
  bodyMap[9] <= 0;
  bodyMap[10] <= 0;
  bodyMap[11] <= 0;
  bodyMap[12] <= 0;
  bodyMap[13] <= 0;

  bodyMap[2][3] <= 1;
  bodyMap[2][4] <= 1;
  bodyMap[2][5] <= 1;

  headPosition <= 3;
  tailPosition <= 0;
end
else if (clk_counter == 8000000) begin
 clk_counter <= 0;
	if (move_direction == 0) begin //Left
    bodyPositionX[headPosition + 1] <= bodyPositionX[headPosition] - 1;
    bodyPositionY[headPosition + 1] <= bodyPositionY[headPosition];
    tailPosition <= tailPosition + 1;
    headPosition <= headPosition + 1;
      end
  else if (move_direction == 1) begin //up
    bodyPositionX[headPosition + 1] <= bodyPositionX[headPosition];// - 1;
    bodyPositionY[headPosition + 1] <= bodyPositionY[headPosition] - 1;
    tailPosition <= tailPosition + 1;
    headPosition <= headPosition + 1;
    end
  else if (move_direction == 2) begin //right
  bodyPositionX[headPosition + 1] <= bodyPositionX[headPosition] + 1;
  bodyPositionY[headPosition + 1] <= bodyPositionY[headPosition];
  tailPosition <= tailPosition + 1;
  headPosition <= headPosition + 1;
  end
  else if (move_direction == 3) begin //down
  bodyPositionX[headPosition + 1] <= bodyPositionX[headPosition];
  bodyPositionY[headPosition + 1] <= bodyPositionY[headPosition] + 1;
  tailPosition <= tailPosition + 1;
  headPosition <= headPosition + 1;
  end
    bodyMap[bodyPositionY[headPosition]][bodyPositionX[headPosition]] <= 1;
    bodyMap[bodyPositionY[tailPosition]][bodyPositionX[tailPosition]] <= 0;
  end
end

/////////////////////////////////////////////////////////////////

wire border = (CounterX[9:3]==0) || (CounterX[9:3]==79) || (CounterY[8:3]==0) || (CounterY[8:3]==59);
wire paddle = bodyMap[CounterY[8:5]][CounterX[8:5]];//(CounterX>=PaddlePosition+8) && (CounterX<=PaddlePosition+24) && (CounterY[8:4]==27);

/////////////////////////////////////////////////////////////////

wire R = border;
wire G = paddle;
wire B = border;

reg vga_R, vga_G, vga_B;
always @(posedge clk)
begin
	vga_R <= R & inDisplayArea;
	vga_G <= G & inDisplayArea;
	vga_B <= B & inDisplayArea;
end

endmodule
