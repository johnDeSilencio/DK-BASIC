library ieee;
use ieee.std_logic_1164.all;

entity open_collector_encoder is
	port(
        CLK:        in std_logic;
		DIN:		in std_logic;
		DOUT:		out std_logic
	);
end entity open_collector_encoder;

architecture rtl of open_collector_encoder is

	-- bidirectional serial data line has pull-up resistor,
	-- so we use NPN transistor to pull the line low for a zero,
	-- and disconnect from data line when "writing" a one
	constant BIT_ZERO : std_logic := '1';
	constant BIT_ONE  : std_logic := '0';
	constant HIGH_IMPEDANCE : std_logic := '0';

begin
	process (CLK, DIN)
	begin
        if (CLK = '1' and CLK'event) then
            if (DIN = '0') then
                DOUT <= BIT_ZERO;
            elsif (DIN = '1') then
                DOUT <= BIT_ONE;
            elsif (DIN = 'Z') then
                DOUT <= HIGH_IMPEDANCE;
            end if;
        end if;
	end process;
end architecture rtl;