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
reg [$clog2(DATA_BIT_COUNT)-1:0] current_bit = 0;

// Buffer / wire-to-r 
reg [DATA_BIT_COUNT-1:0] data_r;
reg done_r = 0;
reg serial_r = 0;

assign done = done_r;
assign serial = serial_r;

always @(posedge clk) begin
	case (state)
		SM_IDLE: begin
			if (data_ready == 1'b1) begin
				data_r <= data;
				done_r <= 0;
				state <= SM_TX_START;
				clock_count <= 0;
			end else begin
				done_r <= 1;
				serial_r <= 1'b1; // keep the line high to mark we are not transmitting
			end
		end
		SM_TX_START: begin
			serial_r <= 1'b0;
			if (clock_count < CLK_PER_BIT-1) begin
				clock_count <= clock_count + 1;
			end else begin
				state <= SM_TX_DATA;
				clock_count <= 0;
			end
		end
		SM_TX_DATA: begin
			serial_r <= data_r[current_bit];
			if (clock_count < CLK_PER_BIT-1) begin
				clock_count <= clock_count + 1;
			end else begin
				clock_count <= 0;
				if ({1'b0, current_bit} < (DATA_BIT_COUNT-1)) begin
					current_bit <= current_bit + 1;
				end else begin
					current_bit <= 0;
					if (PARITY_BIT_COUNT > 0) begin
						state <= SM_TX_PARITY;
					end else begin
						state <= SM_TX_STOP;
					end
				end
			end
		end
		SM_TX_PARITY: begin
			// TODO
			state <= SM_IDLE;
		end
		SM_TX_STOP: begin
			// Hold serial down for the entire cycle
			// then mark the transaction complete
			serial_r <= 1;
			if (clock_count < CLK_PER_BIT-1) begin
				clock_count <= clock_count + 1;
			end else begin
				clock_count <= 0;
				if (current_bit == (STOP_BIT_COUNT-1)) begin
					current_bit <= 0;
					done_r <= 1;
					state <= SM_IDLE;
				end else begin
					current_bit <= current_bit + 1;
				end
			end
		end
		default:
			state <= SM_IDLE;
	endcase
end

endmodule
