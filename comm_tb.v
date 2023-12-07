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

	reg [3:0] received_counter = 0;

	reg [31:0] buffer = 0;
	reg garbage;

	reg [3:0] wanted_bytes = 0;


	task tc1(input [31:0] expected);
		#1;
	endtask

	initial begin
		$dumpfile("test.vcd");
		$dumpvars(0,test);

		//tx_data <= c.COMM_READ_ENABLE_MASK;
		wanted_bytes <= 3;
		tx_data <= c.COMM_READ_PIN_MAP;
		tx_data_ready <= 1;
		#3;
		tx_data_ready = 0;

	end

	always @(posedge rx_ready) begin
		received_counter <= received_counter + 1;
		buffer[((received_counter)*8)+:8] = rx_data;
		if (received_counter == wanted_bytes) begin
			garbage <= compare_buffers(32'haabbccdd, buffer);
			#10 $finish;
		end
	end

	function compare_buffers(input [31:0] expected, got);
		begin
			if (expected != got) begin
				$display("Error: expected %h got %h", expected, got);
			end
			if (^got === 1'bX) begin
				$display("Error: Got Unknown %h wanted: %h", got, expected);
				for(integer i=0; i<32; i++) begin
					if(got[i]===1'bX) $display("buffer[%0d] is X",i);
					if(got[i]===1'bZ) $display("buffer[%0d] is Z",i);
				end
			end
		end
	endfunction
endmodule
