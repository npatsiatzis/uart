library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_top is
	generic (
		g_sys_clk : natural := 5000;		--system clock freq. in Hz
		g_baud_rate : natural := 300;  		--baud rate in bits/s
		g_data_width : natural :=8;
		g_addr_width : natural :=2);
	port (
		--system clock and reset
		i_clk : in std_ulogic;
		i_arstn : in std_ulogic;

		--wishbone b4 (slave) interface
		i_we : in std_ulogic;
		i_stb : in std_ulogic;
		i_addr : in std_logic_vector(g_addr_width -1  downto 0); 
		i_data : in std_logic_vector(15 downto 0);
		o_data : out std_logic_vector(15 downto 0);

		--interrupts
		o_tx_done : out std_ulogic;
		o_rx_done : out std_ulogic;

		--serial input/output signals
		i_rx : in std_ulogic;
		o_tx : out std_ulogic);
end uart_top;

architecture rtl of uart_top is 
	signal w_rhr : std_logic_vector(g_data_width -1 downto 0);
	signal w_thr : std_logic_vector(g_data_width -1 downto 0);

	signal w_rbr_rd : std_ulogic;
	signal w_thr_wr : std_ulogic;
	signal w_tx_break : std_ulogic;

	signal w_data_bits : std_ulogic_vector(1 downto 0);
	signal w_parity_en : std_ulogic;
	signal w_parity_even : std_ulogic; 
	signal w_tx_breal : std_ulogic;
	signal w_stop_bits : std_ulogic_vector(1 downto 0);

	signal w_divisor : std_ulogic_vector(15 downto 0);

	signal w_overrun_err : std_ulogic;
	signal w_parity_err : std_ulogic;
	signal w_frame_err : std_ulogic;
	signal w_break_int : std_ulogic;

	signal w_thr_empty : std_ulogic;
	signal w_tempty : std_ulogic;
	signal w_thr_rd : std_ulogic;
	signal w_rx_rdy : std_ulogic;
begin
	interface : entity work.interface(rtl)
	generic map(
		g_sys_clk => g_sys_clk,
 		g_baud_rate => g_baud_rate,
 		g_data_width => g_data_width)
	port map(
		i_clk => i_clk,
		i_arstn => i_arstn,

		--Interface side
		i_addr => i_addr,
		i_data => i_data,
		i_we => i_we,
		i_stb => i_stb,
		o_data => o_data,

		--registers
		i_rhr =>w_rhr,
		o_thr => w_thr,

		--registers read/write strobes
		o_thr_wr =>w_thr_wr,

		--RX/TX control
		o_data_bits =>w_data_bits,
		o_stop_bits =>w_stop_bits,
		o_parity_en =>w_parity_en,
		o_parity_even  =>w_parity_even,
		o_tx_break =>w_tx_break,

		--RX/TX status
		i_overrun_err =>w_overrun_err,
		i_parity_err =>w_parity_err,
		i_frame_err =>w_frame_err,
		i_break_int =>w_break_int,
		i_thr_empty	=>w_thr_empty,
		i_tempty =>w_tempty,
		i_thr_rd =>w_thr_rd,
		i_rx_rdy =>w_rx_rdy,
		o_divisor => w_divisor);

	uart_tx : entity work.uart_tx(rtl)
	generic map(
		g_data_width => g_data_width)
	port map(
		--system clock and reset
		i_clk =>i_clk,
		i_arstn =>i_arstn,

		--register write strobe
		i_thr_wr =>w_thr_wr,
		--registers
		i_thr =>w_thr,

		--divisor for baud rate
		i_divisor =>w_divisor,

		--TX control information (from LineControlRegister (LCR))
		i_tx_break =>w_tx_break,
		i_parity_en =>w_parity_en,
		i_parity_even =>w_parity_even,
		i_data_bits =>w_data_bits,
		i_stop_bits =>w_stop_bits,

		--TX serial output
		o_tx =>o_tx,
		o_tx_done => o_tx_done,

		--TX status
		o_thr_empty =>w_thr_empty,
		o_tempty =>w_tempty);

	uart_rx : entity work.uart_rx(rtl)
	generic map(
		g_data_width => g_data_width)
	port map(
		--system clock and reset
		i_clk =>i_clk,
		i_arstn =>i_arstn,

		--divisor for baud rate
		i_divisor =>w_divisor,

		--serial data in
		i_rx =>i_rx,
		o_rx_done => o_rx_done,

		--register (receiver buffer register)
		o_rhr =>w_rhr,

		--RX control signals
		i_parity_en =>w_parity_en,
		i_parity_even =>w_parity_even,
		i_data_bits =>w_data_bits,

		--RX status
		o_rx_rdy =>w_rx_rdy,
		o_frame_err =>w_frame_err,
		o_parity_err =>w_parity_err,
		o_overrun_err =>w_overrun_err,
		o_break_int =>w_break_int);
end rtl;