module gamecube_bit_receiver (
    input CLK,
    input n_RST,
    input DATALINE,
    output reg RX,
    output reg VALID_DATA
);
    // This module is designed to decode virtual bits from the bidirectional
    // serial dataline according to the 1 MHz Gamecube Protocol (see documentation
    // in gamecube_bit_transmitter.v for more information on this encoding).
    //
    // Transmissions received on the DATALINE input are decoded internally using
    // a Moore FSM. When a bit has been successfully decoded from DATALINE, the
    // output RX is toggled high or low accordingly. VALID_DATA then goes high
    // for one clock cycle before going low again. It is recommended to sample
    // RX on the positive edge of VALID_DATA.

    localparam STATE_INITIAL = 3'd0;
    localparam STATE_READING_SECOND_VBIT = 3'd1;
    localparam STATE_READING_ZERO_VBIT_2 = 3'd2;
    localparam STATE_READING_ZERO_VBIT_3 = 3'd3;
    localparam STATE_READING_ONE_VBIT_2 = 3'd4;
    localparam STATE_READING_ONE_VBIT_3 = 3'd5;

    reg [2:0] curr_state;
    reg [2:0] next_state;

    // sequential, output logic
    always @ (posedge CLK) begin
        if (n_RST == 0) begin
            curr_state <= STATE_INITIAL;
            RX <= 1;
            VALID_DATA <= 0; 
        end else
            curr_state <= next_state;

        case (curr_state)
            STATE_READING_ZERO_VBIT_2: begin
                RX <= 0;
                VALID_DATA <= 0;
            end

            STATE_READING_ZERO_VBIT_3: begin
                RX <= 0;
                VALID_DATA <= 1;
            end

            STATE_READING_ONE_VBIT_2: begin
                RX <= 1;
                VALID_DATA <= 0;
            end

            STATE_READING_ONE_VBIT_3: begin
                RX <= 1;
                VALID_DATA <= 1;
            end
        
            default: begin
                // curr_state == STATE_INITIAL, or
                // curr_state == STATE_READING_SECOND_VBIT
                RX <= 1;
                VALID_DATA <= 0;
            end
        endcase
    end

    // combinational, next-state logic
    always @ (*) begin
        // default state is preserved
        next_state <= curr_state;

        case (curr_state)
            STATE_INITIAL: begin
                if (DATALINE == 0)
                    next_state <= STATE_READING_SECOND_VBIT;
                else
                    next_state <= STATE_INITIAL;
            end

            STATE_READING_SECOND_VBIT: begin
                if (DATALINE == 0)
                    next_state <= STATE_READING_ZERO_VBIT_2;
                else
                    // DATALINE == 1
                    next_state <= STATE_READING_ONE_VBIT_2;
            end

            STATE_READING_ZERO_VBIT_2: begin
                if (DATALINE == 0)
                    next_state <= STATE_READING_ZERO_VBIT_3;
                else
                    // DATALINE == 1, corrupt bit transmission, so we reset
                    next_state <= STATE_INITIAL;
            end
            
            STATE_READING_ONE_VBIT_2: begin
                if (DATALINE == 1)
                    next_state <= STATE_READING_ONE_VBIT_3;
                else
                    // DATALINE == 0, corrupt bit transmission, so we reset
                    next_state <= STATE_INITIAL;
            end

            default: begin
                // curr_state == STATE_READING_ZERO_VBIT_3, or
                // curr_state == STATE_READING_ONE_VBIT_3, so we
                // either record another bit or reset
                if (DATALINE == 0)
                    next_state <= STATE_READING_SECOND_VBIT;
                else
                    // DATALINE == 1
                    next_state <= STATE_INITIAL;
            end
        endcase
    end
endmodule