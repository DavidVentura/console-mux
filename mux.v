// This module takes INPUT_COUNT `source` wires and `OUTPUT_COUNT` `out` wires,
// it will map the sources to the output based on the mapping given by 
// `selectors`.
module mux #(parameter INPUT_COUNT = 16, parameter OUTPUT_COUNT = 16)(
	input wire [INPUT_COUNT-1:0] sources,

	// A packed array, where each position indicates the index of the pin
	// to source from
	// Examples:
	// `selectors[0:3]   = 15`, then the PIN  0 will mirror the values seen at PIN 15
	// `selectors[4:7]   = 15`, then the PIN  1 will mirror the values seen at PIN 15
	// `selectors[56:59] = 15`, then the PIN 14 will mirror the values seen at PIN 15
	input wire [$clog2(INPUT_COUNT)*OUTPUT_COUNT-1:0] selectors,
	input wire [OUTPUT_COUNT-1:0] enabled_out,
	output wire [OUTPUT_COUNT-1:0] out
);

	localparam SEL_WIDTH = $clog2(INPUT_COUNT);

	genvar i;
	generate
		for (i=0; i<OUTPUT_COUNT; i=i+1) begin
			wire[$clog2(INPUT_COUNT)-1:0] source_for_i = selectors[(i+1)*SEL_WIDTH-1:i*SEL_WIDTH];
			assign out[i] = enabled_out[i] ? sources[source_for_i] : 1'bz;
		end
	endgenerate
endmodule
