library ieee;
use ieee.std_logic_1164.all;

entity open_collector_encoder_tb is
  --empty
end open_collector_encoder_tb;


architecture beh of open_collector_encoder_tb is

  component open_collector_encoder
        port(
		CLK:	in std_logic;
		DIN:	in std_logic;
	   	DOUT:	out std_logic
	);
  end component open_collector_encoder;

  --constant declaration
  constant period_c      : time := 1.0 us;
  constant probe_c       : time := period_c/5; --probe signals 4 ns before the end of the cycle
  constant tb_skew_c     : time := period_c/20;
  constant severity_c    : severity_level := warning;

  --signal declaration
  signal tb_ck: 	 std_logic;
  signal ck:		 std_logic;
  signal din:		 std_logic;
  signal dout:		 std_logic;

begin -- beh

   --mapping
   inst_open_collector_encoder: open_collector_encoder
     port map(
       CLK => ck,
       DIN => din,
       DOUT => dout
     );

 
  -- testbench clock generator
  tb_ck_gen : process
  begin
    tb_ck <= '0';
    wait for period_c/2;
    tb_ck <= '1';
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
        report "mismatch error: dout = " & std_logic'image(sig_to_test)
        severity severity_c;
      end if;
    end check_exp_val;
    
    --
    -- initialize all input signals: nothing must be left floating
    --
    procedure initialize_tb is
    begin
      din <= 'Z';
    end initialize_tb;

    	-- tests whether a zero is properly written to BI_DIR_SERIAL
    	 procedure test_write_one is
		variable exp_value : std_logic := '0';
	 begin
		wait_tb_ck;
		din <= '1';
		wait_ck;
		wait_tb_ck;
		check_exp_val(dout, exp_value);
		wait_ck;
	 end test_write_one;
	 
	 -- tests whether a zero is properly written to BI_DIR_SERIAL
	 procedure test_write_zero is
		variable exp_value : std_logic := '1';
	 begin
		wait_tb_ck;
		din <= '0';
		wait_ck;
		wait_tb_ck;
		check_exp_val(dout, exp_value);
		wait_ck;
	 end test_write_zero;
   
	procedure test_write_high_impedance is
		variable exp_value : std_logic := '0';
	begin
		wait_tb_ck;
		din <= 'Z';
		wait_ck;
		wait_tb_ck;
		check_exp_val(dout, exp_value);
		wait_ck;
	end test_write_high_impedance;

  begin -- testbench process
  
    initialize_tb;

    -- make sure ones are written properly encoded
    test_write_one;

    -- waste time
    wait_ck(1);
	 
    -- make sure zeros are written properly encoded
    test_write_zero;

    -- waste time
    wait_ck(1);

    -- make sure high impedance state is properly encoded
    test_write_high_impedance;

    -- waste time
    wait_ck(1);

    assert false
    report "End of Simulation"
    severity failure;


  end process test_bench;

end beh;
