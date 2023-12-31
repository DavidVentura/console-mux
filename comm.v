module comm #(parameter CLOCK_PER_BIT = 16, parameter OUTPUT_COUNT = 16, parameter INPUT_COUNT = 4)(
	input clk,
	input rx_serial_line,
	output tx_serial_line,
	output [OUTPUT_COUNT-1:0] out_pins,
	input [INPUT_COUNT-1:0] in_pins
);

reg  tx_data_ready = 0;
wire tx_done;
wire  [7:0] tx_data;
reg   [7:0] tx_data_r = 8'b11111111;

wire rx_ready;
reg rx_ready_delay = 0;

wire [7:0] rx_data;
reg  [7:0] rx_data_r;

// Customizable widths
parameter sel_width = $clog2(INPUT_COUNT)*OUTPUT_COUNT;

// selectors and enabled_out must be multiples of 8 bit, so they can be transferred
wire [sel_width-1:0] selectors;
reg  [sel_width-1:0] selectors_r = 0;
//reg  [sel_width-1:0] selectors_buf = 0;
reg  [OUTPUT_COUNT-1:0] enabled_out_r = 0;
//reg  [OUTPUT_COUNT-1:0] enabled_out_buf = 0;
wire [OUTPUT_COUNT-1:0] enabled_out;

uart_tx #(.CLK_PER_BIT(CLOCK_PER_BIT)) 		  tx(clk, tx_data, tx_data_ready, tx_done, tx_serial_line);
uart_rx #(.CLK_PER_BIT(CLOCK_PER_BIT)) 		  rx(clk, rx_serial_line, rx_ready, rx_data);
mux 	#(.INPUT_COUNT(INPUT_COUNT), .OUTPUT_COUNT(OUTPUT_COUNT)) m1(in_pins, selectors, enabled_out, out_pins);

reg f_w_en = 0;
reg f_adv_r = 0;
reg [7:0] f_data_in = 0;
wire [7:0] f_data_out;
/* verilator lint_off UNUSEDSIGNAL */
wire f_full;
/* verilator lint_on UNUSEDSIGNAL */
wire f_data_avail;
wire f_rst;
reg f_rst_r = 1;
assign f_rst = f_rst_r;
fifo f(clk, f_w_en, f_adv_r, f_rst, f_data_in, f_data_out, f_full, f_data_avail);

localparam PIN_MAP_SIZE = sel_width/8; //bitfield->bytes
localparam OUT_PIN_ENABLE_SIZE = OUTPUT_COUNT/8; //bitfield->bytes


localparam COMM_INVALID 		 	= 3'b000;
localparam COMM_READ_ENABLE_MASK 	= 3'b001;
localparam COMM_READ_PIN_MAP 	 	= 3'b010;
localparam COMM_WRITE_ENABLE_MASK 	= 3'b011;
localparam COMM_WRITE_PIN_MAP 	 	= 3'b100;

localparam SM_IDLE 							= 4'b0000;
localparam SM_OUTPUT_READ_ENABLE_MASK 		= 4'b0001;
localparam SM_OUTPUT_READ_PIN_MAP 			= 4'b0010;
localparam SM_OUTPUT_WRITE_ENABLE_MASK 		= 4'b0011;
localparam SM_OUTPUT_WRITE_PIN_MAP 			= 4'b0100;
localparam SM_CLEANUP 						= 4'b0101;

// COMM state
reg [3:0] rx_byte_counter = 0;
reg [3:0] tx_byte_counter = 0;
reg [3:0] state = SM_CLEANUP;
reg rx_cmd_avail;

assign selectors = selectors_r;
assign enabled_out = enabled_out_r;
assign tx_data = tx_data_r;

always @(posedge clk) begin
	if(tx_data_ready == 1'b1) tx_data_ready <= 0;
	if(f_adv_r == 1'b1) f_adv_r <= 0;
	if(f_rst_r == 1'b1) f_rst_r <= 0;
	rx_ready_delay <= rx_ready;

	if(rx_ready && !rx_ready_delay) begin // edge
		rx_data_r <= rx_data;
		rx_byte_counter <= rx_byte_counter + 1;
		rx_cmd_avail <= 1;
	end
end

always @(posedge clk) begin
	if(f_data_avail && !tx_data_ready && tx_done) begin
		f_adv_r <= 1;
		tx_data_r <= f_data_out;
		tx_data_ready <= 1;
	end
end

always @(posedge clk) begin
	case (state)
		SM_IDLE: begin
			begin
				if(rx_cmd_avail) begin
					case (rx_data_r)
						{5'b00000, COMM_INVALID}: begin
						end
						{5'b00000, COMM_READ_ENABLE_MASK}: begin
							state <= SM_OUTPUT_READ_ENABLE_MASK;
						end
						{5'b00000, COMM_READ_PIN_MAP}: begin
							state <= SM_OUTPUT_READ_PIN_MAP;
						end
						{5'b00000, COMM_WRITE_ENABLE_MASK}: begin
							state <= SM_OUTPUT_WRITE_ENABLE_MASK;
						end
						{5'b00000, COMM_WRITE_PIN_MAP}: begin
							state <= SM_OUTPUT_WRITE_PIN_MAP;
						end
						default: begin
							//$display("Got bad IDLE command?: %b", rx_data_r);
							//TODO signal error?
						end
					endcase
					rx_cmd_avail <= 0;
					rx_byte_counter <= 0;
					tx_byte_counter <= 0;
					rx_data_r <= 0;
				end
			end
		end
		SM_OUTPUT_READ_ENABLE_MASK: begin
			if (tx_byte_counter<OUT_PIN_ENABLE_SIZE[3:0]) begin
				f_w_en <= 1;
				f_data_in <= enabled_out_r[(8*tx_byte_counter)+:8];
				tx_byte_counter <= tx_byte_counter + 1;
			end else begin
				f_w_en <= 0;
				f_data_in <= 0;
				state <= SM_CLEANUP;
			end
		end
		SM_OUTPUT_READ_PIN_MAP: begin
			if (tx_byte_counter<PIN_MAP_SIZE[3:0]) begin
				f_w_en <= 1;
				f_data_in <= selectors_r[(8*tx_byte_counter)+:8];
				tx_byte_counter <= tx_byte_counter + 1;
			end else begin
				f_w_en <= 0;
				f_data_in <= 0;
				state <= SM_CLEANUP;
			end
		end
		SM_OUTPUT_WRITE_ENABLE_MASK: begin
			enabled_out_r[(8*(rx_byte_counter-1))+:8] <= rx_data_r;
			if (rx_byte_counter == OUT_PIN_ENABLE_SIZE[3:0]) begin
				state <= SM_OUTPUT_READ_ENABLE_MASK;
				rx_byte_counter <= 0;
			end
		end
		SM_OUTPUT_WRITE_PIN_MAP: begin
			selectors_r[(8*(rx_byte_counter-1))+:8] <= rx_data_r;
			if (rx_byte_counter == PIN_MAP_SIZE[3:0]) begin
				state <= SM_OUTPUT_READ_PIN_MAP;
				rx_byte_counter <= 0;
				// This can move to the READ state
			end
		end
		SM_CLEANUP: begin
			// Clear the received command, so that SM_IDLE
			// doesn't need to deal with the leftovers of the data (not
			// commands!) in the register
			// Also finish the transmission
			rx_data_r <= {5'b00000, COMM_INVALID};
			if(!f_data_avail) begin
				f_rst_r <= 1;
				state <= SM_IDLE;
			end
		end
		default: begin
			state <= SM_CLEANUP;
		end
	endcase
end
endmodule
