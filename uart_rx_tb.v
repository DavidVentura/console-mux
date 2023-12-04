module test;

reg clk = 0;
reg serial_line = 1;
wire ready = 0;
wire [7:0] data;

reg [7:0] fake_data = 8'b11100001;

always #1 clk = !clk;

parameter CPB = 100;
uart_rx #(.CLK_PER_BIT(CPB)) rx(clk, serial_line, ready, data);

integer i;

//$monitor("clock count %d", clock_count);
initial
begin
	$dumpfile("test.vcd");
	$dumpvars(0,test);

	serial_line <= 0; // start bit
	#(CPB*2);
	for(i=0; i<8; i=i+1) begin
		serial_line <= fake_data[i];
		#(CPB*2);
	end

	serial_line <= 1'b1; // stop bit
	#(CPB*2);

	if (ready != 1'b1) begin
		$display("Error: byte was not ready");
	end
	if (data != fake_data) begin
		$display("Error: data was bad");
	end
	$display("Fake data was %b data was %b", fake_data, data);
	$finish;
end
endmodule
