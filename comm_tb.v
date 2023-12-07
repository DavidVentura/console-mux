module test;
	reg clk = 0;
	always #1 clk = ~clk;
	localparam CLOCK_PER_BIT = 16;

	wire serial_tx;
	wire serial_rx;
	wire [15:0] enabled_out; // these must be multiples of 8 bit, so they can be transferred
	comm c(clk, serial_rx, serial_tx, enabled_out);

	reg[7:0] tx_data;
	reg tx_data_ready;
	wire tx_done;
	uart_tx #(.CLK_PER_BIT(CLOCK_PER_BIT)) test_tx(clk, tx_data, tx_data_ready, tx_done, serial_rx);

	wire rx_ready;
	wire[7:0] rx_data;
	uart_rx #(.CLK_PER_BIT(CLOCK_PER_BIT)) test_rx(clk, serial_tx, rx_ready, rx_data);

	reg [2:0] received_counter = 0;

	reg [15:0] buffer = 0;

	initial begin
		$dumpfile("test.vcd");
		$dumpvars(0,test);

		tx_data <= c.COMM_READ_ENABLE_MASK;
		tx_data_ready <= 1;
		#3;
		tx_data_ready = 0;

	end

	always @(posedge rx_ready) begin
		received_counter <= received_counter + 1;
		buffer[((received_counter)*8)+:8] = rx_data; // [(pending_tx_bytes)*8-1-:8]
		if (received_counter == 1) begin
			if (enabled_out != buffer) begin
				$display("Error: Mismatch in state and reply: %h %h", enabled_out, buffer);
			end
			if (^buffer === 1'bX) begin
				$display("Error: Unknown buffer value: %h %h", enabled_out, buffer);
				for(integer i=0; i<16; i++) begin
					if(buffer[i]===1'bX) $display("buffer[%0d] is X",i);
					if(buffer[i]===1'bZ) $display("buffer[%0d] is Z",i);
				end
			end
			#10 $finish;
		end
	end
endmodule
