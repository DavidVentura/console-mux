.PHONY: test lint clean

test: uart_rx_tb uart_tx_tb uart_tb mux_tb comm_tb fifo_tb
	:
clean:
	rm -f uart_rx_tb uart_tx_tb uart_tb comm_tb mux_tb

lint:
	verilator --top-module comm --timing -Wall -y . --lint-only *.v

fifo_tb: fifo.v fifo_tb.v Makefile
	verilator --timing -Wall -y . --lint-only $(filter %.v,$^)
	iverilog -Wall -o $@ $(filter %.v,$^)
	./$@
mux_tb: mux.v mux_tb.v Makefile
	verilator --top-module $@ --timing -Wall -y . --lint-only $(filter %.v,$^)
	iverilog -Wall -o $@ $(filter %.v,$^)
	./$@

comm_tb: comm.v comm_tb.v uart_rx.v uart_tx.v mux.v fifo.v Makefile
	verilator --top-module $@ --timing -Wall -y . --lint-only $(filter %.v,$^)
	iverilog -Wall -o $@ $(filter %.v,$^)
	./$@

uart_tb: uart_tx.v uart_rx.v uart_tb.v Makefile
	verilator --top-module $@ --timing -Wall -y . --lint-only $(filter %.v,$^)
	iverilog -Wall -o $@ $(filter %.v,$^)
	./$@

uart_rx_tb: uart_rx.v uart_rx_tb.v Makefile
	verilator --top-module $@ --timing -Wall -y . --lint-only $(filter %.v,$^)
	iverilog -Wall -o $@ $(filter %.v,$^)
	./$@

uart_tx_tb: uart_tx.v uart_tx_tb.v Makefile
	verilator --top-module $@ --timing -Wall -y . --lint-only $(filter %.v,$^)
	iverilog -Wall -o $@ $(filter %.v,$^)
	./$@
