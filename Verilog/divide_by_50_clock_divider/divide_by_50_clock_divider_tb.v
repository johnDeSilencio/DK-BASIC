`timescale 1ns/1ns;

module divide_by_50_clock_divider_tb ();
    task assert ( input signal, input exp_value);
        begin
            if (signal !== exp_value) begin
                $display("ASSERTION FAILED in %m");
                $stop();
            end
        end
    endtask

    reg clk_tb;
    initial begin
        clk_tb = 0;
        forever begin
            #500 clk_tb = ~clk_tb;
        end
    end

    reg n_rst;
    wire clk_out;
    integer i;
    divide_by_50_clock_divider dut ( .CLK_IN(clk_tb), .n_RST(n_rst), .CLK_OUT(clk_out) );

    initial begin
        n_rst = 1;

        #100 n_rst = 0;
        #100 n_rst = 1;
        assert (clk_out, 1);
        
        @ (posedge clk_tb);

        for (i = 0; i < 25; i = i + 1)
            @ (posedge clk_tb);
        assert (clk_out, 0);

        for (i = 0; i < 25; i = i + 1)
            @ (posedge clk_tb);
        assert (clk_out, 1);
    end
endmodule