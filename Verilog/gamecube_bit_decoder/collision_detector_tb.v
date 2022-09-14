`timescale 1ns/1ns;

module collision_detector_tb ();
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

    reg data_clk;
    initial begin
        @ (posedge clk_tb);
        #100 data_clk = 0; // offset to load inputs and read output
        forever begin
            #500 data_clk = ~data_clk;
        end
    end

    reg write_data, n_send;
    wire collision_detected;

    reg dir, gen;
    assign wire dataline = dir ? gen : 1'bZ;

    collision_detector dut (
        .WRITE_DATA(write_data),
        .n_SEND(n_send),
        .DATALINE(dataline),
        .COLLISION_DETECTED(collision_detected)
    );

    initial begin
        // initial values
        write_data = 0;
        n_send = 1;

        @ (posedge data_clk);
        assert (collision_detected, 0);

        write_data = 1;

        @ (posedge data_clk);
        assert (collision_detected, 0);
    end

endmodule