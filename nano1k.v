module nano1k(input clk, input rx_serial, output tx_serial, output [3:0] out_pins, input [3:0] in_pins);

localparam freq = 27_000_000;
localparam baud = 9600;
localparam divider = freq / baud;

comm #(.CLOCK_PER_BIT(divider), .OUTPUT_COUNT(5), .INPUT_COUNT(5)) comm(clk, rx_serial, tx_serial, out_pins, in_pins);

endmodule
