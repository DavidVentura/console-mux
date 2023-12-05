module test;

reg clk = 0;
reg data_ready = 0;
wire done;
reg [7:0] data;
wire serial;

always #1 clk = !clk;

parameter CPB = 100;
uart_tx #(.CLK_PER_BIT(CPB)) tx(clk, data, data_ready, done, serial);

initial
begin
	$dumpfile("test.vcd");
	$dumpvars(0,test);
	data_ready <= 0;
	data <= 8'b01100011;
	data_ready <= 1;
	#1;
	data_ready <= 0;
	#(CPB*19);
	if (done != 1'b1) begin
		$display("Error: did not finish transmission");
	end
	$finish;
end

endmodule
