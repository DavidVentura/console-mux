.PHONY: test lint clean build
SHELL := /bin/bash
BOARD=tangnano1k
FREQ_MHZ=27
# FIXME?
FAMILY=GW1NZ-1
DEVICE=GW1NZ-LV1QN48C6/I5

test: uart_rx_tb uart_tx_tb uart_tb mux_tb comm_tb fifo_tb comm.json comm_pnr.json comm.fs
	:
clean:
	rm -f uart_rx_tb uart_tx_tb uart_tb comm_tb mux_tb comm.json comm_pnr.json comm.fs

comm.json: comm.v mux.v uart_rx.v uart_tx.v fifo.v
	yosys -p "read_verilog $^; synth_gowin -top comm -json $@"

comm_pnr.json: comm.json
	nextpnr-gowin --json $^ --freq ${FREQ_MHZ} --write $@ --device ${DEVICE} --family ${FAMILY} --cst ${BOARD}.cst
	#nextpnr-gowin --json $^ --freq ${FREQ_MHZ} --write $@ --device ${DEVICE} --cst ${BOARD}.cst

comm.fs: comm_pnr.json
	gowin_pack -d ${FAMILY} -o $@ $^

build: comm.fs
	:

flash: comm.fs
	openFPGALoader -b ${BOARD} $^ -f

lint:
	verilator --top-module comm --timing -Wall -y . --lint-only *.v

fifo_tb: fifo.v fifo_tb.v Makefile
	verilator --timing -Wall -y . --lint-only $(filter %.v,$^)
	iverilog -Wall -o $@ $(filter %.v,$^)
	./$@
mux_tb: mux.v mux_tb.v Makefile
	verilator --timing -Wall -y . --lint-only $(filter %.v,$^)
	iverilog -Wall -o $@ $(filter %.v,$^)
	./$@

comm_tb: comm.v comm_tb.v uart_rx.v uart_tx.v mux.v fifo.v Makefile
	verilator --timing -Wall -y . --lint-only $(filter %.v,$^)
	iverilog -Wall -o $@ $(filter %.v,$^)
	./$@

uart_tb: uart_tx.v uart_rx.v uart_tb.v Makefile
	verilator --timing -Wall -y . --lint-only $(filter %.v,$^)
	iverilog -Wall -o $@ $(filter %.v,$^)
	./$@

uart_rx_tb: uart_rx.v uart_rx_tb.v Makefile
	verilator --timing -Wall -y . --lint-only $(filter %.v,$^)
	iverilog -Wall -o $@ $(filter %.v,$^)
	./$@

uart_tx_tb: uart_tx.v uart_tx_tb.v Makefile
	verilator --timing -Wall -y . --lint-only $(filter %.v,$^)
	iverilog -Wall -o $@ $(filter %.v,$^)
	./$@
