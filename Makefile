.PHONY: uart_tx lint
comm: comm.v comm_tb.v uart_rx.v uart_tx.v mux.v fifo.v Makefile
	iverilog -Wall -o $@ $(filter %.v,$^) && ./$@

lint:
	verilator -Wall -y . --lint-only *.v

uart_tx_rx: uart_tx.v uart_rx.v uart_tb.v Makefile
	iverilog -Wall -o $@ $(filter %.v,$^) && ./$@

uart_tx: uart_tx.v uart_tx_tb.v Makefile
	iverilog -Wall -o uart_tx uart_tx.v uart_tx_tb.v && ./uart_tx

uart_rx: uart_rx.v uart_rx_tb.v Makefile
	iverilog -Wall -o uart_rx uart_rx.v uart_rx_tb.v && ./uart_rx

test: mux.v mux_tb.v Makefile
	iverilog -Wall -o my_design mux.v mux_tb.v && ./my_design
