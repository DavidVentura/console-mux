module comm_tb;
	reg clk = 0;
	always #1 clk <= ~clk;
	localparam CLOCK_PER_BIT = 16;

	wire serial_tx;
	wire serial_rx;
	wire [15:0] output_pins;
	wire [3:0] input_pins;
	reg [3:0] input_pins_r;
	assign input_pins = input_pins_r;
	comm c(clk, serial_rx, serial_tx, output_pins, input_pins);

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

	function compare_buffers(input [31:0] _expected, got);
		begin
			if (^got === 1'bX) begin
				$display("Error: Got Unknown %h wanted: %h", got, _expected);
				for(i=0; i<32; i=i+1) begin
					if(got[i]===1'bX) $display("buffer[%0d] is X",i);
					if(got[i]===1'bZ) $display("buffer[%0d] is Z",i);
				end
				$finish;
			end
			if (_expected != got) begin
				$display("Error: expected %h got %h", _expected, got);
				$finish;
			end
		end
	endfunction

	task send_byte(input[7:0] xbyte);
		begin
			tx_data = xbyte;
			tx_data_ready = 1;
			#3;
			tx_data_ready = 0;
			wait (tx_done == 1);
		end
	endtask

	task run_command(input[3:0] _bytes, input[2:0] command, input [31:0] _expected);
		begin
			buffer = 0;
			received_counter = 0;
			wanted_bytes = _bytes;
			expected = _expected;

			send_byte(command);

			wait (tc_done == 1);
			#1;
			tc_done = 0;
			#5;
		end
	endtask

	task run_command_with_payload(input[3:0] _bytes, input[2:0] command, input[2:0] bytes_to_send, input[31:0] payload, input [31:0] _expected);
		begin
			buffer = 0;
			received_counter = 0;
			wanted_bytes = _bytes;
			expected = _expected;

			send_byte(command);
			for(i=0; i<bytes_to_send; i=i+1) begin
				send_byte(payload[i*8+:8]);
			end

			wait (tc_done == 1);
			#1;
			tc_done = 0;
			#5;
		end
	endtask

	initial begin
		$dumpfile("test.vcd");
		$dumpvars(0,comm_tb);
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
		// Integration test
		// 4 input pins
		// 16 output pins
		// Each output picks it source:
		// |O0|O1|O2|..|OF|Notes|
		// |--|--|--|--|--|-----|
		// |00|00|00|..|00|All 16 outputs source pin 0|
		// |01|00|00|..|00|Output 0 sources input pin 1|
		//
		// So, map all pins to 0
		run_command_with_payload(3, c.COMM_WRITE_PIN_MAP, 4, 32'h00000000, 32'h00000000);
		// Set input pin 0 to 0
		input_pins_r = 0;
		// Disable output on all of them
		run_command_with_payload(1, c.COMM_WRITE_ENABLE_MASK, 2, 16'h0000, 16'h0000);
		for(i=0; i<15; i=i+1) begin
			if (output_pins[i] !== 1'bz) $display("Pin %d, expected z, got %d", i, output_pins[i]);
		end
		// Enable output on all of them
		run_command_with_payload(1, c.COMM_WRITE_ENABLE_MASK, 2, 16'hFFFF, 16'hFFFF);
		for(i=0; i<15; i=i+1) begin
			if (output_pins[i] !== 1'b0) $display("Pin %d, expected 0, got %d", i, output_pins[i]);
		end
		// Change pin 0 to 1, all should now be 1
		input_pins_r[0] = 1;
		#1; // why does this need a delay??
		for(i=0; i<15; i=i+1) begin
			if (output_pins[i] !== 1'b1) $display("Pin %d, expected 1, got %d", i, output_pins[i]);
		end
		// Change pin mapping: pin 0 sources input pin 1, which is still 0
		run_command_with_payload(3, c.COMM_WRITE_PIN_MAP, 4, 32'h00000001, 32'h00000001);
		#1; // why does this need a delay??
		if (output_pins[0] !== 1'b0) $display("Pin %d, expected 0, got %d", 0, output_pins[0]);
		for(i=1; i<15; i=i+1) begin
			if (output_pins[i] !== 1'b1) $display("Pin %d, expected 1, got %d", i, output_pins[i]);
		end
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

endmodule
