.PHONY: test lint

test: uart_rx uart_tx uart_tx_rx comm mux
	./uart_rx
	./uart_tx
	./uart_tx_rx
	./mux
	./comm

lint:
	verilator --timing -Wall -y . --lint-only *.v

mux: mux.v mux_tb.v Makefile
	iverilog -Wall -o $@ $(filter %.v,$^)

comm: comm.v comm_tb.v uart_rx.v uart_tx.v mux.v fifo.v Makefile
	iverilog -Wall -o $@ $(filter %.v,$^)

uart_tx_rx: uart_tx.v uart_rx.v uart_tb.v Makefile
	iverilog -Wall -o $@ $(filter %.v,$^)

uart_rx: uart_rx.v uart_rx_tb.v Makefile
	iverilog -Wall -o $@ $(filter %.v,$^)

uart_tx: uart_tx.v uart_tx_tb.v Makefile
	iverilog -Wall -o $@ $(filter %.v,$^)
