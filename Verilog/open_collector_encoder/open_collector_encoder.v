module open_collector_encoder (
    input DIN,
    output reg DOUT
);
    // bidirectional serial data line has pull-up resistor,
    // so we use NPN transistor to pull the line low for a zero
    // and disconnect from data line when writing a one or
    // when going into a high impedance state

    always @ (*) begin
        DOUT <= 0; // high impedance state by default
        
        if (DIN == 0)
            DOUT <= 1;  // pulling the line down low
    end
endmodule