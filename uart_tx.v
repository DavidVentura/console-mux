// Defaults to 8N1
module uart_tx #(parameter DATA_BIT_COUNT=8, parameter PARITY_BIT_COUNT=0, parameter STOP_BIT_COUNT=1, parameter CLK_PER_BIT=8)
(
	input clk,
	input [DATA_BIT_COUNT-1:0] data,
	input data_ready,
	output done,
	output serial
);
/*
 * START BIT: Line is held high when idle. Pulled down for 1 clock cycle to
 * start data transfer.
 * DATA: 5 to 9 bits if no parity, up to 8 if parity
 * STOP BITS: 1-2 bits, line is pulled high.
 */

parameter SM_IDLE 			= 3'b000;
parameter SM_TX_START 		= 3'b001;
parameter SM_TX_DATA 		= 3'b010;
parameter SM_TX_PARITY 		= 3'b011;
parameter SM_TX_STOP 		= 3'b100;


// Internal state management
reg [$clog2(CLK_PER_BIT)+1:0] clock_count = 0;
reg [2:0] state = SM_IDLE;
reg [3:0] current_bit = 0; // counts data (up to 9) and stop bit (1-2)

// Buffer / wire-to-r 
reg [DATA_BIT_COUNT-1:0] data_r;
reg done_r = 0;
reg serial_r = 0;

assign done = done_r;
assign serial = serial_r;

always @(posedge clk) begin
	case (state)
		SM_IDLE: begin
			done_r <= 0;
			if (data_ready == 1'b1) begin
				data_r <= data;
				done_r <= 0;
				state <= SM_TX_START;
			end
		end
		SM_TX_START: begin
			serial_r <= 1'b0;
			if (clock_count < CLK_PER_BIT-1) begin
				clock_count <= clock_count + 1;
			end
			else begin
				state <= SM_TX_DATA;
			end
		end
		SM_TX_DATA: begin
			if (clock_count < CLK_PER_BIT-1) begin
				clock_count <= clock_count + 1;
			end
			else begin
				serial_r <= data_r[current_bit];
				clock_count <= 0;
				if (current_bit < DATA_BIT_COUNT-1) begin
					current_bit <= current_bit + 1;
				end
				else begin
					current_bit <= 0;
					if (PARITY_BIT_COUNT > 0) begin
						state <= SM_TX_PARITY;
					end
					else begin
						state <= SM_TX_STOP;
					end
				end
			end
		end
		SM_TX_PARITY: begin
			$finish;
		end
		SM_TX_STOP: begin
			serial_r <= 0;
			if (clock_count < CLK_PER_BIT-1) begin
				clock_count <= clock_count + 1;
			end
			else begin
				current_bit <= current_bit + 1;
				clock_count <= 0;
				if (current_bit == STOP_BIT_COUNT -1) begin
					done_r <= 1;
					state <= SM_IDLE;
				end
			end
			//$display("stoop");
		end
	endcase
end

endmodule
