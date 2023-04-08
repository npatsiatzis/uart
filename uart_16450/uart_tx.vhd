library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_tx is
	generic(
		g_data_width : natural :=8);				--width of the data to transmit	
	port(
		--system clock and reset
		i_clk : in std_ulogic;						--system clock
		i_arstn : in std_ulogic;

		--register write strobe
		i_thr_wr : in std_ulogic;
		--registers
		i_thr : in std_ulogic_vector(g_data_width-1 downto 0);

		--divisor for baud rate
		i_divisor : std_ulogic_vector(15 downto 0);

		--TX control information (from LineControlRegister (LCR))
		i_parity_en : in std_ulogic;
		i_tx_break : in std_ulogic;
		i_parity_even : in std_ulogic;
		i_data_bits : in std_ulogic_vector(1 downto 0);
		i_stop_bits : in std_ulogic_vector(1 downto 0);

		--TX serial output
		o_tx : out std_ulogic;

		--interrupt
		o_tx_done : out std_ulogic;

		--TX status
		o_thr_empty : out std_ulogic;
		o_tempty : out std_ulogic);

end uart_tx;

architecture rtl of uart_tx is
	signal w_divisor_half_rate : unsigned(15 downto 0);
	signal w_thr_empty : std_ulogic;
	signal w_tsr_empty : std_ulogic;

	--in shift/stop state indicators
	signal w_in_shift, w_in_shift_prev : std_ulogic;
	signal w_in_stop, w_in_stop_prev : std_ulogic;

	--TX FSM signals 
	type t_state is (idle,start,shift,parity,stop_1bit,stop_halfbit,stop_2bit);
	signal w_state : t_state;
	signal w_cnt_bits_sent : integer range 0 to 8;
	signal w_baud_counter : unsigned(i_divisor'range);
	signal w_tx : std_ulogic;
	signal w_parity : std_ulogic;
	signal w_tsr : std_ulogic_vector(g_data_width -1 downto 0);

	--signlas that help with verification
	signal f_state_prev : t_state;

begin
	w_divisor_half_rate <= shift_right(unsigned(i_divisor),1);

	thr_tsr_empty : process(i_clk,i_arstn) is
	begin
		if(i_arstn = '0') then
			w_thr_empty <= '1';
			w_tsr_empty <= '1';
		elsif (rising_edge(i_clk)) then
			if(i_thr_wr = '1') then
				w_thr_empty <= '0';
			elsif (w_in_shift = '1' and w_in_shift_prev = '0') then
				w_thr_empty <= '1';
			end if;

			if(w_in_stop = '0' and w_in_stop_prev = '1') then
				w_tsr_empty <= '0';
			elsif(w_in_stop = '1' and w_in_stop_prev = '0') then
				w_tsr_empty <= '1';
			end if;
		end if;
	end process; -- thr_tsr_empty

	reg_shift_stop_state : process(i_clk,i_arstn) is
	begin
		if(i_arstn = '0') then
			w_in_stop_prev <= '0';
			w_in_stop_prev <= '0';
		elsif(rising_edge(i_clk)) then
			w_in_shift_prev <= w_in_shift;
			w_in_stop_prev <= w_in_stop;
		end if;
	end process; -- reg_shift_stop_state

	in_shift_stop_proc : process(i_clk,i_arstn) is
	begin
		if(i_arstn = '0') then
			w_in_shift <= '0';
			w_in_stop <= '0';
		elsif(rising_edge(i_clk)) then
			if(w_state <= shift) then
				w_in_shift <= '1';
			end if;

			if(w_state <= stop_1bit) then
				w_in_stop <= '1';
			end if;
		end if;
	end process; -- in_shift_stop_proc

	o_thr_empty <= w_thr_empty;
	o_tempty <= '1' when (w_thr_empty = '1' and w_tsr_empty = '1') else '0';


	o_tx <= w_tx when (i_tx_break = '0') else '0';


	TX_FSM : process(i_clk,i_arstn) is
	begin
		if(i_arstn = '0') then
			w_cnt_bits_sent <= 0;
			w_state <= idle;
			w_tsr <= (others => '0');
			w_tx <= '1';
			w_parity <= '1';
			w_baud_counter <=  (others => '0');
		elsif (rising_edge(i_clk)) then
			f_state_prev <= w_state;
			case w_state is 
				when idle =>
				--if thr is not empty, copy its contents to tsr
				--tsr then shifts the data out to the serial out (tx) pin
					if(w_thr_empty = '0') then
						w_state <= start;
					end if;
				when start =>
					if(w_baud_counter = 0) then
						w_baud_counter <= unsigned(i_divisor)-1;
					elsif(w_baud_counter = 1) then
						w_baud_counter <= (others => '0');
						w_tsr <= i_thr;
						w_cnt_bits_sent <= 0;
						w_parity <= not(i_parity_even);
						w_state <= shift;
					else
						w_baud_counter <= w_baud_counter -1;						
					end if;
					w_tx <= '0';
				when shift =>
					w_tx <= w_tsr(0);
					if(w_baud_counter = 0) then
						w_baud_counter <= unsigned(i_divisor)-1;
					elsif (w_baud_counter = 1) then
						w_baud_counter <= (others => '0');
						w_tsr <= '0' & w_tsr(7 downto 1);
						w_cnt_bits_sent <= w_cnt_bits_sent +1;
						w_parity <= w_parity xor w_tsr(0);
						if((i_data_bits = "00" and w_cnt_bits_sent = 4) 
							or (i_data_bits = "01" and w_cnt_bits_sent = 5) 
							or (i_data_bits = "10" and w_cnt_bits_sent = 6) 
							or (i_data_bits = "11" and w_cnt_bits_sent = 7)) then
								if(i_parity_en = '1') then
									w_state <= parity;
								else
									w_state <= stop_1bit;
								end if;
						end if;
					else
						w_baud_counter <= w_baud_counter -1;
					end if;
				when parity =>
					if(w_baud_counter = 0) then 
						w_baud_counter <= unsigned(i_divisor)-1;
					elsif (w_baud_counter = 1) then
						w_baud_counter <= (others => '0');
						w_state <= stop_1bit;
					else
						w_baud_counter <= w_baud_counter -1;		
					end if;
					w_tx <= w_parity;
				when stop_1bit =>
						if(w_baud_counter = 0) then
							w_baud_counter <= unsigned(i_divisor)-1;
						elsif(w_baud_counter = 1) then
							w_baud_counter <= (others => '0');
							if(i_stop_bits = "00") then
								w_state <= idle;
							elsif(i_stop_bits = "01") then
								w_state <= stop_halfbit;
							else
								w_state <= stop_2bit;
							end if;
						else
							w_baud_counter <= w_baud_counter -1;
						end if;
						w_tx <= '1';
				when stop_halfbit =>
					if(w_baud_counter = 0) then
						w_baud_counter <= unsigned(i_divisor)-1;
					elsif (w_baud_counter = 1) then
						w_baud_counter <= (others => '0');
						w_state <= idle;
					else
						w_baud_counter <= w_baud_counter -1;
					end if;
						w_tx <= '1';
				when stop_2bit =>
					if(w_baud_counter = 0) then
						w_baud_counter <= w_divisor_half_rate;
					elsif(w_baud_counter = 1) then
						w_baud_counter <= (others => '0');
						w_state <= idle;
					else
						w_baud_counter <= w_baud_counter -1;
					end if;
					w_tx <= '1';
				when others =>
					w_state <= idle;
			end case;
		end if;		
	end process; -- TX_FSM

	o_tx_done <= '1' when (w_state = idle and (f_state_prev = stop_1bit or f_state_prev = stop_2bit or f_state_prev = stop_halfbit)) else '0';

end rtl;