module test;

reg clk = 0;
reg serial_line = 1;
wire ready = 0;
wire [7:0] data;

always #1 clk = !clk;

parameter CPB = 100;
uart_rx #(.CLK_PER_BIT(CPB)) rx(clk, serial_line, ready, data);

integer i;
integer k;

//$monitor("clock count %d", clock_count);
initial
begin
	//$dumpfile("test.vcd");
	//$dumpvars(0,test);

	for(k=0; k<256; k=k+1) begin

		serial_line <= 0; // start bit
		#(CPB*2);
		for(i=0; i<8; i=i+1) begin
			serial_line <= k[i];
			#(CPB*2);
		end

		serial_line <= 1'b1; // stop bit
		#(CPB*3);

		if (ready != 1'b1) begin
			$display("Error: byte was not ready");
		end
		if (data != k) begin
			$display("Error: k was %b data was %b", k, data);
		end
	end
	$finish;
end

endmodule
