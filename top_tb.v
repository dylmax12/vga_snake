module top_tb;
reg btn1, btn2, btn3, btn4, reset;
wire[1:0] move_direction;

// instantiate device under test
snake dut (.btn1(btn1), .btn2(btn2), .btn3(btn3), .btn4(btn4), .reset(reset), .move_direction(move_direction));

// apply inputs one at a time
initial begin
$dumpfile("top_tb.vcd"); $dumpvars;
btn1 = 0; btn2 = 1; btn3 = 1; btn4 = 1; reset = 1; #100; //left, move direct = 0
btn1 = 1; btn2 = 0; btn3 = 1; btn4 = 1; reset = 1; #100; //up, move direct = 1
btn1 = 1; btn2 = 1; btn3 = 0; btn4 = 1; reset = 1; #100; //right, move direct = 2
btn1 = 1; btn2 = 1; btn3 = 1; btn4 = 0; reset = 1; #100; //down, move direct = 3
btn1 = 1; btn2 = 1; btn3 = 1; btn4 = 0; reset = 0; #100; //reset, move direct = 2
end
endmodule
