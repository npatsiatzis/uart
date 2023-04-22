library ieee;
use ieee.std_logic_1164.all;

entity uart_top is
	--if there is a need for at least some of these parameters to be able to change
	--in real time, then create a configuration register that is controlled in real time 
	--via the interface.
	generic(
		g_sys_clk : natural :=40_000_000;		--system clock rate in Hz
		g_baud : natural :=256000;				--baud rate in bits/sec
		g_oversample : natural :=16; 			--oversample rate
		g_word_width : natural :=8;				--width of the data to transmit 
		g_parity_type : std_ulogic := '0');		--'0' for even parity, '1' for odd
	port(
		i_clk : in std_ulogic;					--system clock
		i_rst : in std_ulogic;

		--wishbone b4 (slave) interface
		i_we : in std_ulogic; 
		i_stb : in std_ulogic;
		i_addr : in std_ulogic;
		i_data : in std_ulogic_vector(g_word_width -1 downto 0);	--data to transmit
		o_ack : out std_ulogic;
		o_data : out std_ulogic_vector(g_word_width -1 downto 0);	--received data

		--tx, rx serial lines
		o_tx : out std_ulogic := '1';			--transmit line
		i_rx : in std_ulogic;					--receive line
		
		--interrupts
		o_tx_busy : out std_ulogic :='0';		--uart transmit under way flag
		o_rx_busy : out std_ulogic;				--uart receive under way flag

		o_rx_error : out std_ulogic);			--error on received data(wrong parity,end etc...)
end uart_top;

architecture rtl of uart_top is 
	signal w_tx_reg, w_rd_data : std_ulogic_vector(g_word_width -1 downto 0);
	signal w_tx_en : std_ulogic;
begin
	wb_regs : entity work.wb_regs(rtl)
	generic map(
		g_word_width => g_word_width
		)
	port map(
		i_clk =>i_clk,
		i_rst =>i_rst,

		--wishbone b4 (slave) interface
		i_we  =>i_we,
		i_stb =>i_stb,
		i_addr =>i_addr,
		i_data =>i_data,
		o_data =>o_data,
		o_ack => o_ack,

		--data read from sdram
		i_uart_rd_data =>w_rd_data,

		--ports for write regs to hierarchy
		o_tx_en => w_tx_en,
		o_tx_reg => w_tx_reg
		);

	uart: entity work.uart(rtl)
	generic map(
		g_sys_clk => g_sys_clk,
		g_baud => g_baud,
		g_oversample => g_oversample,
		g_word_width => g_word_width,
		g_parity_type => g_parity_type
		)
	port map(
		i_clk =>i_clk,					
		i_rst =>i_rst,

		i_tx_en => w_tx_en,
		i_data => w_tx_reg,
		o_data =>w_rd_data,

		--tx, rx serial lines
		o_tx =>o_tx,
		i_rx =>i_rx,					
		
		--interrupts
		o_tx_busy => o_tx_busy,
		o_rx_busy => o_rx_busy,

		o_rx_error => o_rx_error
		);
end rtl;
