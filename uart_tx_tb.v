module uart_tx_tb;

reg clk = 0;
reg data_ready = 0;
wire done;
reg [7:0] data;
wire serial;
integer i;

always #1 clk <= !clk;

parameter CPB = 100;
uart_tx #(.CLK_PER_BIT(CPB)) tx(clk, data, data_ready, done, serial);

initial
begin
	$dumpfile("test.vcd");
	$dumpvars(0,uart_tx_tb);

	#100; 
	data_ready = 0;
	//data = 8'b01010101;
	//data = 8'b00000000;
	data = 8'b11111111;
	data_ready = 1;
	@(posedge clk);
	@(posedge clk);
	@(posedge clk);
	data_ready = 0;

	// start bit
	if(serial !== 0) begin
		$display("Error: start bit not found");
		$finish;
	end
	#(CPB*2);

	for(i=0; i<8; i=i+1) begin
		if(serial !== data[i]) begin
			$display("Error: bit %d mismatch, want %b got %b", i, data[i], serial);
		end
		#(CPB*2);
	end
	#(CPB*2); // stop bit
	#(CPB*2); // stop bit

	if (done != 1'b1) begin
		$display("Error: did not finish transmission");
	end
	$finish;
end

endmodule
