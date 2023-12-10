module fifo_tb;
	reg clk = 0;
	always #1 clk <= ~clk;
	wire f_w_en;
	reg f_w_en_r = 0;
	reg f_adv_r = 0;
	reg [7:0] f_data_in = 0;
	wire [7:0] f_data_out;
	wire f_full;
	wire f_data_avail;
	wire rst;
	assign f_w_en = f_w_en_r;
	fifo f(clk, f_w_en, f_adv_r, rst, f_data_in, f_data_out, f_full, f_data_avail);

	reg rst_r = 0;
	assign rst = rst_r;

	task assert_after_rst;
		begin
			@(posedge clk) rst_r = 1;
			@(posedge clk) rst_r = 0;
			@(posedge clk) begin
				if (f_full != 0) begin
					$display("Was full after reset");
					$finish;
				end
				if (f_data_avail != 0) begin
					$display("Was available after reset");
					$finish;
				end
			end
		end
	endtask

	task write_once;
		begin
			@(posedge clk) rst_r = 1;
			@(posedge clk) rst_r = 0;
			@(posedge clk) begin
				f_w_en_r = 1;
				f_data_in = 8'hab;
			end
			@(posedge clk);
			@(posedge clk) begin
				if (f_full != 0) begin
					$display("Was full after 1 write");
					$finish;
				end
				if (f_data_avail != 1) begin
					$display("Was not available after 2 clock cycles");
					$finish;
				end
			end
		end
	endtask

	task read_when_available;
		begin
			@(posedge clk) rst_r = 1;
			@(posedge clk) rst_r = 0;
			@(posedge clk) begin
				f_w_en_r = 1;
				f_data_in = 8'hff;
			end
			wait (f_data_avail);
			if (f_data_out != 8'hff) begin
				$display("Got bad data out");
				$finish;
			end
		end
	endtask

	task mark_read_when_available;
		begin
			@(posedge clk) rst_r = 1;
			@(posedge clk) rst_r = 0;
			@(posedge clk) begin
				f_w_en_r = 1;
				f_data_in = 8'hff;
			end
			wait (f_data_avail);
			if (f_data_out != 8'hff) begin
				$display("Got bad data out");
				$finish;
			end

			f_adv_r = 1;
			@(posedge clk);
			@(posedge clk) begin
				if (f_data_avail != 0) begin
					$display("Was AVAILABLE after 2 clock cycles");
					$finish;
				end
			end
		end
	endtask

	initial begin
		$dumpfile("test.vcd");
		$dumpvars(0, fifo_tb);
		assert_after_rst();
		write_once();
		read_when_available();
		mark_read_when_available();
		#2 $finish;
	end

	always @(posedge clk) begin
		if(f_adv_r) f_adv_r <= 0;
		if (f_w_en_r) f_w_en_r <= 0;
	end
endmodule
