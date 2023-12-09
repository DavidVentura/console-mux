module uart_tb;

reg clk = 0;
wire serial_line;

reg tx_data_ready = 0;
wire tx_done;
reg [7:0] tx_data;

wire rx_ready;
wire [7:0] rx_data;

always #1 clk <= !clk;

parameter CPB = 100;
uart_tx #(.CLK_PER_BIT(CPB)) tx(clk, tx_data, tx_data_ready, tx_done, serial_line);
uart_rx #(.CLK_PER_BIT(CPB)) rx(clk, serial_line, rx_ready, rx_data);

integer i;
initial
begin
	tx_data_ready = 0;
	for(i=0; i<256; i=i+1) begin
		tx_data = i[7:0];
		tx_data_ready = 1;
		@(posedge clk);
		@(posedge clk) tx_data_ready = 0;

		@(posedge rx_ready);
		@(posedge clk);
	end
	$finish;
end
always @(posedge rx_ready) begin
	if (tx_done != 1'b1) begin
		$display("Error: did not finish transmission");
		#1 $finish;
	end

	if (rx_data != tx_data) begin
		$display("Error: rx_data %h tx_data %h", rx_data, tx_data);
		#1 $finish;
	end
end

endmodule
