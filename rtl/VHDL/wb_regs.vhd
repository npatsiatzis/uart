library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity wb_regs is
	generic(
		g_word_width : natural :=8);				--width of the data to transmit 
	port (
		i_clk : in std_ulogic;
		i_rst : in std_ulogic;

		--wishbone b4 (slave) interface
		i_we  : in std_ulogic;
		i_stb : in std_ulogic;
		i_addr : in std_ulogic;
		i_data : in std_ulogic_vector(g_word_width -1 downto 0);
		o_data : out std_ulogic_vector(g_word_width -1 downto 0);
		o_ack : out std_ulogic;

		--data read from uart rx 
		i_uart_rd_data : in std_ulogic_vector(g_word_width -1 downto 0);

		--ports for write regs to hierarchy
		o_tx_en : out std_ulogic;
		o_tx_reg : out std_ulogic_vector(g_word_width -1 downto 0)); 
end wb_regs;

architecture rtl of wb_regs is
	signal f_is_data_to_tx : std_ulogic;
	signal w_tx_reg : std_ulogic_vector(g_word_width -1 downto 0);
begin

	-- 					INTERFACE REGISTER MAP

	-- 			Address 		| 		Functionality
	--			   0 			|	data to tx (uart TX)
	--			   1 			|	received data (uart RX)


	f_is_data_to_tx <= '1' when (i_we = '1' and i_stb = '1' and i_addr = '0') else '0';

	manage_intf_regs : process(i_clk,i_rst) is
	begin
		if(i_rst = '1') then
			w_tx_reg <= (others => '0');
			o_ack <= '0';
			o_tx_en <= '0';
		elsif (rising_edge(i_clk)) then
			o_ack <= i_stb;
			o_tx_en <= '0';

			if(i_we = '1' and i_stb = '1' and i_addr = '0') then
				w_tx_reg <= i_data;
				o_tx_en <= '1';
			elsif (i_we = '0' and i_stb = '1' and i_addr = '1') then
				o_data <= i_uart_rd_data;
			end if;
		end if;
	end process; -- manage_intf_regs

	o_tx_reg <= w_tx_reg;
end rtl;