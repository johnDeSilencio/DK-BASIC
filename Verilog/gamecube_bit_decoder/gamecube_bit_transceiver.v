module gamecube_bit_transceiver (
    input CLK,
    input n_RST,
    input TX,
    input n_SEND,
    output reg BUSY,
    output reg RX,
    output reg VALID_DATA,
    inout DATALINE,
    output COLLISION_DETECTED
);
    
    gamecube_bit_transmitter transmitter (
        .CLK(CLK),
        .n_RST(n_RST),
        .n_SEND(n_SEND),
        .TX(TX),
        .DATALINE(DATALINE),
        .BUSY(busy)
    );

    gamecube_bit_receiver receiver (
        .CLK(CLK),
        .n_RST(n_RST),
        .DATALINE(DATALINE),
        .RX(RX),
        .VALID_DATA(VALID_DATA)
    );


endmodule