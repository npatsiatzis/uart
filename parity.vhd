--Parity bit calculation depending on input data and generic even/odd parity type.

library ieee;
use ieee.std_logic_1164.all;

entity parity is
	generic(
		g_width : natural :=8;
		g_parity_type : std_ulogic := '0');
	port(
		i_data : in std_ulogic_vector(g_width-1 downto 0);
		o_parity_bit : out std_ulogic);
end parity;

architecture rtl of parity is
	signal data_parity : std_ulogic;
begin
	parity_calc : process(all)
	begin
		data_parity <= xor i_data;
		o_parity_bit <= g_parity_type xor data_parity;
	end process; -- parity_calc
end rtl;