test:
	iverilog -o my_design mux.v mux_tb.v && ./my_design 
