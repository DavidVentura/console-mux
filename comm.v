module comm #(parameter CLOCK_PER_BIT = 16, parameter OUTPUT_COUNT = 16)(
	input clk,
	input rx_serial_line,
	output tx_serial_line,
	inout [15:0] enabled_out
);

reg  tx_data_ready = 0;
wire tx_done;
wire  [7:0] tx_data;
reg   [7:0] tx_data_r = 8'b11111111;

wire rx_ready;
wire [7:0] rx_data;
reg  [7:0] rx_data_r;


wire [3:0] in_pins;
wire [31:0] selectors;
//wire [15:0] enabled_out; // these must be multiples of 8 bit, so they can be transferred
reg  [15:0] enabled_out_r = 16'hAA55;
wire [15:0] out_pins;

uart_tx #(.CLK_PER_BIT(CLOCK_PER_BIT)) 		  tx(clk, tx_data, tx_data_ready, tx_done, tx_serial_line);
uart_rx #(.CLK_PER_BIT(CLOCK_PER_BIT)) 		  rx(clk, rx_serial_line, rx_ready, rx_data);
mux 	#(.INPUT_COUNT(4), .OUTPUT_COUNT(16)) m1(in_pins, selectors, enabled_out, out_pins);

reg f_w_en = 0;
reg f_r_en = 0;
reg [7:0] f_data_in = 0;
wire [7:0] f_data_out;
wire f_full;
wire f_empty;
fifo 										   f(clk, f_w_en, f_r_en, f_data_in, f_data_out, f_full, f_empty);


reg [3:0] state = SM_IDLE;

localparam COMM_INVALID 		 	= 3'b000;
localparam COMM_READ_ENABLE_MASK 	= 3'b001;
localparam COMM_READ_PIN_MAP 	 	= 3'b010;
localparam COMM_WRITE_ENABLE_MASK 	= 3'b011;
localparam COMM_WRITE_PIN_MAP 	 	= 3'b100;

localparam SM_IDLE 							= 4'b0000;
localparam SM_OUTPUT_READ_ENABLE_MASK 		= 4'b0001;

assign enabled_out = enabled_out_r;
assign tx_data = tx_data_r;

always @(posedge rx_ready) begin
	rx_data_r <= rx_data;
end

always @(posedge clk) begin
	if(tx_data_ready == 1'b1) tx_data_ready <= 0;
	if(f_r_en == 1'b1) f_r_en <= 0;
end

always @(posedge clk) begin
	if(!f_empty && !tx_data_ready && tx_done) begin
		// Empty is signalled when any data has been written, but
		// data_out always has the value from the last clock cycle
		// so we still need to wait 1 clock after !empty
		@(posedge clk) begin
			f_r_en <= 1;
			tx_data_r <= f_data_out;
			tx_data_ready <= 1;
		end
	end
end

always @(posedge clk) begin
	case (state)
		SM_IDLE: begin
			case (rx_data_r)
				COMM_READ_ENABLE_MASK: begin
					state <= SM_OUTPUT_READ_ENABLE_MASK;
				end
			endcase
			rx_data_r <= COMM_INVALID;
		end
		SM_OUTPUT_READ_ENABLE_MASK: begin
			state <= SM_IDLE;
			f_w_en <= 1;
			f_data_in <= enabled_out_r[7:0];
			@(posedge clk) f_data_in <= enabled_out_r[15:8];
			@(posedge clk) begin
				f_w_en <= 0;
				f_data_in <= 0;
			end
		end
	endcase
end
endmodule
