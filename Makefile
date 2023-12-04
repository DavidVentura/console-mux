uart_rx: uart_rx.v uart_rx_tb.v Makefile
	iverilog -o uart_rx uart_rx.v uart_rx_tb.v && ./uart_rx

test: mux.v mux_tb.v Makefile
	iverilog -o my_design mux.v mux_tb.v && ./my_design
