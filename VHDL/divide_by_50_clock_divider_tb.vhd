library ieee;
use ieee.std_logic_1164.all;

entity divide_by_50_clock_divider_tb is
  --empty
end divide_by_50_clock_divider_tb;


architecture beh of divide_by_50_clock_divider_tb is

  component divide_by_50_clock_divider
        port(
        	n_RST:      in std_logic;
        	CLK_IN:     in std_logic;
        	CLK_OUT:    out std_logic
    	);
  end component divide_by_50_clock_divider;

  --constant declaration
  constant period_c      : time := 20 ns;
  constant probe_c       : time := period_c/5; --probe signals 4 ns before the end of the cycle
  constant tb_skew_c     : time := period_c/20;
  constant severity_c    : severity_level := warning;

  --signal declaration
  signal tb_ck: 	 std_logic;
  signal ck:		 std_logic;
  signal n_rst:		 std_logic;
  signal clk_out:	 std_logic;

begin -- beh

   --mapping
   inst_divide_by_50_clock_divider: divide_by_50_clock_divider
     port map(
       n_RST => n_rst,
       CLK_IN => ck,
       CLK_OUT => clk_out
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
        report "mismatch error"
        severity severity_c;
      end if;
    end check_exp_val;
 
    procedure reset_tb is
    begin
      n_rst <= '0';
      wait for period_c/2;
      n_rst <= '1';
      wait for period_c/2;
    end reset_tb;

    	-- tests whether a zero is properly written to BI_DIR_SERIAL
    	 procedure test_clock_period is
		variable exp_value : std_logic_vector(49 downto 0) := "11111111111111111111111110000000000000000000000000";
	 begin
		for i in 0 to 49 loop
			wait_tb_ck;
			check_exp_val(exp_value(49-i), clk_out);
			wait_ck;
		end loop;
	 end test_clock_period;

  begin -- testbench process
  
    reset_tb;
  
    test_clock_period;

    -- waste time
    --wait_ck(50);

    assert false
    report "End of Simulation"
    severity failure;


  end process test_bench;

end beh;