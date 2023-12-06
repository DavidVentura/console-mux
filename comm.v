module comm #(parameter CLOCK_PER_BIT = 16, parameter OUTPUT_COUNT = 16)(
	input clk,
	input rx_serial_line,
	output tx_serial_line
);

reg  tx_data_ready;
wire tx_done;
wire  [7:0] tx_data;
reg   [7:0] tx_data_r = 8'b11111111;

wire rx_ready;
wire [7:0] rx_data;
reg  [7:0] rx_data_r;


wire [3:0] in_pins;
wire [31:0] selectors;
wire [15:0] enabled_out; // these must be multiples of 8 bit, so they can be transferred
reg  [15:0] enabled_out_r = 16'hAA55;
wire [15:0] out_pins;

uart_tx #(.CLK_PER_BIT(CLOCK_PER_BIT)) 		 tx(clk, tx_data, tx_data_ready, tx_done, tx_serial_line);
uart_rx #(.CLK_PER_BIT(CLOCK_PER_BIT)) 		 rx(clk, rx_serial_line, rx_ready, rx_data);
mux 	#(.INPUT_COUNT(4), .OUTPUT_COUNT(16)) m1(in_pins, selectors, enabled_out, out_pins);

reg [2:0] pending_tx_bytes;
reg [3:0] state = SM_IDLE;

localparam COMM_INVALID 		 	= 3'b000;
localparam COMM_READ_ENABLE_MASK 	= 3'b001;
localparam COMM_READ_PIN_MAP 	 	= 3'b010;
localparam COMM_WRITE_ENABLE_MASK 	= 3'b011;
localparam COMM_WRITE_PIN_MAP 	 	= 3'b100;

localparam SM_IDLE 							= 4'b0000;
localparam SM_OUTPUT_READ_ENABLE_MASK 		= 4'b0001;
localparam SM_OUTPUTTING_READ_ENABLE_MASK 	= 4'b0010;

assign enabled_out = enabled_out_r;
assign tx_data = tx_data_r;

always @(posedge rx_ready) begin
	rx_data_r <= rx_data;
end

always @(posedge clk) begin
	case (state)
		SM_IDLE: begin
			tx_data_ready <= 0; // FIXME
			case (rx_data_r)
				COMM_READ_ENABLE_MASK: begin
					state <= SM_OUTPUT_READ_ENABLE_MASK;
				end
			endcase
			rx_data_r <= COMM_INVALID;
		end
		SM_OUTPUT_READ_ENABLE_MASK: begin
			pending_tx_bytes <= 2;
			state <= SM_OUTPUTTING_READ_ENABLE_MASK;
		end
		SM_OUTPUTTING_READ_ENABLE_MASK: begin
			if (pending_tx_bytes == 0) begin
				state <= SM_IDLE;
			end else begin
				if (tx_done && !tx_data_ready) begin
					pending_tx_bytes <= pending_tx_bytes - 1;
					tx_data_r <= enabled_out_r[(pending_tx_bytes)*8-1-:8];
					tx_data_ready <= 1;
				end
				if (tx_done && tx_data_ready) begin
					tx_data_ready <= 0;
				end
			end
		end
	endcase
end
endmodule
