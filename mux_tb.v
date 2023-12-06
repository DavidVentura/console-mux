module test;
	reg clk = 0;

	reg  [7:0] selectors;
	wire [3:0] out;
	wire [3:0] enabled_out;
	reg  [3:0] enabled_out_r;

	wire [3:0] gpios = {a,b,c,d};

	// Counter and a-d are used to generate test input values
	reg  [3:0] counter = 0;
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

	assign enabled_out = enabled_out_r;

	initial $monitor("%d, gpios %b, sel0 %d, sel1 %d, out0 %d, out1 %d", $time, gpios, selectors[3:0], selectors[7:4], out[0], out[1]);
	initial begin
		enabled_out_r =  4'b0011;
		#1 selectors[7:4] = 1;

		#1 selectors[3:0] = 0;
		#1 selectors[3:0] = 1;
		#1 selectors[3:0] = 2;
		enabled_out_r =  4'b0001;
		#1 selectors[3:0] = 3;
		#1 selectors[3:0] = 0;
		#1 selectors[3:0] = 3;
		#1 selectors[3:0] = 0;


		#10 $finish;
	end

	mux #( .INPUT_COUNT(4), .OUTPUT_COUNT(4) ) m1 (gpios, selectors, enabled_out, out);


initial
begin
   $dumpfile("test.vcd");
   $dumpvars(0,test);
end
endmodule
