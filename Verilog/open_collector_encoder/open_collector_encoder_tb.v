`timescale 1ns/1ns;

module open_collector_encoder_tb ();
    task assert ( input signal, input exp_value );
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

    reg din;
    wire dout;
    open_collector_encoder dut ( .DIN(din), .DOUT(dout) );

    initial begin
        din <= 0;
        @ (posedge clk_tb);
        assert (dout, 1);

        din <= 1;
        @ (posedge clk_tb);
        assert (dout, 0);

        //din <= z;
        //@ (posedge clk_tb);
        //assert (dout, 0);
    end
endmodule