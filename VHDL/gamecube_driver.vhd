library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity gamecube_driver is
	port(
		CLK_IN:	    in std_logic; -- 50 MHz
        n_RST:      in std_logic;
        PACKET:     in std_logic_vector(8 downto 0);
        DATA:       out std_logic
	);
end entity gamecube_driver;

architecture rtl of gamecube_driver is

    component gamecube_bit_decoder
        port(
            CLK:            in std_logic; -- 1 MHz
            n_RST:          in std_logic;
            BI_DIR_SERIAL:  out std_logic; -- connected to DATA line
            DIR:			in std_logic; -- 1 for writing, 0 for reading
            n_SEND:			in std_logic; -- 0 to send data, 1 to wait
            TO_GAMECUBE:	in std_logic; -- unencoded 1 or 0
            FROM_GAMECUBE:  out std_logic; -- decoded 1 or 0
            BUSY:			out std_logic; -- 1 if busy, 0 if free
            LOAD:           out std_logic -- goes high 1 clock cycle before busy goes low
        );
    end component gamecube_bit_decoder;
    
    component open_collector_encoder
        port(
            CLK:        in std_logic;
            DIN:		in std_logic;
            DOUT:		out std_logic
        );
    end component open_collector_encoder;
    
    component divide_by_50_clock_divider
        port(
            n_RST:      in std_logic;
            CLK_IN:     in std_logic;
            CLK_OUT:    out std_logic
        );
    end component divide_by_50_clock_divider;
    
    -- constant delcaration
    constant packet_width : integer := 9;
    constant dir : std_logic := '1'; -- 1 for writing, 0 for reading
    
    --signal declaration
    signal CLK:             std_logic; -- 1 MHz
    signal bi_dir_serial:   std_logic; -- connected to DATA line
    signal n_send:	        std_logic; -- 0 to send data, 1 to wait
    signal from_gamecube:   std_logic;
    signal busy:		    std_logic; -- 1 if busy, 0 if free
    signal load:            std_logic; -- goes high one clock cycle before busy goes low
    
    -- FSM
    type state_type is (setup, sending, idle);
    signal state, next_state : state_type;
    signal pause_cycle, next_pause_cycle, bit_counter, next_bit_counter : integer range 0 to (64-1+16);
    signal to_gamecube, next_to_gamecube : std_logic;

    -- netlist
    signal gamecube_bit_decoder_serial_out : std_logic;
    
begin

    inst_gamecube_bit_decoder: gamecube_bit_decoder
        port map(
            CLK => CLK,
            n_RST => n_RST,
            BI_DIR_SERIAL => gamecube_bit_decoder_serial_out,
            DIR => dir,
            n_SEND => n_send,
            TO_GAMECUBE => to_gamecube,
            FROM_GAMECUBE => from_gamecube,
            BUSY => busy,
            LOAD => load
        );
        
    inst_open_collector_encoder: open_collector_encoder
        port map(
            CLK => CLK,
            DIN => gamecube_bit_decoder_serial_out,
            DOUT => DATA
        );
        
    inst_divide_by_50_clock_divider : divide_by_50_clock_divider
        port map(
            n_RST => n_RST,
            CLK_IN => CLK_IN,
            CLK_OUT => CLK -- 1 MHz
        ); 
   
    next_state_logic : process (state, pause_cycle, bit_counter, PACKET)
    begin
        -- defaults to preserve state
        next_state <= state;
        next_bit_counter <= bit_counter;
        next_pause_cycle <= pause_cycle;
        next_to_gamecube <= to_gamecube;
        
        case state is
            when setup =>
                if (bit_counter = 0) then
                    next_state <= sending;
                    next_bit_counter <= packet_width-1;
                    next_pause_cycle <= 3;
                    n_SEND <= '0';
                else
                    -- bit_counter > 0
                    
                    n_SEND <= '1';
                    
                    next_bit_counter <= bit_counter - 1;
                    next_to_gamecube <= PACKET(packet_width-1);
                end if;
            when sending =>
                if (bit_counter = 0) then
                    next_state <= idle;
                    next_bit_counter <= (64 - 1 + 16); -- 8 byte response from controller plus padding to let line go high
                    next_pause_cycle <= 3;
                    n_SEND <= '1';
                else
                    -- bit_counter > 0
                    
                    n_SEND <= '0';
                    
                    if (pause_cycle = 0) then
                        next_bit_counter <= bit_counter - 1;
                        next_pause_cycle <= 3;
                    elsif (pause_cycle = 1) then
                        -- pause_cycle > 0
                        next_to_gamecube <= PACKET(bit_counter-1);
                        next_pause_cycle <= pause_cycle - 1;
                    else
                        -- pause_cycle > 0
                        next_pause_cycle <= pause_cycle - 1;
                    end if;
                end if;
            when idle =>
                if (bit_counter = 0) then
                    next_state <= setup;  
                    next_bit_counter <= 1;
                    next_pause_cycle <= 3;
                    n_SEND <= '1';
                else
                    -- bit_counter > 0
                    
                    n_SEND <= '1';
                    next_to_gamecube <= '1';
                    
                    if (pause_cycle = 0) then
                        next_bit_counter <= bit_counter - 1;
                        next_pause_cycle <= 3;
                    else
                        -- pause_cycle > 0
                        
                        next_pause_cycle <= pause_cycle - 1;
                    end if;
                end if;
            when others => -- do nothing
        end case;
    end process next_state_logic;

    reg_logic : process (n_RST, CLK)
    begin
        if (n_RST = '0') then
            state <= setup;
            bit_counter <= 1;
            pause_cycle <= 3;
        elsif (CLK = '1' and CLK'event) then
            state <= next_state;
            bit_counter <= next_bit_counter;
            pause_cycle <= next_pause_cycle;
            to_gamecube <= next_to_gamecube;
        end if;
    end process reg_logic;
end architecture rtl;