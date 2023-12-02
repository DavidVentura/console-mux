module test;
	reg clk = 0;
	reg [0:3] counter = 0;
	reg [0:3] sel = 0;

	reg a;
	reg b;
	reg c;
	reg d;
	wire out;
	wire [0:3] gpios = {a,b,c,d};

	always #1 begin
		clk = !clk;
		counter = (counter+1) % 16;
		d = (counter & 4'b0001) == 4'b0001;
		c = (counter & 4'b0010) == 4'b0010;
		b = (counter & 4'b0100) == 4'b0100;
		a = (counter & 4'b1000) == 4'b1000;
	end

	//assign a = 1;
	//assign gpios = 4'b1010;

	initial $monitor("%d, gpios %b, sel %d, out %d", $time, gpios, sel, out);
	initial begin
		#1 sel = 0;
		#1 sel = 1;
		#1 sel = 2;
		#1 sel = 3;
		#1 sel = 0;
		#1 sel = 3;
		#1 sel = 0;


		#10 $finish;
	end

	mux m1 (clk, gpios, sel, out);

endmodule
