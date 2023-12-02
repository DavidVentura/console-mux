module mux(
	input wire clk,
	input wire [0:3] sources, // all _source_ pins
	input wire [0:3] sel, // selected pin,
	output out
);

	assign out = sources[sel];
endmodule
