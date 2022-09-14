library ieee;
use ieee.std_logic_1164.all;

entity gamecube_bit_decoder_tb is
    --empty
end gamecube_bit_decoder_tb;


architecture beh of gamecube_bit_decoder_tb is

    component gamecube_bit_decoder
        port(
            CLK:                in  std_logic; -- 1 MHz
            n_RST:              in  std_logic;
            BI_DIR_SERIAL:      out std_logic; -- connected to DATA line
            DIR:                in  std_logic; -- 1 for writing, 0 for reading
            n_SEND:             in  std_logic; -- 0 to send data, 1 to wait
            TO_GAMECUBE:        in  std_logic; -- unencoded 1 or 0
            FROM_GAMECUBE:      out std_logic; -- decoded 1 or 0
            BUSY:               out std_logic; -- 1 if busy, 0 if free
            LOAD:               out std_logic -- goes high one cycle before BUSY goes low
        );
    end component gamecube_bit_decoder;

    --constant declaration
    constant period_c      : time := 1.0 us;
    constant probe_c       : time := period_c/2.0; --probe signals 4 ns before the end of the cycle
    constant tb_skew_c     : time := period_c/8.0;
    constant severity_c    : severity_level := warning;

    --signal declaration
    signal tb_ck:           std_logic;
    signal ck:              std_logic;
    signal n_rst:           std_logic;
    signal bi_dir_serial:   std_logic; -- connected to DATA line
    signal dir:             std_logic; -- 1 for writing, 0 for reading
    signal n_send:          std_logic; -- 0 to send data, 1 to wait
    signal to_gamecube:     std_logic;
    signal from_gamecube:   std_logic;
    signal busy:            std_logic; -- 1 if busy, 0 if free
    signal load:            std_logic; -- goes high one clock cycle before busy goes low
begin -- beh

    --mapping
    inst_gamecube_bit_decoder: gamecube_bit_decoder
        port map(
            CLK => ck,
            n_RST => n_rst,
            BI_DIR_SERIAL => bi_dir_serial,
            DIR => dir,
            n_SEND => n_send,
            TO_GAMECUBE => to_gamecube,
            FROM_GAMECUBE => from_gamecube,
            BUSY => busy,
            LOAD => load
        );

 
    -- testbench clock generator
    tb_ck_gen : process
    begin
        tb_ck <= '1';
        wait for period_c/2;
        tb_ck <= '0';
        wait for period_c/2;
    end process;
  
 
    -- system clock generator
    clock_gen : process (tb_ck)
    begin
        ck <= transport tb_ck after tb_skew_c;
    end process;
    
    
    --
    -- the test bench process
    --
    test_bench : process
    
        --
        -- wait for the rising edge of tb_ck
        --
        procedure wait_tb_ck(num_cyc : integer := 1) is
        begin
        for i in 1 to num_cyc loop
            wait until tb_ck'event and tb_ck = '1';
        end loop;
        end wait_tb_ck;
    
        --
        -- wait for the rising edge of clk
        --
        procedure wait_ck(num_cyc : integer := 1) is
        begin
        for i in 1 to num_cyc loop
            wait until ck'event and ck = '1';
        end loop;
        end wait_ck;
    
        --
        -- check expected value for a std_logic
        --
        procedure check_exp_val(sig_to_test : std_logic; exp_val : std_logic; comment : string := " ") is
        begin
        if (sig_to_test /= exp_val) then
            assert false
            report "mismatch error"
            severity severity_c;
        end if;
        end check_exp_val;
        
        --
        -- initialize all input signals: nothing must be left floating
        --
        procedure initialize_tb is
        begin
            n_rst         <= '1';
            dir           <= '1';
            to_gamecube   <= '0';
            n_send        <= '1';
        end initialize_tb;
        
        --
        -- reset the tb 
        --
        procedure reset_tb is
        begin
            n_rst <= '1';
            wait for period_c/2;
            n_rst <= '0';
            wait for period_c/2;
            n_rst <= '1';
        end reset_tb;
    
        -- tests whether a zero is properly written to BI_DIR_SERIAL
        procedure test_write_one is
            variable exp_value : std_logic_vector(3 downto 0) := "0111";
        begin
            wait_tb_ck;
            
            TO_GAMECUBE <= '1';
            DIR <= '1';
            n_SEND <= '0';
            wait_ck;
            
            n_SEND <= '1';
    
            check_exp_val(BI_DIR_SERIAL, exp_value(3));
            check_exp_val(LOAD, '0');
            wait_tb_ck;
            wait_ck;

            check_exp_val(BI_DIR_SERIAL, exp_value(2));
            check_exp_val(LOAD, '0');
            wait_tb_ck;
            wait_ck;
   
            check_exp_val(BI_DIR_SERIAL, exp_value(1));
            check_exp_val(LOAD, '0');
            wait_tb_ck;
            wait_ck;

            check_exp_val(BI_DIR_SERIAL, exp_value(0));
            check_exp_val(LOAD, '0');
            wait_tb_ck;
            wait_ck;
    
            wait_tb_ck;
            n_SEND <= '1';
            wait_ck;
        end test_write_one;
        
        -- tests whether a zero is properly written to BI_DIR_SERIAL
        procedure test_write_zero is
            variable exp_value : std_logic_vector(3 downto 0) := "0001";
        begin
            wait_tb_ck;
            TO_GAMECUBE <= '0';
            DIR <= '1';
            n_SEND <= '0';
            wait_ck;
    
            n_SEND <= '1';
            
            check_exp_val(BI_DIR_SERIAL, exp_value(3));
            check_exp_val(LOAD, '0');
            wait_tb_ck;
            wait_ck;

            check_exp_val(BI_DIR_SERIAL, exp_value(2));
            check_exp_val(LOAD, '0');
            wait_tb_ck;
            wait_ck;
   
            check_exp_val(BI_DIR_SERIAL, exp_value(1));
            check_exp_val(LOAD, '0');
            wait_tb_ck;
            wait_ck;

            check_exp_val(BI_DIR_SERIAL, exp_value(0));
            check_exp_val(LOAD, '0');
            wait_tb_ck;
            wait_ck;

            wait_tb_ck;
            n_SEND <= '1';
            wait_ck;
        end test_write_zero;

        procedure test_write_byte is
            variable exp_value : std_logic_vector(31 downto 0) := "00010111000101110001011100010111";
        begin
            wait_tb_ck;
            TO_GAMECUBE <= '0';
            DIR <= '1';
            n_SEND <= '0';
            wait_ck;
            for i in 0 to 4 loop
                -- write zero
                check_exp_val(BI_DIR_SERIAL, exp_value(8*i));
                check_exp_val(LOAD, '0');
                wait_tb_ck;
                wait_ck;
    
                check_exp_val(BI_DIR_SERIAL, exp_value(8*i+1));
                check_exp_val(LOAD, '0');
                wait_tb_ck;
                wait_ck;
   
                check_exp_val(BI_DIR_SERIAL, exp_value(8*i+2));
                check_exp_val(LOAD, '0');
                wait_tb_ck;
                wait_ck;

                TO_GAMECUBE <= '1';

                check_exp_val(BI_DIR_SERIAL, exp_value(8*i+3));
                check_exp_val(LOAD, '1');
                wait_tb_ck;
                wait_ck;
                
                -- write one
                check_exp_val(BI_DIR_SERIAL, exp_value(8*i+4));
                check_exp_val(LOAD, '0');
                wait_tb_ck;
                wait_ck;
        
                check_exp_val(BI_DIR_SERIAL, exp_value(8*i+5));
                check_exp_val(LOAD, '0');
                wait_tb_ck;
                wait_ck;
        
                check_exp_val(BI_DIR_SERIAL, exp_value(8*i+6));
                check_exp_val(LOAD, '0');
                wait_tb_ck;
                wait_ck;
        
                TO_GAMECUBE <= '0';

                check_exp_val(BI_DIR_SERIAL, exp_value(8*i+7));
                check_exp_val(LOAD, '1');
                wait_tb_ck;
                wait_ck;
            end loop;

            wait_tb_ck;
            n_SEND <= '1';
            wait_ck;

        end test_write_byte;
        

    begin -- testbench process
    
        initialize_tb;
        reset_tb;

        -- make sure ones are written properly encoded
        test_write_one;
    
        -- waste time
        wait_ck(5);
        
        -- make sure zeros are written properly encoded
        test_write_zero;
    
        wait_ck(5);

        -- make sure we can write a byte continuously
        test_write_byte;

    wait_ck(40);
    
        assert false
        report "End of Simulation"
        severity failure;
    
    
    end process test_bench;
end beh;

