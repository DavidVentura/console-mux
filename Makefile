.PHONY: uart_tx
uart_tx_rx: uart_tx.v uart_rx.v uart_tb.v Makefile
	iverilog -o $@ $(filter %.v,$^) && ./$@
uart_tx: uart_tx.v uart_tx_tb.v Makefile
	iverilog -o uart_tx uart_tx.v uart_tx_tb.v && ./uart_tx

uart_rx: uart_rx.v uart_rx_tb.v Makefile
	iverilog -o uart_rx uart_rx.v uart_rx_tb.v && ./uart_rx

test: mux.v mux_tb.v Makefile
	iverilog -o my_design mux.v mux_tb.v && ./my_design
