module test;

reg clk = 0;
wire serial_line;

reg tx_data_ready = 0;
wire tx_done;
reg [7:0] tx_data;

wire rx_ready;
wire [7:0] rx_data;

always #1 clk = !clk;

parameter CPB = 100;
uart_tx #(.CLK_PER_BIT(CPB)) tx(clk, tx_data, tx_data_ready, tx_done, serial_line);
uart_rx #(.CLK_PER_BIT(CPB)) rx(clk, serial_line, rx_ready, rx_data);

reg [7:0] test_data = 8'b01100011;

initial
begin
	$dumpfile("test.vcd");
	$dumpvars(0,test);
	tx_data_ready <= 0;
	tx_data <= test_data;
	tx_data_ready <= 1;
	#1;
	tx_data_ready <= 0;

	#(CPB*21);
	if (tx_done != 1'b1) begin
		$display("Error: did not finish transmission");
	end
	$finish;
end
always @(posedge rx_ready) begin
	$display("on rx_ready, tx_done was %d", tx_done);
	if (rx_data != tx_data) begin
		$display("Error: rx_data %h tx_data %h", rx_data, tx_data);
	end
end

endmodule
