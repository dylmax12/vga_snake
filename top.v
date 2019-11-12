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

always @(posedge clk) begin
clk_counter <= clk_counter + 1;
if (~reset) begin
  headPosition = 1;
  tailPosition = 0;
end
else if (clk_counter == 8000000) begin
 clk_counter <= 0;
	if (~btn1) begin //right
    bodyPositionX[headPosition + 1] <= bodyPositionX[headPosition] + 1;
    bodyPositionY[headPosition + 1] <= bodyPositionY[headPosition];
    tailPosition <= tailPosition + 1;
    headPosition <= headPosition + 1;
      end
  else if (~btn2) begin //up
    bodyPositionX[headPosition + 1] <= bodyPositionX[headPosition];// - 1;
    bodyPositionY[headPosition + 1] <= bodyPositionY[headPosition] - 1;
    tailPosition <= tailPosition + 1;
    headPosition <= headPosition + 1;
    end
  else if (~btn3) begin //down
  bodyPositionX[headPosition + 1] <= bodyPositionX[headPosition];
  bodyPositionY[headPosition + 1] <= bodyPositionY[headPosition] + 1;
  tailPosition <= tailPosition + 1;
  headPosition <= headPosition + 1;
  end
  else if (~btn4) begin //right
  bodyPositionX[headPosition + 1] <= bodyPositionX[headPosition] - 1;
  bodyPositionY[headPosition + 1] <= bodyPositionY[headPosition];
  tailPosition <= tailPosition + 1;
  headPosition <= headPosition + 1;
  end
    bodyMap[bodyPositionY[headPosition]][bodyPositionX[headPosition]] <= 1;
  end
    bodyMap[bodyPositionY[tailPosition]][bodyPositionX[tailPosition]] <= 0;
end
/////////////////////////////////////////////////////////////////
reg [9:0] ballX;
reg [8:0] ballY;
reg ball_inX, ball_inY;

always @(posedge clk)
if(ball_inX==0) ball_inX <= (CounterX==ballX) & ball_inY; else ball_inX <= !(CounterX==ballX+16);

always @(posedge clk)
if(ball_inY==0) ball_inY <= (CounterY==ballY); else ball_inY <= !(CounterY==ballY+16);

wire ball = ball_inX & ball_inY;

/////////////////////////////////////////////////////////////////
wire border = (CounterX[9:3]==0) || (CounterX[9:3]==79) || (CounterY[8:3]==0) || (CounterY[8:3]==59);
wire paddle = bodyMap[CounterY[8:5]][CounterX[8:5]];//(CounterX>=PaddlePosition+8) && (CounterX<=PaddlePosition+24) && (CounterY[8:4]==27);
//wire BouncingObject = border | paddle; // active if the border or paddle is redrawing itself

// reg ResetCollision;
// always @(posedge clk) ResetCollision <= (CounterY==500) & (CounterX==0);  // active only once for every video frame
//
// reg CollisionX1, CollisionX2, CollisionY1, CollisionY2;
// always @(posedge clk) if(ResetCollision) CollisionX1<=0; else if(BouncingObject & (CounterX==ballX   ) & (CounterY==ballY+ 8)) CollisionX1<=1;
// always @(posedge clk) if(ResetCollision) CollisionX2<=0; else if(BouncingObject & (CounterX==ballX+16) & (CounterY==ballY+ 8)) CollisionX2<=1;
// always @(posedge clk) if(ResetCollision) CollisionY1<=0; else if(BouncingObject & (CounterX==ballX+ 8) & (CounterY==ballY   )) CollisionY1<=1;
// always @(posedge clk) if(ResetCollision) CollisionY2<=0; else if(BouncingObject & (CounterX==ballX+ 8) & (CounterY==ballY+16)) CollisionY2<=1;

/////////////////////////////////////////////////////////////////
// wire UpdateBallPosition = ResetCollision;  // update the ball position at the same time that we reset the collision detectors
//
// reg ball_dirX, ball_dirY;
// always @(posedge clk)
// if(UpdateBallPosition)
// begin
// 	if(~(CollisionX1 & CollisionX2))        // if collision on both X-sides, don't move in the X direction
// 	begin
// 		ballX <= ballX + (ball_dirX ? -1 : 1);
// 		if(CollisionX2) ball_dirX <= 1; else if(CollisionX1) ball_dirX <= 0;
// 	end
//
// 	if(~(CollisionY1 & CollisionY2))        // if collision on both Y-sides, don't move in the Y direction
// 	begin
// 		ballY <= ballY + (ball_dirY ? -1 : 1);
// 		if(CollisionY2) ball_dirY <= 1; else if(CollisionY1) ball_dirY <= 0;
// 	end
// end

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
