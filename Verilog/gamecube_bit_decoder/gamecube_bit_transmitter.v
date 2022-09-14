module gamecube_bit_transmitter (
    input CLK,              // 1 MHz, 50% duty cycle clock
    input n_RST,            // Active-low, synchronous reset signal
    input n_SEND,           // Active-low, starts transmission of virtual bits on DATALINE
    input TX,              // Input data to transmit
    output reg DATALINE,    // Output data encoded with Gamecube Protocol
    output reg BUSY         // Signal
);
    // In the Gamecube Protocol, the clock rate is 1 MHz on the
    // bidirectional serial data line, but four clock pulses are
    // required to send either a zero or a one, meaning the maximum
    // effective bit rate is actually 250 kbaud. The level of the
    // data line at the positive edge of each clock pulse is therefore
    // referred to as a "virtual bit" for the remainder of this module,
    // while "bit" refers to the properly encoded bit comprised of
    // four virtual bits.
    //
    // '0' is encoded with the following virtual bits: '0', '0', '0', and '1'.
    // '1' is encoded with the following virtual bits: '0', '1', '1', and '1'.
    //
    // When idle, the BUSY flag is low. When n_SEND is low on the positive
    // edge of CLK, BUSY goes high for three clock cycles while it transmits
    // the virtual bits corresponding to the value at BIT on that positive edge
    // of CLK. On the positive edge of the fourth clock cycle, BUSY goes low.
    //
    // To transmit either a zero or a one, the n_SEND flag must be pulled
    // low when the BUSY flag is also low. For bit streams, it is convenient
    // to keep the n_SEND signal low and to use the negative edge of the BUSY signal
    // to shift the bit stream one clock cycle prior to the capturing positive edge.
    //
    // This module internally uses a Moore FSM, so the outputs are synchronous, meaning
    // that the DATALINE will be pulled low one clock cycle after n_SEND is captured
    // low on a positive clock edge. When transmitting a bit stream and n_SEND is
    // kept low, however, the virtual bits are transmitted "back-to-back". Transmitting
    // a byte with a 1 MHz clock, for example, would take 33 us since there is a 1 us
    // (1 clock cycle) delay before the transmission begins, after which the 32 virtual
    // bits required to transmit eight bits take the remaining 32 us to transmit.

    localparam STATE_IDLE = 3'd0;
    localparam STATE_WRITING_ZERO_VBIT_0 = 3'd1;
    localparam STATE_WRITING_ZERO_VBIT_1 = 3'd2;
    localparam STATE_WRITING_ZERO_VBIT_2 = 3'd3;
    localparam STATE_WRITING_ONE_VBIT_0 = 3'd4;
    localparam STATE_WRITING_ONE_VBIT_1 = 3'd5;
    localparam STATE_WRITING_ONE_VBIT_2 = 3'd6;
    localparam STATE_WRITING_FINAL_VBIT = 3'd7; // last virtual bit is high for both '0' and '1'

    reg [2:0] curr_state;
    reg [2:0] next_state;

    // sequential, output logic
    always @ (posedge CLK) begin        
        if (n_RST == 0) begin
            BUSY <= 0;
            DATALINE <= 1; // let bus float high when idle
            curr_state <= STATE_IDLE;
        end else
            curr_state <= next_state;

        // default output values
        BUSY <= 0;
        DATALINE <= 1;

        case (curr_state)
            STATE_IDLE: begin
                BUSY <= 0;
                DATALINE <= 1; // let bus float high when idle
            end

            STATE_WRITING_ZERO_VBIT_0:      begin BUSY <= 1; DATALINE <= 0; end
            STATE_WRITING_ZERO_VBIT_1:      begin BUSY <= 1; DATALINE <= 0; end
            STATE_WRITING_ZERO_VBIT_2:      begin BUSY <= 1; DATALINE <= 0; end
            STATE_WRITING_ONE_VBIT_0:       begin BUSY <= 1; DATALINE <= 0; end
            STATE_WRITING_ONE_VBIT_1:       begin BUSY <= 1; DATALINE <= 1; end
            STATE_WRITING_ONE_VBIT_2:       begin BUSY <= 1; DATALINE <= 1; end
            STATE_WRITING_FINAL_VBIT:       DATALINE <= 1;

            default:                        DATALINE <= 1;
        endcase
    end

    // combinational, next-state logic
    always @ (*) begin
        // default state is preserved
        next_state <= curr_state;

        case (curr_state)
            STATE_IDLE: begin
                if (n_SEND == 0 && TX == 0)
                    next_state <= STATE_WRITING_ZERO_VBIT_0;
                else if (n_SEND == 0 && TX == 1)
                    next_state <= STATE_WRITING_ONE_VBIT_0;
                else
                    next_state <= STATE_IDLE;
            end
            
            STATE_WRITING_ZERO_VBIT_0:  next_state <= STATE_WRITING_ZERO_VBIT_1;
            STATE_WRITING_ZERO_VBIT_1:  next_state <= STATE_WRITING_ZERO_VBIT_2;
            STATE_WRITING_ZERO_VBIT_2:  next_state <= STATE_WRITING_FINAL_VBIT;

            STATE_WRITING_ONE_VBIT_0:   next_state <= STATE_WRITING_ONE_VBIT_1;
            STATE_WRITING_ONE_VBIT_1:   next_state <= STATE_WRITING_ONE_VBIT_2;
            STATE_WRITING_ONE_VBIT_2:   next_state <= STATE_WRITING_FINAL_VBIT;

            STATE_WRITING_FINAL_VBIT: begin
                if (n_SEND == 0 && TX == 0)
                    next_state <= STATE_WRITING_ZERO_VBIT_0;
                else if (n_SEND == 0 && TX == 1)
                    next_state <= STATE_WRITING_ONE_VBIT_0;
                else
                    next_state <= STATE_IDLE;
            end

            default:                    next_state <= STATE_IDLE;
        endcase
    end

endmodule