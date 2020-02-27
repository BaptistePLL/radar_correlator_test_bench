
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.all;

--/////////////////////
--    BANC TEST
--/////////////////////


entity banc_test is generic( N_pile: integer := 8);
port(reset, clk, clke : in std_logic;
     correll : out std_logic_vector (20 downto 0));
end banc_test;

architecture arch_banc_test of banc_test is
	signal ref : std_logic;
	signal data : std_logic_vector(N_pile-1 downto 0);
begin

stimul: entity stimulateur port map(
				clke => clke,
				reset => reset,
				d_out => data,
				ref => ref);

correl: entity correlateur port map(
                     		clk => clk,
                    		clke => clke,
                   		reset => reset,
                   		ref => ref,
                    		d_in => data,
                    		correll => correll);

end arch_banc_test;



