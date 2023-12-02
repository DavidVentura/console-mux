module test;
	reg clk = 0;

	// There are 16 selectors; each selector marks the source pin for a given
	// pin.
	// If `selectors[0] = 15`, then the PIN 0 will mirror the values seen at PIN 15
	reg [0:3] selectors [0:15];

	// There are 16 output pins, which get their value assigned
	// from the `selectors` mapping
	wire [0:15] out;

	// There are "4" (16..) input pins, which are used to source
	// values for `out`
	wire [0:3] gpios = {a,b,c,d};

	// This is an N to M (#gpios to #out) mux, where multiple output pins (M)
	// can source the same source (N) pin

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

	initial $monitor("%d, gpios %b, sel0 %d, sel1 %d, out0 %d, out1 %d", $time, gpios, selectors[0], selectors[1], out[0], out[1]);
	initial begin
		#1 selectors[1] = 1;

		#1 selectors[0] = 0;
		#1 selectors[0] = 1;
		#1 selectors[0] = 2;
		#1 selectors[0] = 3;
		#1 selectors[0] = 0;
		#1 selectors[0] = 3;
		#1 selectors[0] = 0;


		#10 $finish;
	end

	genvar i;
	generate
		for (i=0; i<16; i=i+1) begin
			mux m1 (clk, gpios, selectors[i], out[i]);
		end
	endgenerate


initial
begin
   $dumpfile("test.vcd");
   $dumpvars(0,test);
end
endmodule
