library ieee;
use ieee.std_logic_1164.all;

-- note that writing one bit will require four clock cycles
-- if n_SEND is low, the module will continue sending bits consecutively
-- from the TO_GAMECUBE input

entity gamecube_bit_decoder is
    port(
        CLK:            in  std_logic; -- 1 MHz
        n_RST:          in  std_logic;
        BI_DIR_SERIAL:  out std_logic; -- connected to DATA line
        DIR:            in  std_logic; -- 1 for writing, 0 for reading
        n_SEND:         in  std_logic; -- 0 to send bit, 1 to wait
        TO_GAMECUBE:    in  std_logic;
        FROM_GAMECUBE:  out std_logic;
        BUSY:           out std_logic; -- 1 if busy, 0 if free
        LOAD:           out std_logic -- goes high 1 clock cycle before busy goes low
    );
end entity gamecube_bit_decoder;


architecture rtl of gamecube_bit_decoder is
    type state_type is (ready, writing_zero_bit_0, writing_zero_bit_1, writing_zero_bit_2, writing_zero_bit_3,
                               writing_one_bit_0,  writing_one_bit_1,  writing_one_bit_2,  writing_one_bit_3);
    signal state : state_type;
    signal next_state : state_type;
    signal output : std_logic;
    
begin
    next_state_logic : process(state, n_SEND, TO_GAMECUBE)
    begin
        -- defaults
        next_state <= ready;

        case state is
            when writing_zero_bit_0 => 
                next_state <= writing_zero_bit_1;
                BUSY <= '1';
                output <= '0';
                LOAD <= '0';
            when writing_zero_bit_1 =>
                next_state <= writing_zero_bit_2;
                BUSY <= '1';        
                output <= '0';
                LOAD <= '0';
            when writing_zero_bit_2 =>
                next_state <= writing_zero_bit_3;
                BUSY <= '1';
                output <= '0';
                LOAD <= '0';
            when writing_zero_bit_3 =>
                BUSY <= '1';
                output <= '1';
                if (n_SEND = '0' and TO_GAMECUBE = '1') then
                    next_state <= writing_one_bit_0; -- output encoded 1
                    LOAD <= '1';
                elsif (n_SEND = '0' and TO_GAMECUBE = '0') then
                    next_state <= writing_zero_bit_0; -- output encoded 0
                    LOAD <= '1';
                else
                    -- n_SEND = '1', done transmitting
                    next_state <= ready;
                    LOAD <= '0';
                end if;
                

            when writing_one_bit_0 =>
                next_state <= writing_one_bit_1;
                BUSY <= '1';
                output <= '0';
                LOAD <= '0';
            when writing_one_bit_1 =>
                next_state <= writing_one_bit_2;
                BUSY <= '1';
                output <= '1';
                LOAD <= '0';
            when writing_one_bit_2 =>
                next_state <= writing_one_bit_3;
                BUSY <= '1';    
                output <= '1';
                LOAD <= '0';
            when writing_one_bit_3 =>
                BUSY <= '1';
                output <= '1';
                if (n_SEND = '0' and TO_GAMECUBE = '1') then
                    next_state <= writing_one_bit_0; -- output encoded 1
                    LOAD <= '1';
                elsif (n_SEND = '0' and TO_GAMECUBE = '0') then
                    next_state <= writing_zero_bit_0; -- output encoded 0
                    LOAD <= '1';
                else
                    -- n_SEND = '1', done transmitting
                    next_state <= ready;
                    LOAD <= '0';
                end if;
            
            when others => -- state = ready
                BUSY <= '0';
                output <= 'Z';
                LOAD <= '0';
                if (n_SEND = '0' and TO_GAMECUBE = '1') then
                    next_state <= writing_one_bit_0; -- output encoded 1
                elsif (n_SEND = '0' and TO_GAMECUBE = '0') then
                    next_state <= writing_zero_bit_0; -- output encoded 0
                else
                    -- n_SEND = '1'
                    next_state <= ready;
                end if;
        end case;
    end process next_state_logic;
    
    reg_logic : process(CLK, n_RST)
    begin
        if (n_RST = '0') then
            state <= ready;
        elsif (CLK = '1' and CLK'event) then
            state <= next_state;
        end if;
    end process reg_logic;

    -- dummy assignment
    BI_DIR_SERIAL <= output;

    -- keep FROM_GAMECUBE high for now
    FROM_GAMECUBE <= '1';
end architecture rtl;