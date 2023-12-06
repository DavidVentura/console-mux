module test;
	reg clk = 0;
	always #1 clk = ~clk;
	localparam CLOCK_PER_BIT = 16;

	wire serial_tx;
	wire serial_rx;
	comm c(clk, serial_rx, serial_tx);

	reg[7:0] tx_data;
	reg tx_data_ready;
	wire tx_done;
	uart_tx #(.CLK_PER_BIT(CLOCK_PER_BIT)) test_tx(clk, tx_data, tx_data_ready, tx_done, serial_rx);

	wire rx_ready;
	wire[7:0] rx_data;
	uart_rx #(.CLK_PER_BIT(CLOCK_PER_BIT)) test_rx(clk, serial_tx, rx_ready, rx_data);

	initial begin
		$dumpfile("test.vcd");
		$dumpvars(0,test);

		tx_data <= 1; //COMM_READ_ENABLE_MASK;
		#1;
		tx_data_ready <= 1;
		#2;
		tx_data_ready <= 0;
		#1000;
		$finish;
	end
endmodule
