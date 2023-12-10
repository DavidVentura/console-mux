// Defaults to 8N1
module uart_rx #(parameter DATA_BIT_COUNT=8, parameter PARITY_BIT_COUNT=0, parameter STOP_BIT_COUNT=1, parameter CLK_PER_BIT=8)
(
	input clk,
	input serial,
	output ready,
	output [DATA_BIT_COUNT-1:0] data
);
/*
 * START BIT: Line is held high when idle. Pulled down for 1 clock cycle to
 * start data transfer.
 * DATA: 5 to 9 bits if no parity, up to 8 if parity
 * STOP BITS: 1-2 bits, line is pulled high.
 */

parameter SM_IDLE 			= 3'b000;
parameter SM_RX_START 		= 3'b001;
parameter SM_RX_DATA 		= 3'b010;
parameter SM_RX_PARITY 		= 3'b011;
parameter SM_RX_STOP 		= 3'b100;
parameter SM_ERROR 			= 3'b101;
parameter SM_CLEANUP 		= 3'b111;

// Need to over-sample the data line to read its value at the middle of the bit cycle
reg [$clog2(CLK_PER_BIT)+1:0] clock_count = 0;
reg [2:0] state = SM_IDLE;

reg r_ready;
reg [DATA_BIT_COUNT-1:0] r_data = 255;
reg [$clog2(DATA_BIT_COUNT)-1:0] current_bit = 0;

assign ready = r_ready;
assign data = r_data;

localparam HALF_CLK = (CLK_PER_BIT-1)/2;

always @(posedge clk) begin
	case (state)
		SM_IDLE: begin
			if (serial == 1'b0) begin
				// Pulling the line down for 1 cycle starts a data transfer
				clock_count <= 0;
				state <= SM_RX_START;
				current_bit <= 0;
				r_ready <= 0;
			end
		end
		SM_RX_START: begin
			// The line change might be noise, so we need to validate in half
			// a bit cycle whether it's still down
			if (clock_count == HALF_CLK) begin
				if (serial == 1'b0) begin
					// The line was held down for half a clock cycle, we will
					// now start receiving data
					current_bit <= 0;
					clock_count <= 0;
					state <= SM_RX_DATA;
				end else begin
					// The line was _not_ held down. Probably noise.
					// Restart the state machine
					state <= SM_IDLE;
				end
			end else begin
				clock_count <= clock_count + 1;
			end
		end
		SM_RX_DATA: begin
			// The `clock_count` got set to 0 at the half-bit cycle
			// By continuing to check every CLK_PER_BIT, we remain at the
			// middle of the bit cycle
			if (clock_count < CLK_PER_BIT-1) begin
				clock_count <= clock_count + 1;
			end else begin
				// At the middle of the data bit
				clock_count <= 0;
				r_data[current_bit] <= serial;
				if ({1'b0, current_bit} < (DATA_BIT_COUNT-1)) begin
					current_bit <= current_bit + 1;
				end else begin
					current_bit <= 0;
					if (PARITY_BIT_COUNT > 0) begin
						state <= SM_RX_PARITY;
					end else begin
						state <= SM_RX_STOP;
					end
				end
			end
		end
		SM_RX_PARITY: begin
			// TODO ))
			state <= SM_ERROR;
		end
		SM_RX_STOP: begin
			// Transition to STOP at the middle of a DATA bit
			// Wait 1 bit cycle to sample the STOP bit at the middle
			if (clock_count < CLK_PER_BIT-1) begin
				clock_count <= clock_count + 1;
			end else begin
				if (serial != 1'b1) begin
					// An RX line held to 0 will always land here
					state <= SM_ERROR;
				end else begin
					clock_count <= 0;
					if ({1'b0, current_bit} == (STOP_BIT_COUNT-1)) begin
						state <= SM_CLEANUP;
					end else begin
						current_bit <= current_bit + 1;
					end
				end
			end
		end
		SM_CLEANUP: begin
			// Wait half a cycle for the STOP bit to finish
			current_bit <= 0;
			if (clock_count < HALF_CLK) begin
				clock_count <= clock_count + 1;
			end else begin
				r_ready <= 1;
				clock_count <= 0;
				state <= SM_IDLE;
			end
		end
		SM_ERROR: begin
			current_bit <= 0;
			r_ready <= 0;
			clock_count <= 0;
			state <= SM_IDLE;
		end
		default: begin
			state <= SM_ERROR;
		end
	endcase
end
endmodule
