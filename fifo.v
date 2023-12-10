// Takes 2 clock cycles to propagate a write
module fifo #(parameter DEPTH=16, WIDTH=8) (
	input clk,
	input w_en,
	input advance_read_ptr,
	input rst,
	input [WIDTH-1:0] data_in,
	output reg [WIDTH-1:0] data_out,
	output full,
	output data_available
);

reg [$clog2(DEPTH)-1:0] w_ptr = 0;
reg [$clog2(DEPTH)-1:0] r_ptr = 0;
reg [WIDTH-1:0] fifo_r[DEPTH-1:0];
reg avail = 0;
wire empty = (r_ptr == w_ptr);

/* verilator lint_off UNUSEDSIGNAL */
wire [WIDTH-1:0] dbg_current_r = fifo_r[r_ptr];
wire [WIDTH-1:0] dbg_current_w = fifo_r[w_ptr-1];
wire [WIDTH-1:0] dbg_zero = fifo_r[0];
wire [WIDTH-1:0] dbg_one = fifo_r[1];
/* verilator lint_on UNUSEDSIGNAL */

assign full = ({1'b0, w_ptr} == DEPTH-1);
assign data_available = avail;
integer i;

always @(posedge clk) begin
	if(rst) begin
		w_ptr <= 0;
		r_ptr <= 0;
		for (i=0; i<DEPTH; i=i+1) begin
			fifo_r[i] <= 0;
		end
		avail <= 0;
	end else begin
		data_out <= fifo_r[r_ptr];
		avail <= advance_read_ptr ? (r_ptr + 1) < w_ptr : r_ptr < w_ptr;
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
