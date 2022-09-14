library ieee;
use ieee.std_logic_1164.all;

entity divide_by_50_clock_divider is
    port(
        n_RST:      in std_logic;
        CLK_IN:     in std_logic;
        CLK_OUT:    out std_logic
    );
end entity divide_by_50_clock_divider;

architecture rtl of divide_by_50_clock_divider is
begin
    process (CLK_IN, n_RST)
        variable counter : integer range 0 to 49;
    begin
        if (n_RST = '0') then
            counter := 0;
        elsif (CLK_IN = '1' and CLK_IN'event) then
            if (counter = 0) then
                CLK_OUT <= '1';
                counter := 49;
            elsif (counter = 25) then
                CLK_OUT <= '0';
                counter := counter - 1;
            else
                counter := counter - 1;
            end if;
        end if;
    end process;
end architecture rtl;