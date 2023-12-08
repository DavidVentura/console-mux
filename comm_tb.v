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
	reg [31:0] expected = 0;
	reg garbage;

	reg [3:0] wanted_bytes = 0;

	reg tc_done = 0;

	integer i;

	task send_byte(input[7:0] byte);
		begin
			tx_data <= byte;
			tx_data_ready <= 1;
			#3;
			tx_data_ready = 0;
			wait (tx_done == 1);
		end
	endtask

	task run_command(input[3:0] _bytes, input[3:0] command, input [31:0] _expected);
		begin
			buffer <= 0;
			received_counter <= 0;
			wanted_bytes <= _bytes;
			expected <= _expected;

			send_byte(command);

			wait (tc_done == 1);
			#1;
			tc_done <= 0;
			#5;
		end
	endtask

	task run_command_with_payload(input[3:0] _bytes, input[3:0] command, input[2:0] bytes_to_send, input[31:0] payload, input [31:0] _expected);
		begin
			buffer <= 0;
			received_counter <= 0;
			wanted_bytes <= _bytes;
			expected <= _expected;

			send_byte(command);
			for(i=0; i<bytes_to_send; i++) begin
				send_byte(payload[i*8+:8]);
			end

			wait (tc_done == 1);
			#1;
			tc_done <= 0;
			#5;
		end
	endtask

	initial begin
		$dumpfile("test.vcd");
		$dumpvars(0,test);
		run_command(3, c.COMM_READ_PIN_MAP, 0);
		run_command(3, c.COMM_READ_PIN_MAP, 0); // can run it twice
		run_command(1, c.COMM_READ_ENABLE_MASK, 0);
		run_command(1, c.COMM_READ_ENABLE_MASK, 0);

		run_command_with_payload(1, c.COMM_WRITE_ENABLE_MASK, 2, 32'habcd, 32'habcd);
		run_command(1, c.COMM_READ_ENABLE_MASK, 32'habcd);
		run_command(1, c.COMM_READ_ENABLE_MASK, 32'habcd);

		run_command_with_payload(1, c.COMM_WRITE_ENABLE_MASK, 2, 32'haaaa, 32'haaaa);
		run_command(1, c.COMM_READ_ENABLE_MASK, 32'haaaa);
		run_command(1, c.COMM_READ_ENABLE_MASK, 32'haaaa);

		run_command_with_payload(3, c.COMM_WRITE_PIN_MAP, 4, 32'h89abcdef, 32'h89abcdef);
		run_command(3, c.COMM_READ_PIN_MAP, 32'h89abcdef);
		run_command(3, c.COMM_READ_PIN_MAP, 32'h89abcdef);

		run_command_with_payload(3, c.COMM_WRITE_PIN_MAP, 4, 32'haaff5500, 32'haaff5500);
		run_command(3, c.COMM_READ_PIN_MAP, 32'haaff5500);
		run_command(3, c.COMM_READ_PIN_MAP, 32'haaff5500);
		#10 $finish;

	end

	always @(posedge rx_ready) begin
		received_counter <= received_counter + 1;
		buffer[((received_counter)*8)+:8] = rx_data;
		if (received_counter == wanted_bytes) begin
			// need to assign to something
			garbage <= compare_buffers(expected, buffer);
			tc_done <= 1;
		end
	end

	function compare_buffers(input [31:0] expected, got);
		begin
			if (^got === 1'bX) begin
				$display("Error: Got Unknown %h wanted: %h", got, expected);
				for(integer i=0; i<32; i++) begin
					if(got[i]===1'bX) $display("buffer[%0d] is X",i);
					if(got[i]===1'bZ) $display("buffer[%0d] is Z",i);
				end
				$finish;
			end
			if (expected != got) begin
				$display("Error: expected %h got %h", expected, got);
				$finish;
			end
		end
	endfunction
endmodule
