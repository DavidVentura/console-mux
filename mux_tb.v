module test;
	reg clk = 0;

	reg [0:7] selectors;
	wire [0:3] out;

	wire [0:3] gpios = {a,b,c,d};

	// Counter and a-d are used to generate test input values
	reg [0:3] counter = 0;
	reg a;
	reg b;
	reg c;
	reg d;

	always #1 begin
		clk = !clk;
		counter = (counter+1) % 16;
		d = (counter & 4'b0001) == 4'b0001;
		c = (counter & 4'b0010) == 4'b0010;
		b = (counter & 4'b0100) == 4'b0100;
		a = (counter & 4'b1000) == 4'b1000;
	end

	initial $monitor("%d, gpios %b, sel0 %d, sel1 %d, out0 %d, out1 %d", $time, gpios, selectors[0:3], selectors[4:7], out[0], out[1]);
	initial begin
		#1 selectors[4:7] = 1;

		#1 selectors[0:3] = 0;
		#1 selectors[0:3] = 1;
		#1 selectors[0:3] = 2;
		#1 selectors[0:3] = 3;
		#1 selectors[0:3] = 0;
		#1 selectors[0:3] = 3;
		#1 selectors[0:3] = 0;


		#10 $finish;
	end

	mux #( .INPUT_COUNT(4), .OUTPUT_COUNT(4) ) m1 (clk, gpios, selectors, out);


initial
begin
   $dumpfile("test.vcd");
   $dumpvars(0,test);
end
endmodule
