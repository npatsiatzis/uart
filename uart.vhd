library ieee;
use ieee.std_logic_1164.all;

entity uart is
	generic(
		g_sys_clk : natural :=40_000_000;		--system clock rate in Hz
		g_baud : natural :=256000;				--baud rate in bits/sec
		g_oversample : natural :=16; 			--oversample rate
		g_word_width : natural :=4;				--width of the data to transmit 
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
end uart;

architecture rtl of uart is
	--counter range to create the baud frequency from the system clock
	constant range_baud : natural := g_sys_clk/g_baud -1;
	--counter range to create the oversample frequency based on system clock and baud rate
	constant range_oversample :natural := g_sys_clk/g_baud/g_oversample -1;
	--pulse signal (1 cycle) @ baud rate
	signal r_baud_pulse : std_ulogic :='0';
	--pulse signal (1 cycle) @ oversample rate
	signal r_oversample_pulse : std_ulogic := '0';

	--states of uart tx FSM
	type rx_states is (IDLE,RECEIVE);
	--states of uart rx FSM
	type tx_states is (IDLE,TRANSMIT);
	signal r_state_rx,r_state_rx_next : rx_states;
	signal r_state_tx,r_state_tx_next : tx_states;

	--signal holding the parity bit of the transmit data
	signal w_tx_parity : std_ulogic;

	--baud and oversample coutners
	signal cnt_baud : integer range 0 to range_baud;
	signal cnt_oversample : integer range 0 to range_oversample;

	--uartTX FSM signals
	signal r_tx_data : std_ulogic_vector(g_word_width -1  +3 downto 0) :=(others => '0');  
	signal cnt_digits_send : integer range 0 to g_word_width+3 ;  --count bits sent

	--uartRX FSM signals
	signal cnt_oversample_pulses : integer range 0 to g_oversample :=0;
	signal cnt_digits_received : integer range 0 to g_word_width + 2 :=0;
	--save rx_data stream including the data plus parity and end bit
	signal r_rx_data : std_ulogic_vector(g_word_width +1 downto 0);

	signal w_tx_en : std_ulogic;
	signal w_tx_reg : std_ulogic_vector(g_word_width -1 downto 0);
	signal w_rx_data : std_ulogic_vector(g_word_width -1 downto 0);

begin

	-- 					INTERFACE REGISTER MAP

	-- 			Address 		| 		Functionality
	--			   0 			|	data to tx (uart TX)
	--			   1 			|	received data (uart RX)


	
	manage_intf_regs : process(i_clk) is
	begin
		if(rising_edge(i_clk)) then
			if(i_rst = '1') then
				w_tx_en <= '0';
				w_tx_reg <= (others => '0');
			else
				o_ack <= i_stb;
				w_tx_en <= '0';
				if(i_we = '1' and i_stb = '1' and i_addr = '0') then
					w_tx_reg <= i_data;
					w_tx_en <= '1';
				elsif(i_we = '0' and i_stb = '1' and i_addr = '1') then
					o_data <= w_rx_data;
				end if;
			end if;
		end if;
	end process; -- manage_intf_regs

	--counters to create the baud rate pulse and oversample pulse
	gen_pulse : process(i_clk)
	begin
		if(rising_edge(i_clk)) then
			if(i_rst = '1') then
				cnt_baud <= 0;
				r_baud_pulse <= '0';
				cnt_oversample <= 0;
				r_oversample_pulse <= '0';
			else
				if(cnt_baud < range_baud) then
					cnt_baud <= cnt_baud +1;
					r_baud_pulse <= '0';
				else
					cnt_baud <=0;
					r_baud_pulse <= '1';
					cnt_oversample <=0;		--reset oversampling period
				end if;

				if(cnt_oversample < range_oversample) then
					cnt_oversample <= cnt_oversample +1;
					r_oversample_pulse <= '0';
				else
					cnt_oversample <=0;
					r_oversample_pulse <= '1';
				end if;
			end if;
		end if;
	end process; -- gen_pulse	


	--uart transmit FSM
	tx_next_state_logic : process(i_clk)
	begin
		if(rising_edge(i_clk)) then
			if(i_rst = '1') then
				o_tx_busy <= '0';					--tx busy; not avaiable for transmit
				r_state_tx <= IDLE;					--initialize tx FSM state
				cnt_digits_send <=0;				--initialize write pointer
				r_tx_data <= (others => '0');		--clear data to send 
				o_tx <= '1';						--keep line raised
				cnt_digits_send <= 0;
			else
				case r_state_tx is 
					when IDLE =>
						o_tx <= '1';
						--if(i_tx_en = '1') then
						if(w_tx_en = '1') then
							--include start ('0') , parity and stop ('1') bits
							r_tx_data <= '1' & w_tx_parity & w_tx_reg & '0';
							r_state_tx <= TRANSMIT;
							cnt_digits_send <=0;
							o_tx_busy <= '1';
						end if;
					when TRANSMIT =>
						--following the baud rate send each bit lsb first over the line
						if(r_baud_pulse = '1') then
							o_tx <= r_tx_data(0);				--lsb first
							o_tx_busy <= '1';
							if(cnt_digits_send < g_word_width + 2) then
								r_tx_data <= '1' & r_tx_data(r_tx_data'high downto 1);
								cnt_digits_send <= cnt_digits_send +1;
								r_state_tx <= TRANSMIT;
							else
								cnt_digits_send <=0; 			--if transmit over, goto IDLE
								r_state_tx <= IDLE;
								o_tx_busy <= '0';
								o_tx <= '1';
							end if;
						end if;
					when others =>
						o_tx_busy <= '0';
						o_tx <= '1';
						r_state_tx <= IDLE;
				end case;
			end if;
		end if;
	end process; -- tx_next_state_logic

	--single parity check code (SPC)
	--calculates an extra bit to be addded to original codeword
	--can detect one error in the transmission, cannot correct it
	parity : entity work.parity(rtl)
	generic map(
		g_width => w_tx_reg'length,
		g_parity_type => g_parity_type)
	port map(
		i_data => w_tx_reg,
		o_parity_bit => w_tx_parity);


	--uart receive FSM
	rx_next_state_logic : process(i_clk)	 
	begin
		if(rising_edge(i_clk)) then
			if(i_rst = '1') then
				o_rx_busy <= '0';					--rx busy; not avaiable to receive
				o_rx_error <= '0';					--initialize error flag
				w_rx_data <= (others => '0');
				r_rx_data <= (others => '0');		--clear received data
				r_state_rx <= IDLE;					--initialize rx state to IDLE
				cnt_digits_received <= 0;
				cnt_oversample_pulses <= 0;
			else
				case r_state_rx is 
					when IDLE =>
						--sample the line based on the oversampled baud rate
						if(r_oversample_pulse = '1') then
							--if the line is pulled low 
							if(i_rx = '0') then
								
								--sample again at the middle of the cycle to 
								--minimize the probability of metastability
								if(cnt_oversample_pulses < g_oversample/2-1) then
									cnt_oversample_pulses <= cnt_oversample_pulses +1;
									r_state_rx <= IDLE;
								else
									o_rx_busy <= '1';
									cnt_oversample_pulses <= 0;
									r_state_rx <= RECEIVE;
								end if;
							else
								o_rx_busy <= '0';
								o_rx_error <= '0';
								r_rx_data <= (others => '0');
							end if;
						end if;
					WHEN RECEIVE =>
						o_rx_busy <= '1';
						--receive based on the oversampled baud rate
						--sample values at the middle of the cycle
						--to minimize the probability of metastability
						if(r_oversample_pulse = '1') then
							if(cnt_oversample_pulses < g_oversample) then
								cnt_oversample_pulses <= cnt_oversample_pulses +1;
							else
								cnt_oversample_pulses <= 0;

								--remain in receive state until all the rx part is complete
								--including receiving the parity bit (and verifify) and the 
								--stop bit and detecting any errors during the transmission
								if(cnt_digits_received < g_word_width + 2) then
									r_rx_data <= i_rx & r_rx_data(r_rx_data'high downto 1);
									cnt_digits_received <= cnt_digits_received + 1;
									r_state_rx <= RECEIVE;
								else
									r_state_rx <= IDLE;
									cnt_digits_received <= 0;
									o_rx_busy <= '0';
									w_rx_data <= r_rx_data(r_rx_data'high-2 downto 0);
									--verify the stop bit/ detect Framing Error
									if(r_rx_data(r_rx_data'high) = '0') then
										o_rx_error <= '1';
									end if;
									--detect Parity Error
									if(xor((r_rx_data(r_rx_data'high -2 downto 0) & g_parity_type)) /= g_parity_type)then
										o_rx_error <= '1'; 
									end if;
								end if;
							end if;
						end if;
					when others =>
						o_rx_busy <= '1';
						o_rx_error <= '0';
						w_rx_data <= (others => '0');
						r_state_rx <= IDLE;
				end case;
			end if;
		end if;
	end process; -- rx_next_state_logic

end rtl;