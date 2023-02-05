library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity interface is
	generic (
	 		g_sys_clk : natural;
	 		g_baud_rate : natural;
	 		g_data_width : natural :=8); 
	port (
			--sytem clock and reset
			i_clk : in std_ulogic;
			i_arstn : in std_ulogic;

			--Interface side
			i_addr : in std_ulogic_vector(2 downto 0);
			i_data : in std_ulogic_vector(15 downto 0);
			i_we : in std_ulogic;
			o_data : out std_ulogic_vector(15 downto 0);

			--registers
			i_rbr : in std_ulogic_vector(g_data_width-1 downto 0);
			--i_lsr : in std_ulogic_vector(6 downto 0);
			o_thr : out std_ulogic_vector(g_data_width-1 downto 0);

			--registers read/write strobes
			o_rbr_rd : out std_ulogic;
			o_thr_wr : out std_ulogic;
			--o_lsr_rd : out std_ulogic;

			--RX/TX control
			o_data_bits : out std_ulogic_vector(1 downto 0);
			o_stop_bits : out std_ulogic_vector(1 downto 0);
			o_parity_en : out std_ulogic;
			o_parity_even : out std_ulogic;
			o_tx_break : out std_ulogic;

			--RX/TX status
			i_overrun_err : in std_ulogic;
			i_parity_err : in std_ulogic;
			i_frame_err : in std_ulogic;
			i_break_int : in std_ulogic;
			i_thr_empty	: in std_ulogic;
			i_tempty: in std_ulogic;
			i_thr_rd : in std_ulogic;
			i_rx_rdy : in std_ulogic;
			o_divisor : out std_ulogic_vector(15 downto 0));
end interface;

architecture rtl of interface is
	constant c_divisor : natural range 0 to 2**16 -1:= (g_sys_clk)/g_baud_rate;
	constant DIVISOR : std_ulogic_vector(2 downto 0) := "111";
	constant THR : std_ulogic_vector(2 downto 0) := "000";
	constant RBR : std_ulogic_vector(2 downto 0) :="000";
	constant LSR : std_ulogic_vector(2 downto 0) :="101";
	constant LCR : std_ulogic_vector (2 downto 0) := "011";

	signal w_div_wr : std_ulogic;
	signal w_thr_wr : std_ulogic;
	signal w_rbr_rd : std_ulogic;
	signal w_lsr_rd : std_ulogic;
	signal w_data : std_ulogic_vector(7 downto 0);
	signal w_thr : std_ulogic_vector(g_data_width -1 downto 0);
	signal w_lcr : std_ulogic_vector(6 downto 0);

begin
	w_div_wr <= '1'  when (i_we = '1' and i_addr = DIVISOR) else '0';

	divisor_proc : process(i_clk,i_arstn) is
	begin
		if(i_arstn = '0') then
			o_divisor <= std_ulogic_vector(to_unsigned(c_divisor,o_divisor'length));
		elsif (rising_edge(i_clk)) then
			if(w_div_wr = '1') then
				o_divisor <= i_data;
			end if;
		end if;
	end process; -- divisor_proc

	w_thr_wr <= '1' when (i_we = '1' and i_addr = THR) else '0';
	w_rbr_rd <= '1' when (i_we ='0' and i_addr = RBR)  else '0';
	w_lsr_rd <= '1' when (i_we = '0' and i_addr = LSR) else '0';

	thw_rw_proc : process(i_clk,i_arstn) is
	begin
		if(i_arstn = '0') then
			o_thr_wr <= '0';
		elsif(rising_edge(i_clk)) then
			o_thr_wr <= w_thr_wr;
		end if;
	end process; -- thw_rw_proc
	
	o_rbr_rd <= w_rbr_rd;

	o_data <= std_ulogic_vector(to_unsigned(0,8)) & w_data;

	o_data_proc : process(i_clk,i_arstn) is
	begin
		if(i_arstn = '0') then
			w_data <= (others => '0');
		elsif(rising_edge(i_clk)) then
			if(i_we = '0') then
				case i_addr(2 downto 0) is 
					when RBR => 
						w_data <= i_rbr;
					--when LSR =>
					--	o_data <= "0" & i_lsr;
					when others =>
						w_data <= (others => '1');
				end case;
			end if;
		end if;
	end process; -- o_data_proc

	o_thr <= w_thr;

	regs_proc : process(i_clk,i_arstn) is
	begin
		if(i_arstn = '0') then
			w_thr <= (others => '0');
			w_lcr <= (others => '0');
		elsif (rising_edge(i_clk)) then
			if(i_we = '1') then
				case i_addr(2 downto 0) is 
					when THR =>
						w_thr <= i_data(7 downto 0);
					when LCR =>
						w_lcr <= i_data(6 downto 0);
					when others =>
						null;
				end case;
			end if;
		end if;
	end process; -- regs_proc


	o_data_bits <= w_lcr(1 downto 0); 
	o_stop_bits <= "00" when (w_lcr(2) = '0') else
					"01" when (w_lcr(2 downto 0) = "100") else
					"10";	
	o_parity_en <=  w_lcr(3);
	o_parity_even <= w_lcr(4);
	o_tx_break <= w_lcr(6);
end rtl;