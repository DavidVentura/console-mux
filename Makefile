.PHONY: test lint clean build
SHELL := /bin/bash
BOARD=tangnano1k
FREQ_MHZ=27
FAMILY=GW1NZ-1
DEVICE=GW1NZ-LV1QN48C6/I5

# Family and device mapping come from 
# https://wiki.sipeed.com/hardware/en/tang/Tang-Nano-Doc/install-the-ide.html
# With a permalink at
# https://github.com/sipeed/sipeed_wiki/blob/ad092799a3da2f6c595a098e6ef3ccbe602c41fd/docs/hardware/en/tang/Tang-Nano-Doc/install-the-ide.md?plain=1#L46-L53

test: uart_rx_tb uart_tx_tb uart_tb mux_tb comm_tb fifo_tb comm.json comm_pnr.json comm.fs
	:
clean:
	rm -f uart_rx_tb uart_tx_tb uart_tb comm_tb mux_tb comm.json comm_pnr.json comm.fs

comm.json: comm.v mux.v uart_rx.v uart_tx.v fifo.v nano1k.v
	yosys -p "read_verilog $^; synth_gowin -top nano1k -json $@"

comm_pnr.json: comm.json ${BOARD}.cst
	nextpnr-gowin --json $(filter %.json,$^) --freq ${FREQ_MHZ} --write $@ --device ${DEVICE} --family ${FAMILY} --cst ${BOARD}.cst

comm.fs: comm_pnr.json
	gowin_pack -d ${FAMILY} -o $@ $^

build: comm.fs
	:

flash: comm.fs
	openFPGALoader -b ${BOARD} $^ -f

flash_mem: comm.fs
	openFPGALoader -b ${BOARD} $^ # write to ram

lint:
	# whines about undriven wires
	#verilator --top-module nano1k --timing -Wall -y . --lint-only *.v
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
