// Takes 2 clock cycles to propagate a write
module fifo #(parameter DEPTH=16, WIDTH=8) (
	input clk,
	input w_en,
	input advance_read_ptr,
	input [WIDTH-1:0] data_in,
	output reg [WIDTH-1:0] data_out,
	output full,
	output empty
);

reg [$clog2(DEPTH)-1:0] w_ptr = 0;
reg [$clog2(DEPTH)-1:0] r_ptr = 0;
reg [WIDTH-1:0] fifo_r[DEPTH-1:0];

/*
wire [WIDTH-1:0] dbg_current_r = fifo_r[r_ptr];
wire [WIDTH-1:0] dbg_current_w = fifo_r[w_ptr-1];
wire [WIDTH-1:0] dbg_zero = fifo_r[0];
wire [WIDTH-1:0] dbg_one = fifo_r[1];
*/

assign full = ({1'b0, w_ptr} == DEPTH-1);
assign empty = (r_ptr == w_ptr);

always @(posedge clk) begin
	if(empty && w_ptr != 0) begin
		w_ptr <= 0;
		r_ptr <= 0;
		fifo_r[0] <= 0;
	end else begin
		// data_out is constantly updated as an optimization;
		// the value can be read immediately
		data_out <= fifo_r[r_ptr];
		if (advance_read_ptr && !empty) begin
			r_ptr <= r_ptr + 1;
		end

		if (w_en && !full) begin
			fifo_r[w_ptr] <= data_in;
			w_ptr <= w_ptr + 1;
		end
	end
end

endmodule
