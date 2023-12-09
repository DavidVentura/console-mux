module mux_tb;
	reg clk = 0;

	reg  [7:0] selectors = 8'hff;
	wire [3:0] out;
	wire [3:0] enabled_out;
	reg  [3:0] enabled_out_r = 0;

	/*
	* Debugging
	wire [1:0] sel_0 = selectors[1:0];
	wire [1:0] sel_1 = selectors[3:2];
	wire [1:0] sel_2 = selectors[5:4];
	wire [1:0] sel_3 = selectors[7:6];
	*/

	reg a = 0;
	reg b = 0;
	reg c = 0;
	reg d = 0;
	wire [3:0] gpios = {d,c,b,a};

	// Counter and a-d are used to generate test input values
	reg  [3:0] counter = 0;

	mux #( .INPUT_COUNT(4), .OUTPUT_COUNT(4) ) m1 (gpios, selectors, enabled_out, out);

	always #1 begin
		clk <= !clk;
		if (counter == 15) begin
			counter <= 0;
		end else counter <= (counter+1);

		d <= (counter & 4'b0001) == 4'b0001;
		c <= (counter & 4'b0010) == 4'b0010;
		b <= (counter & 4'b0100) == 4'b0100;
		a <= (counter & 4'b1000) == 4'b1000;
	end

	assign enabled_out = enabled_out_r;

	integer i;
	initial begin
		// Enable pins 0 and 1
		enabled_out_r =  4'b0011;
		#1; // Why does enable take 1 clk to propagate??
		if (out[0] === 1'bz) begin
			$display("Expected bit 0 to be defined");
		end
		if (out[1] === 1'bz) begin
			$display("Expected bit 1 to be defined");
		end
		if (out[2] !== 1'bz) begin
			$display("Expected bit 2 to be undefined: %b", out[3]);
		end
		if (out[3] !== 1'bz) begin
			$display("Expected bit 3 to be undefined: %b", out[3]);
		end


		// Pin 0 reads A
		selectors[1:0] = 0;
		for(i=0; i<16; i=i+1) begin
			if (out[0] !== a) begin
				$display("Expected bit 0 (%b) to be equal to A (%b)", out[0], a);
			end
			#1;
		end

		// Pin 0 reads B
		selectors[1:0] = 1;
		for(i=0; i<16; i=i+1) begin
			if (out[0] !== b) begin
				$display("Expected bit 0 (%b) to be equal to B (%b)", out[0], b);
			end
			#1;
		end

		// Pin 0 reads C
		selectors[1:0] = 2;
		for(i=0; i<16; i=i+1) begin
			if (out[0] !== c) begin
				$display("Expected bit 0 (%b) to be equal to C (%b)", out[0], c);
			end
		end

		// Disable pin 0
		enabled_out_r[0] = 0;
		#1;
		for(i=0; i<16; i=i+1) begin
			if (out[0] !== 1'bz) begin
				$display("Expected bit 0 (%b) to be z", out[0]);
			end
			#1;
		end

		// Pin 1 reads B
		selectors[3:2] = 1;
		#1;
		for(i=0; i<16; i=i+1) begin
			if (out[1] !== b) begin
				$display("Expected bit 0 (%b) to be equal to A (%b)", out[0], a);
			end
			#1;
		end

		#10 $finish;
	end

endmodule
