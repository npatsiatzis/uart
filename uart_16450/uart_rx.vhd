library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_rx is 
	generic (
			g_data_width : natural :=8);
	port (
			--system clock and reset
			i_clk : in std_ulogic;
			i_arstn : in std_ulogic;

			--divisor for baud rate
			i_divisor : std_ulogic_vector(15 downto 0);

			--serial data in
			i_rx : in std_ulogic;
			--interrupt
			o_rx_done : out std_ulogic;

			--register (receiver buffer register)
			o_rbr : out std_ulogic_vector(g_data_width -1 downto 0);


			--RX control signals
			--i_tx_break : in std_ulogic;
			i_parity_en : in std_ulogic;
			i_parity_even : in std_ulogic;
			i_data_bits : in std_ulogic_vector(1 downto 0);

			--RX status
			o_rx_rdy : out std_ulogic;
			o_frame_err : out std_ulogic;
			o_parity_err : out std_ulogic;
			o_overrun_err : out std_ulogic;
			o_break_int : out std_ulogic);
end uart_rx;

architecture rtl of uart_rx is 
	signal w_divisor_half_rate : unsigned(15 downto 0);

	signal w_rbr_rdy : std_ulogic;
	signal rx_idle , rx_idle_prev : std_ulogic;

	signal w_rx_prev, w_rx_prev_prev : std_ulogic;
	signal w_frame_err, w_frame_err_prev : std_ulogic;
	signal w_parity_err, w_overrun_err, w_break_int : std_ulogic;
	signal w_frame_err_int, w_parity_err_int, w_overrun_err_int, w_break_int_int : std_ulogic;

	signal w_hunt, w_hunt_one : std_ulogic;
	signal w_sampled_once : std_ulogic;

	--RX FSM signals
	type t_state is (idle_prior_0,idle_after_0,start,shift,parity,stop);
	signal w_state, w_state_prev : t_state;
	signal w_bits_received_cnt : integer range 0 to 8;
	signal w_rsr : std_ulogic_vector(g_data_width -1 downto 0);
	signal w_baud_counter : unsigned(i_divisor'range); 

begin

	w_divisor_half_rate <= shift_right(unsigned(i_divisor),1);

	rbr_rdy_indicator : process(i_clk,i_arstn) is
	begin
		if(i_arstn = '0') then
			w_rbr_rdy <= '0';
		elsif (rising_edge(i_clk)) then
			if(rx_idle = '1' and rx_idle_prev = '0') then
				w_rbr_rdy <= '1';
			end if;
		end if; 
	end process; -- rbr_rdy_indicator

	rx_idle_indicator : process(i_clk,i_arstn) is
	begin
		if(i_arstn = '0') then
			rx_idle <= '1';
			rx_idle_prev <= '1';
		elsif (rising_edge(i_clk)) then
			rx_idle_prev <= rx_idle;
			if(w_state = idle_prior_0) then
				rx_idle <= '1';
			else
				rx_idle <= '0';
			end if;
		end if;
	end process; -- rx_idle_indicator

	--Receiver Buffer Regsiter (RBR)

	rbr_regsiter : process(i_clk,i_arstn) is
	begin
		if(i_arstn = '0') then
			o_rbr <= (others => '0');
			o_rx_done <= '0';
		elsif(rising_edge(i_clk)) then
			o_rx_done <= '0';

			if(rx_idle = '1' and rx_idle_prev = '0') then
				o_rx_done <= '1';
				case i_data_bits is 
					when "00" =>
						o_rbr <= "000" & w_rsr(7 downto 3);
					when "01" =>
						o_rbr <= "00" & w_rsr(7 downto 2);
					when "10" =>
						o_rbr <= "0" & w_rsr(7 downto 1);
					when others => 
						o_rbr <= w_rsr;
				end case;
			end if;
		end if;
	end process; -- rbr_regsiter

	register_serial_line : process(i_clk,i_arstn) is
	begin
		if(i_arstn = '0') then
			w_rx_prev <= '0';
			w_rx_prev_prev <= '0';
			w_frame_err_prev <= '1';
		elsif (rising_edge(i_clk)) then
			w_rx_prev <= i_rx;
			w_rx_prev_prev <= w_rx_prev;	
			w_frame_err_prev <= w_frame_err;
		end if;
	end process; -- register_serial_line

	error_flags : process(i_clk,i_arstn) is
	begin
		if(i_arstn = '0') then
			w_parity_err_int <= '0';
			w_frame_err_int <= '0';
			w_overrun_err_int <= '0';
			w_break_int_int <= '0';
		elsif(rising_edge(i_clk)) then
			if(rx_idle = '1' and rx_idle_prev = '0') then
				w_parity_err_int <= (w_parity_err_int or w_parity_err) and i_parity_en;
				w_frame_err_int <= w_frame_err_int or w_frame_err;
				w_overrun_err_int <= w_rbr_rdy;
				w_break_int_int <= w_break_int_int or not(w_hunt_one);						
			--elsif (i_lsr_rd = '1') then
			--	w_parity_err_int <= '0';
			--	w_frame_err_int <= '0';
			--	w_overrun_err_int <= '0';
			--	w_break_int_int <= '0';		
			end if;
		end if;
	end process; -- error_flags

	o_frame_err <= w_frame_err_int;
	o_overrun_err <= w_overrun_err_int;
	o_parity_err <=  w_parity_err_int;
	o_break_int <= w_break_int_int;
	o_rx_rdy <= w_rbr_rdy;


	hunt_proc : process(i_clk,i_arstn) is
	begin
		if(i_arstn = '0') then
			w_hunt <= '0';
		elsif (rising_edge(i_clk)) then
			if(w_state = idle_prior_0 and w_rx_prev = '0' and w_rx_prev_prev = '1') then
				w_hunt <= '1';
			elsif (w_sampled_once = '1' and w_rx_prev = '0') then
				w_hunt <= '1';
			elsif (rx_idle = '0' and w_rx_prev = '1')then
				w_hunt <= '0';
			end if;
		end if;
	end process; -- hunt_proc

	hunt_one_proce : process(i_clk,i_arstn) is
	begin
		if(i_arstn = '0') then
			w_hunt_one <= '0';
		elsif (rising_edge(i_clk)) then
			if(w_hunt = '1') then
				w_hunt_one <= '0';
			elsif (rx_idle = '0' and w_baud_counter = w_divisor_half_rate and w_rx_prev = '1') then
				w_hunt_one <= '1';
			end if;
		end if;
	end process; -- hunt_one_proce

	sampled_once_proc : process(i_clk,i_arstn) is
	begin
		if(i_arstn = '0') then

		elsif (rising_edge(i_clk)) then
			if(w_frame_err = '1' and w_frame_err_prev = '0' and w_hunt_one = '1' and w_rx_prev = '0') then
				w_sampled_once <= '1';
			else
				w_sampled_once <= '0';
			end if;
		end if;
	end process; -- sampled_once_proc


	RX_FSM : process(i_clk,i_arstn) is
	begin
		if (i_arstn = '0') then
			w_rsr <= (others => '0');
			w_bits_received_cnt <= 0;
			w_state <= idle_prior_0;
			w_baud_counter <= (others => '0');
			w_frame_err <= '0';
			w_parity_err <= '0';
		elsif (rising_edge(i_clk)) then

			case w_state is 
				when idle_prior_0 =>
					if(w_rx_prev = '0' and w_rx_prev_prev = '1') then
						w_state <= idle_after_0;
					end if;
					w_baud_counter <= unsigned(i_divisor) -1;
				when idle_after_0 =>
					if(w_baud_counter = w_divisor_half_rate) then
						if(w_rx_prev ='1') then
							w_state <= idle_prior_0;
						else
							w_rsr <= (others => '0');
							w_bits_received_cnt <= 0;
							w_frame_err <= '0';
							w_parity_err <= not(i_parity_en);
						end if;
					end if;

					if(w_baud_counter = 1) then
						w_state <= shift; 
						w_baud_counter <= unsigned(i_divisor);
					else
						w_baud_counter <= w_baud_counter -1;
					end if;
				when shift =>
					if(w_baud_counter = w_divisor_half_rate) then
						w_rsr <= w_rx_prev & w_rsr(7 downto 1);
						w_parity_err <= w_parity_err xor w_rx_prev;
						w_bits_received_cnt <= w_bits_received_cnt +1;
					end if;

					if(w_baud_counter = 1) then
						if((i_data_bits = "00" and w_bits_received_cnt = 5) 
							or (i_data_bits = "01" and w_bits_received_cnt = 6) 
							or (i_data_bits = "10" and w_bits_received_cnt = 7) 
							or (i_data_bits = "11" and w_bits_received_cnt = 8)) then
							if(i_parity_en = '1') then
								w_state <= parity;
							else
								w_state <= stop;
							end if;
						end if;
						w_baud_counter <= unsigned(i_divisor);
					else
						w_baud_counter <= w_baud_counter -1;
					end if;
				when parity =>
					if(w_baud_counter = w_divisor_half_rate) then
						if(i_parity_even = '0') then
							w_parity_err <= not (w_rx_prev);
						else
							w_parity_err <= w_rx_prev;
						end if;
					end if;

					if(w_baud_counter = 1) then
						w_state <= stop;
						w_baud_counter <= unsigned(i_divisor);
					else
						w_baud_counter <= w_baud_counter -1;
					end if;
				when stop =>
					if(w_baud_counter = w_divisor_half_rate) then
						w_frame_err <= not (w_rx_prev);
						w_state <= idle_prior_0;
					end if;
					w_baud_counter <= w_baud_counter -1;
				when others =>
					w_state <= idle_prior_0;	
			end case;
		end if;
	end process; -- RX_FSM

end rtl;