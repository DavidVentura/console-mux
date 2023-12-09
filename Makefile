.PHONY: test lint

test: uart_rx_tb uart_tx_tb uart_tx_rx_tb comm_tb mux_tb
	:

lint:
	verilator --top-module comm --timing -Wall -y . --lint-only *.v

mux_tb: mux.v mux_tb.v Makefile
	iverilog -Wall -o $@ $(filter %.v,$^)
	./$@

comm_tb: comm.v comm_tb.v uart_rx.v uart_tx.v mux.v fifo.v Makefile
	iverilog -Wall -o $@ $(filter %.v,$^)
	./$@

uart_tx_rx_tb: uart_tx.v uart_rx.v uart_tb.v Makefile
	iverilog -Wall -o $@ $(filter %.v,$^)
	./$@

uart_rx_tb: uart_rx.v uart_rx_tb.v Makefile
	iverilog -Wall -o $@ $(filter %.v,$^)
	./$@

uart_tx_tb: uart_tx.v uart_tx_tb.v Makefile
	iverilog -Wall -o $@ $(filter %.v,$^)
	./$@
