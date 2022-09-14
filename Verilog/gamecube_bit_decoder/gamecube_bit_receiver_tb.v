`timescale 1ns/1ns;

module gamecube_bit_receiver_tb ();
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

    reg n_rst;
    wire dataline, rx, valid_data;

    gamecube_bit_receiver receiver (
        .CLK(clk_tb),
        .n_RST(n_rst),
        .DATALINE(dataline),
        .RX(rx),
        .VALID_DATA(valid_data)
    );

    reg n_send, tx;
    wire busy;

    integer i;
    localparam [7:0] capital_b = 8'b01000010;

    gamecube_bit_transmitter transmitter (
        .CLK(clk_tb),
        .n_RST(n_rst),
        .n_SEND(n_send),
        .TX(tx),
        .DATALINE(dataline),
        .BUSY(busy)
    );             

    initial begin
        // initial values
        n_rst = 1;

        @ (posedge data_clk);
        n_rst = 0;
        @ (posedge data_clk);
        n_rst = 1;

        @ (posedge data_clk);
        assert (rx, 1);
        assert (valid_data, 0);


        // transmit the byte 0x42
        tx = capital_b[7];
        @ (posedge data_clk);
        n_send = 0;
        @ (posedge data_clk);

        for (i = 7; i >= 0; i = i - 1) begin
            @ (posedge data_clk);
            if (i < 7) begin
                assert (rx, capital_b[i+1]);
                assert (valid_data, 1);
            end
            @ (posedge data_clk);
            assert (valid_data, 0);
            @ (posedge data_clk);

            // shift to next transmission bit
            if (i > 0)
                tx <= capital_b[i-1];
            else
                n_send <= 1;

            @ (posedge data_clk);
        end

        @ (posedge data_clk);
        assert (rx, capital_b[0]);
        assert (valid_data, 1);

        @ (posedge data_clk);
        assert (valid_data, 0);
    end

endmodule