//Snake VGA game
//Nathan Riding and Dylan Maxfield

module snake(clk_16, vga_h_sync, vga_v_sync, vga_R, vga_G, vga_B, btn1, btn2, btn3, btn4, reset, USBPU);

//clock input from FPGA (16 MHz)
input clk_16;

//output resolution (horizontal and vertical) for vga as well as colors to light (red, green, and blue)
output vga_h_sync, vga_v_sync, vga_R, vga_G, vga_B;

//input pin values from the 4 buttons (left, up, right, down) and reset input
input btn1, btn2, btn3, btn4, reset;

reg game_over;
reg game_win;
integer size;
//USB Pull Up resistor, when set to 0 it disconnects the MicroUSB
//note: this is on bottom of board
output USBPU;
assign USBPU = 0;

//////////////////////////////////////////////////////////////////
//section for vga controller
//////////////////////////////////////////////////////////////////

//outputs of SB_PLL40_CORE locked is unused
//clk_25 is a 25MHz clock output for our VGA
wire locked, clk_25;

//SB_PLL40_CORE is from the iCE40 sysCLOCK PLL
//returns a scaled clock, based on input parameters for VGA
SB_PLL40_CORE #(
                .FEEDBACK_PATH("SIMPLE"), //Feedback is internal to PLL directly from VCO
                .DIVR(4'b0000),           //DIVR =  0, reference clock divider
                .DIVF(7'b0110001),        //DIVF = 49, feedback divider
                .DIVQ(3'b101),            //DIVQ =  5, VCO divider
                .FILTER_RANGE(3'b001)     //FILTER_RANGE = 1, PLL range
                ) uut (
                .LOCK(locked),            //output to show whether it is PLL aligned or locked to reference
                .RESETB(1'b1),            //input for reset (active low)
                .BYPASS(1'b0),            //input 0 means it is a PLL generated signal
                .REFERENCECLK(clk_16),    //input of reference clock
                .PLLOUTCORE(clk_25)       //output of PLL clock
                );

wire inDisplayArea;
wire [9:0] counterX;
wire [9:0] counterY;

VGA_gen vgen(.VGA_clk(clk_25), .xCount(counterX), .yCount(counterY),. displayArea(inDisplayArea), .VGA_hSync(vga_h_sync), .VGA_vSync(vga_v_sync));

//////////////////////////////////////////////////////////////////
//section for directional input
//////////////////////////////////////////////////////////////////

//register that holds the input direction (there are 4)
//0 = left
//1 = up
//2 = right
//3 = down
reg [1:0] move_direction;

always @(btn1 or btn2 or btn3 or btn4 or reset) begin
  if (~btn1 && btn2 && btn3 && btn4 && reset) begin //left
    if (move_direction != 2) begin
      move_direction = 2'b00;
    end
  end
  if (btn1 && ~btn2 && btn3 && btn4 && reset) begin // up
    if (move_direction != 3) begin
      move_direction = 1;
    end
  end
  if (btn1 && btn2 && ~btn3 && btn4 && reset) begin //right
    if (move_direction != 2'b00) begin
      move_direction = 2;
      end
  end
  if (btn1 && btn2 && btn3 && ~btn4 && reset) begin //down
    if (move_direction != 1) begin
      move_direction = 3;
    end
  end
  if (btn1 && btn2 && btn3 && btn4 && ~reset) begin
    //if reset is pressed then assign the direction to go right
    move_direction = 2;
  end
end

//////////////////////////////////////////////////////////////////
//section for snake logic
//////////////////////////////////////////////////////////////////

//a list of positions to remember the sankes body chain
reg [3:0] bodyPositionX[0:15];
reg [3:0] bodyPositionY[0:15];

//a pseudo 2-dimensional grid that shows which squares of snake should be lit
reg [15:0] bodyMap[0:15];

//the index within the bodyPosition of the begining and end of chain
reg [3:0] headPosition;
reg [3:0] tailPosition;

//the position of the apple
reg [3:0] applePositionX;
reg [3:0] applePositionY;

reg [3:0] tempAppleY;
reg [3:0] tempAppleX;

//a counter for a clock divider
//can hold up to 8,388,608
reg [22:0] clk_counter;

//reg resetFlag;

always @(posedge clk_16) begin
  //increment the counter by one to scale the clock
  clk_counter <= clk_counter + 1;

  //run the snake logic every 1/4 of a second .3 s
  if (clk_counter == 4500000) begin

    //reset the counter for future iterations
    clk_counter <= 0;

    //if the reset is triggered assign the default values
    if (~reset) begin
      //snake chain location
      bodyPositionX[0] <= 2;
      bodyPositionY[0] <= 2;

      bodyPositionX[1] <= 3;
      bodyPositionY[1] <= 2;

      bodyPositionX[2] <= 4;
      bodyPositionY[2] <= 2;

      bodyPositionX[3] <= 5;
      bodyPositionY[3] <= 2;

      //snake output map reset
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
      bodyMap[14] <= 0;

      //assign which snake blocks are visible
      bodyMap[2][3] <= 1;
      bodyMap[2][4] <= 1;
      bodyMap[2][5] <= 1;

      //set the head and tail position to that of the chain
      headPosition <= 3;
      tailPosition <= 0;

      //place the apple somewhere
      applePositionX <= 0;
      applePositionY <= 0;

      game_over <= 1'b0;
      game_win <= 1'b0;
      size = 3;
    end
    else begin

    //check for the next snake direction and move accordingly
      if (move_direction == 0) begin //left
      //  game_over <= (bodyPositionX[headPosition] - 1) == 0 || bodyMap[bodyPositionY[headPosition]][bodyPositionX[headPosition] - 1];
        bodyPositionX[headPosition + 1] <= bodyPositionX[headPosition] - 1;
        bodyPositionY[headPosition + 1] <= bodyPositionY[headPosition];
      end
      else if (move_direction == 1) begin //up
      //  game_over <= (bodyPositionY[headPosition] - 1) == 0 || bodyMap[bodyPositionY[headPosition] - 1][bodyPositionX[headPosition]];
        bodyPositionX[headPosition + 1] <= bodyPositionX[headPosition];
        bodyPositionY[headPosition + 1] <= bodyPositionY[headPosition] - 1;
      end
      else if (move_direction == 2) begin //right
        //= (bodyPositionX[headPosition] + 1) == 15 || bodyMap[bodyPositionY[headPosition]][bodyPositionX[headPosition] + 1];
        bodyPositionX[headPosition + 1] <= bodyPositionX[headPosition] + 1;
        bodyPositionY[headPosition + 1] <= bodyPositionY[headPosition];
      end
      else if (move_direction == 3) begin //down
        //game_over <= (bodyPositionY[headPosition] + 1) == 15 || bodyMap[bodyPositionY[headPosition] + 1][bodyPositionX[headPosition]];
        bodyPositionX[headPosition + 1] <= bodyPositionX[headPosition];
        bodyPositionY[headPosition + 1] <= bodyPositionY[headPosition] + 1;
      end

      //shift the head position and assign the new map to light
      headPosition <= headPosition + 1;
      bodyMap[bodyPositionY[headPosition]][bodyPositionX[headPosition]] <= 1;


      //if the head interconnects an apple then move the apple
      if (bodyPositionX[headPosition] == applePositionX && bodyPositionY[headPosition] == applePositionY) begin
        applePositionX <= (applePositionX + randomNumber[3:0]);// == 0 ? randomNumber[3:0] : (applePositionX + randomNumber[3:0]) == 15 ? randomNumber[3:0] : applePositionX + randomNumber[3:0];
        applePositionY <= (applePositionY + randomNumber[4:1]);// == 0 ? randomNumber[4:1] : (applePositionY + randomNumber[4:1]) == 15 ? randomNumber[4:1] : applePositionY + randomNumber[4:1];
        size = size + 1; //size for win conditions
        end
      else begin
        //if the head doesn't connect then move the tail
        bodyMap[bodyPositionY[tailPosition]][bodyPositionX[tailPosition]] <= 0;
        tailPosition <= tailPosition + 1;
      end

      //////////////////////////////////////////////////////////////////
      //section for game ending situations
      //////////////////////////////////////////////////////////////////

      //wall collision -- player runs into a wall
      if (bodyPositionX[headPosition] == 0 || bodyPositionX[headPosition] == 15 || bodyPositionY[headPosition] == 0 || bodyPositionY[headPosition] == 14) begin
        game_over <= 1'b1;
      end

      //player collison conditions -- play collides with self
      //when player is moving right and runs into tail/body
      if ((move_direction == 0) && (bodyMap[bodyPositionY[headPosition]][bodyPositionX[headPosition] - 1])) begin
          game_over <= 1'b1;
      end

      //when player is moving up and runs into tail/body
      if ((move_direction == 1) && (bodyMap[bodyPositionY[headPosition] - 1][bodyPositionX[headPosition]])) begin
          game_over <= 1'b1;
      end

      //when player is moving right and runs into tail/body
      if ((move_direction == 2) && (bodyMap[bodyPositionY[headPosition]][bodyPositionX[headPosition] + 1])) begin
          game_over <= 1'b1;
      end

      //when player is moving down and runs into tail/body
      if ((move_direction == 3) && (bodyMap[bodyPositionY[headPosition] + 1][bodyPositionX[headPosition]])) begin
          game_over <= 1'b1;
      end

      //win condition -- play has reached max snake length
      if (size == 15) begin
        game_win <= 1'b1;
      end

      //////////////////////////////////////////////////////////////////
      //section for apple mechanics
      //////////////////////////////////////////////////////////////////

      //if apple spawns into outside of game boundaries -- respawn the apple
      if (applePositionX > 14 || applePositionX < 1 || applePositionY > 13 || applePositionY < 1) begin
        applePositionX <= (applePositionX + randomNumber[3:0]);
        applePositionY <= (applePositionY + randomNumber[4:1]);
      end

      //if apple spawns into the player -- respawn apple_gfx
      // if (applePositionX == bodyMap[bodyPositionX[headPosition]][bodyPositionX[tailPosition]] || applePositionY == bodyMap[bodyPositionY[headPosition]][bodyPositionY[tailPosition]]) begin
      //   applePositionX <= (applePositionX + randomNumber[3:0]);
      // end

    end//end not reset
  end//end counter
end//end always

integer randomNumber;
always @(posedge clk_25) begin
  randomNumber <= randomNumber + 1;
end

//////////////////////////////////////////////////////////////////
//section for graphical output
//////////////////////////////////////////////////////////////////

//where the counter X and Y positions line up for chunks of 32 pixels
//output the apple if the position lines up
wire apple_gfx = counterX[8:5] == applePositionX && counterY[8:5] == applePositionY;
//output the border if it is on the sides of the screen
wire border_gfx = (counterX[8:5] == 0) || (counterX[8:5] == 15) || (counterY[8:5] == 0) || (counterY[8:5] == 14);
//output the snake if the bodymap indicates there is a body part there
wire snake_gfx = bodyMap[counterY[8:5]][counterX[8:5]];

//mapping for colors of the output to show
wire R = (game_over || apple_gfx) && ~game_win;
wire G = (snake_gfx || game_win) && ~game_over;
wire B =  border_gfx && ~game_over && ~game_win;

//registers (also the outputs) of the vga to change with the clock
reg vga_R, vga_G, vga_B;

//every VGA clock cycle needs to show the output if it is within the VGA screen area
always @(posedge clk_25) begin
	vga_R <= R & inDisplayArea;
	vga_G <= G & inDisplayArea;
	vga_B <= B & inDisplayArea;
  end
endmodule
