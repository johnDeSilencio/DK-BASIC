library ieee;
use ieee.std_logic_1164.all;

entity keyboard_mapping_fsm_tb is
  --empty
end keyboard_mapping_fsm_tb;

architecture beh of keyboard_mapping_fsm_tb is

  component keyboard_mapping_fsm
		port(
			CLK:			in std_logic;  -- Clock used to trigger state change
			n_RST:		in std_logic;  -- Active-low reset used to initialize the module
			FRB:			in std_logic;	-- Front Right Bongo
			BRB:			in std_logic;  -- Back Right Bongo
			BLB:			in std_logic;	-- Back Left Bongo
			FLB:			in std_logic;	-- Front Left Bongo
			START:		in std_logic;  -- Start Button
			MIC:			in std_logic;  -- Clap detection microphone
			WRITE_MODE:	in std_logic;  -- '0' for binary mode, '1' for hex mode
			CHAR_OUT:	out std_logic_vector(6 downto 0); -- 7-bit ASCII character output
			VALID:		out std_logic  -- '1' indicates valid data on CHAR_OUT, '0' is invalid
		);
  end component keyboard_mapping_fsm;

  --constant declaration
  constant period_c      : time := 1.0 us;
  constant probe_c       : time := period_c/5; --probe signals 4 ns before the end of the cycle
  constant tb_skew_c     : time := period_c/8; -- eighth of a cycle offset between clocks
  constant severity_c    : severity_level := warning;
  
  constant invalid_output		: std_logic_vector(6 downto 0) := "0000000";
  constant binary_0     		: std_logic_vector(6 downto 0) := "0110000";
  constant binary_1		 		: std_logic_vector(6 downto 0) := "0110001";
  constant ctrl_right_arrow   : std_logic_vector(6 downto 0) := "0000000"; -- TODO: Define
  constant ctrl_left_arrow	   : std_logic_vector(6 downto 0) := "0000000"; -- TODO: Define
  constant ctrl_deletion		: std_logic_vector(6 downto 0) := "0001000";
  
  --signal declaration
  signal tb_ck: 	 	std_logic;
  signal ck:		 	std_logic;
  signal n_rst:	 	std_logic;  -- Reset used to initialize the module
  signal frb:		 	std_logic;	-- Front Right Bongo
  signal brb:		 	std_logic;  -- Back Right Bongo
  signal blb:		 	std_logic;	-- Back Left Bongo
  signal flb:		 	std_logic;	-- Front Left Bongo
  signal start:	 	std_logic;  -- Start Button
  signal mic:		   std_logic;  -- Clap detection microphone
  signal write_mode: std_logic;  -- '0' for binary mode, '1' for hex mode
  signal char_out:	std_logic_vector(6 downto 0); -- 7-bit ASCII character output
  signal valid:		std_logic;  -- '1' indicates valid data on CHAR_OUT, '0' is invalid

begin -- beh

   --mapping
   inst_keyboard_mapping_fsm: keyboard_mapping_fsm
     port map(
       CLK => ck,
		 n_RST => n_rst,
		 FRB => frb,
		 BRB => brb,
		 BLB => blb,
		 FLB => flb,
		 START => start,
		 MIC => mic,
		 WRITE_MODE => write_mode,
		 CHAR_OUT => char_out,
		 VALID => valid
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
    procedure check_exp_val(sig_to_test : std_logic;
	                         exp_val : std_logic;
									 comment : string := " ") is
    begin
      if (sig_to_test /= exp_val) then
        assert false
        report "mismatch error: " & comment
        severity severity_c;
      end if;
    end check_exp_val;
	 
	 --
    -- check expected value for a std_logic_vector
    --
    procedure check_exp_val(sig_to_test : std_logic_vector(6 downto 0);
	                             exp_val : std_logic_vector(6 downto 0);
										  comment : string := " ") is
    begin
      if (sig_to_test /= exp_val) then
        assert false
        report "mismatch error: " & comment
        severity severity_c;
      end if;
    end check_exp_val;
    
    --
    -- initialize all input signals: nothing must be left floating
    --
    procedure initialize_tb is
    begin
      n_rst <= '1';
      frb <= '0';
      brb <= '0';
		blb <= '0';
      flb <= '0';
      start <= '0';
      mic <= '0';
		write_mode <= '0'; -- start off in binary mode
    end initialize_tb;
	 
	 procedure reset_tb is
    begin
		n_rst <= '1';
      wait for period_c/2;
      n_rst <= '0';
      wait for period_c/2;
      n_rst <= '1';
    end reset_tb;

	 procedure test_idle is
		variable exp_value : std_logic_vector(6 downto 0) := invalid_output;
	 begin
		wait_tb_ck;
		frb <= '0';
      brb <= '0';
		blb <= '0';
      flb <= '0';
      start <= '0';
      mic <= '0';
		wait_ck;
		wait_tb_ck;
		check_exp_val(char_out, exp_value, "char_out");
		check_exp_val(valid, '0', "valid");
		wait_ck;
	 end test_idle;
	 
    -- tests whether a one is properly written
    procedure test_binary_1 is
		variable exp_value : std_logic_vector(6 downto 0) := binary_1;
	 begin
		wait_tb_ck;
		frb <= '1';
		wait_ck;
		wait_tb_ck;
		check_exp_val(char_out, exp_value, "char_out");
		check_exp_val(valid, '1', "valid");
		
		-- reset input
		frb <= '0';
		wait_ck;
	 end test_binary_1;
	 
	 -- tests whether a zero is properly written
	 procedure test_binary_0 is
		variable exp_value : std_logic_vector(6 downto 0) := binary_0;
	 begin
		wait_tb_ck;
		flb <= '1';
		wait_ck;
		wait_tb_ck;
		check_exp_val(char_out, exp_value, "char_out");
		check_exp_val(valid, '1', "valid");
		
		-- reset input
		flb <= '0';
		wait_ck;
	 end test_binary_0;
	 
	 -- tests whether a backspace is properly written
	 procedure test_deletion is
		variable exp_value : std_logic_vector(6 downto 0) := ctrl_deletion;
	 begin
		wait_tb_ck;
		start <= '1';
		wait_ck;
		wait_tb_ck;
		check_exp_val(char_out, exp_value, "char_out");
		check_exp_val(valid, '1', "valid");
		
		-- reset input
		start <= '0';
		wait_ck;
	 end test_deletion;
	 
	 -- tests whether a left arrow keystroke is properly written
	 procedure test_left_arrow is
		variable exp_value : std_logic_vector(6 downto 0) := ctrl_left_arrow;
	 begin
		wait_tb_ck;
		blb <= '1';
		wait_ck;
		wait_tb_ck;
		check_exp_val(char_out, exp_value, "char_out");
		check_exp_val(valid, '1', "valid");
		
		-- reset input
		blb <= '0';
		wait_ck;
	 end test_left_arrow;
	 
	 -- tests whether a right arrow keystroke is properly written
	 procedure test_right_arrow is
		variable exp_value : std_logic_vector(6 downto 0) := ctrl_right_arrow;
	 begin
		wait_tb_ck;
		brb <= '1';
		wait_ck;
		wait_tb_ck;
		check_exp_val(char_out, exp_value, "char_out");
		check_exp_val(valid, '1', "valid");
		
		-- reset input
		brb <= '0';
		wait_ck;
	 end test_right_arrow;

	 -- tests whether there is proper prioritization if both FRB and FLB are hit
	 procedure test_multiple_button_presses is
		variable exp_value : std_logic_vector(6 downto 0) := binary_1;
	 begin
		wait_tb_ck;
		flb <= '1';
		frb <= '1';
		wait_ck;
		wait_tb_ck;
		check_exp_val(char_out, exp_value, "char_out");
		check_exp_val(valid, '1', "valid");
		
		-- reset input
		flb <= '0';
		frb <= '0';
		wait_ck;
	 end test_multiple_button_presses;
	 
  begin -- testbench process
  
    initialize_tb;
	 reset_tb;
	 
    -- make sure module is initialized properly
    test_idle;

    -- make sure zeros are properly encoded
    test_binary_0;

	 -- make sure module goes back to being idle
	 test_idle;
	 
    -- make sure ones are properly encoded
    test_binary_1;
	 
	 -- make sure delete key is properly encoded
	 test_deletion;
	 
	 -- make sure left arrow key is properly encoded
	 test_left_arrow;
	 
	 -- make sure right arrow key is properly encoded
	 test_right_arrow;
	 
	 -- make sure we prioritize buttons if multiple are pressed at once
	 test_multiple_button_presses;

    assert false
    report "End of Simulation"
    severity failure;


  end process test_bench;

end beh;
