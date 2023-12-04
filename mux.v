// This module takes INPUT_COUNT `source` wires and `OUTPUT_COUNT` `out` wires,
// it will map the sources to the output based on the mapping given by 
// `selectors`.
module mux #(parameter INPUT_COUNT = 16, parameter OUTPUT_COUNT = 16)(
	input wire clk,
	input wire [0:INPUT_COUNT-1] sources,

	// A packed array, where each position indicates the index of the pin
	// to source from
	// Examples:
	// `selectors[0:3]   = 15`, then the PIN  0 will mirror the values seen at PIN 15
	// `selectors[4:7]   = 15`, then the PIN  1 will mirror the values seen at PIN 15
	// `selectors[56:59] = 15`, then the PIN 14 will mirror the values seen at PIN 15
	input wire [0:$clog2(OUTPUT_COUNT)*OUTPUT_COUNT-1] selectors,
	output wire [0:OUTPUT_COUNT-1] out
);

	genvar i;
	generate
		for (i=0; i<OUTPUT_COUNT; i=i+1) begin
			wire source_for_i = selectors[i*4:(i+1)*4-1];
			assign out[i] = sources[source_for_i];
		end
	endgenerate
endmodule
