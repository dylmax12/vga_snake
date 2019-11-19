//typical hvsync_generator found in VGA projects using FPGAs
//handles the syncing of the resolution of the monitor size with the drawing size
//also handles which RGB pixels to draw when within the display area

module hvsync_generator(clk, vga_h_sync, vga_v_sync, inDisplayArea, CounterX, CounterY);

//input clock of the frequency of drawing ofr the 640 x 480, 60 Hz screen
input clk;

//output syncs that handle the porches and blanking of a display
output vga_h_sync, vga_v_sync;

//a value to compute when the pixel drawn is within the monitor area
output inDisplayArea;

//a counter for which index/position is being drawn
output [9:0] CounterX;
output [8:0] CounterY;

//the counter is an internal register
reg [9:0] CounterX;
reg [8:0] CounterY;

wire CounterXmaxed = (CounterX == 10'h2FF);//767

always @(posedge clk)
if(CounterXmaxed)
	CounterX <= 0;
else
	CounterX <= CounterX + 1;

always @(posedge clk)
if(CounterXmaxed) CounterY <= CounterY + 1;

reg	vga_HS, vga_VS;
always @(posedge clk)
begin
	vga_HS <= (CounterX[9:4] == 6'h2D); //checks at 720 change this value to move the display horizontally
	vga_VS <= (CounterY == 500); // change this value to move the display vertically
end

reg inDisplayArea;
always @(posedge clk)
if(inDisplayArea==0)
	inDisplayArea <= (CounterXmaxed) && (CounterY<480);
else
	inDisplayArea <= !(CounterX==480);

assign vga_h_sync = ~vga_HS;
assign vga_v_sync = ~vga_VS;

endmodule
