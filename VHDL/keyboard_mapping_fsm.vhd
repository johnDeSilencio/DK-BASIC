library ieee;
use ieee.std_logic_1164.all;

-- Responible for mapping the bongo presses to keystrokes.
-- Note that this mapping is hardcoded in this module.

entity keyboard_mapping_fsm is
	port(
		CLK:			in std_logic;  -- Clock used to trigger state change
		n_RST:		in std_logic;  -- Reset used to initialize the module
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
end entity keyboard_mapping_fsm;

architecture rtl of keyboard_mapping_fsm is
	type state_t is (ready, -- another ascii character is ready to be sent
						  writing_ctrl_left_arrow,
						  writing_ctrl_right_arrow,
						  writing_ctrl_deletion,
						  writing_binary_0,
						  writing_binary_1,
	                 writing_hex_0,
						  writing_hex_1,
						  writing_hex_2,
						  writing_hex_3,
						  writing_hex_4,
						  writing_hex_5,
						  writing_hex_6,
						  writing_hex_7,
						  writing_hex_8,
						  writing_hex_9,
						  writing_hex_A,
						  writing_hex_B,
						  writing_hex_C,
						  writing_hex_D,
						  writing_hex_E,
						  writing_hex_F
					    );
						
	-- constant declaration
	constant invalid_output		: std_logic_vector(6 downto 0) := "0000000";
   constant binary_0     		: std_logic_vector(6 downto 0) := "0110000";
	constant binary_1		 		: std_logic_vector(6 downto 0) := "0110001";
	constant ctrl_right_arrow  : std_logic_vector(6 downto 0) := "0000000"; -- TODO: Define
	constant ctrl_left_arrow	: std_logic_vector(6 downto 0) := "0000000"; -- TODO: Define
	constant ctrl_deletion		: std_logic_vector(6 downto 0) := "0001000";
	
	signal state, next_state : state_t;
	signal next_char_out : std_logic_vector(6 downto 0);
	signal next_valid : std_logic;
begin
	next_state_logic : process (FRB, BRB, BLB, FLB, START, MIC, WRITE_MODE, state)
	begin
		-- default to maintaining state
		next_state <= state;
		
		case state is
			when ready =>
				-- only one character can be outputted at a time, so we
				-- explicitly prioritize the button presses here
				if (WRITE_MODE = '0') then
					-- module is in binary write mode
					if (FRB = '1') then
						next_state <= writing_binary_1;
						
						-- outputs
						next_char_out <= binary_1;
						next_valid <= '1';
					elsif (FLB = '1') then
						next_state <= writing_binary_0;
					
						-- outputs
						next_char_out <= binary_0;
						next_valid <= '1';
					elsif (BRB = '1') then
						next_state <= writing_ctrl_right_arrow;
						
						-- outputs
						next_char_out <= ctrl_right_arrow;
						next_valid <= '1';
					elsif (BLB = '1') then
						next_state <= writing_ctrl_left_arrow;
						
						-- outputs
						next_char_out <= ctrl_left_arrow;
						next_valid <= '1';
					elsif (START = '1') then
						next_state <= writing_ctrl_deletion;
						
						-- outputs
						next_char_out <= ctrl_deletion;
						next_valid <= '1';
					else
						next_state <= ready;
						
						-- outputs
						next_char_out <= invalid_output;
						next_valid <= '0';
					end if;
				else
					-- module is in hexadecimal write mode
					next_state <= state;
				end if;
			when others =>
				next_state <= ready;
				next_valid <= '0';
		end case;
	end process next_state_logic;
	
	reg_logic : process (CLK, n_RST)
	begin
		if (n_RST = '0') then
			state <= ready;
			CHAR_OUT <= invalid_output;
			VALID <= '0';
		elsif (CLK = '1' and CLK'event) then
			state <= next_state;
			CHAR_OUT <= next_char_out;
			VALID <= next_valid;
		end if;
	end process reg_logic;
end architecture rtl;