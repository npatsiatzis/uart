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
			i_addr : in std_ulogic;
			i_data : in std_ulogic_vector(15 downto 0);
			i_we : in std_ulogic;
			i_stb : in std_ulogic;
			o_data : out std_ulogic_vector(15 downto 0);
			o_ack : out std_ulogic;

			--registers
			i_rhr : in std_ulogic_vector(g_data_width-1 downto 0);
			--i_lsr : in std_ulogic_vector(6 downto 0);
			o_thr : out std_ulogic_vector(g_data_width-1 downto 0);

			--registers read/write strobes
			o_thr_wr : out std_ulogic;

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
	constant c_divisor : natural range 0 to 2**16 -1:= (g_sys_clk)/(g_baud_rate);

	--interface registers addresses

	constant DIVISOR : std_ulogic := '0';
	--transmitter holding register
	--the user writes in this write only location the data the data to be sent through the serial channel
	--NOTE that the DLAB bit (MSB) of the line control register must be '0'.
	--NOTE that if a character less than 8 bits is to be transmitted, in must be right-justified.
	constant THR : std_ulogic := '0';
	--received holding register
	--the user can get the data received through the serial channel by reading this register
	--NOTE that the DLAB bit (MSB) of the line control register must be '0'.
	constant RHR : std_ulogic :='0';
	--line control register
	--this register controls the asynchronnous data communication format, i.e. the character framing, 
	--namely the word length of the data frame, the existence and type of parity, 
	--the length of the stop bit(s), break condition enforcement, divisor register (MSB of lcr) enable
	constant LCR : std_ulogic := '1';

	signal w_data : std_ulogic_vector(7 downto 0);
	--divisor register
	signal w_divisor : std_ulogic_vector(15 downto 0);
	--transmit holding register
	signal w_thr : std_ulogic_vector(g_data_width -1 downto 0);
	--line control register
	signal w_lcr : std_ulogic_vector(7 downto 0);

	alias w_dlab : std_ulogic is w_lcr(7);

begin

		-- 					REGISTER MAP

	--				REGISTERS ACCESSIBLE WHEN DLAB = 0
	-- 			Address 		| 		Functionality
	--			   0 			|(W)	transmit holding register (character to be transmitted)
	--			   0 			|(R)	receiver holding register (character received)
	--			   1 			|		line control register (configuration information)

	--			REGISTERS ACCESSIBLE WHEN DLAB = 1
	--			   0  			|		divisor register (for baud rage generation)


	manage_intf_regs : process(i_clk,i_arstn) is
	begin
		if(i_arstn = '0') then
			w_divisor <= std_ulogic_vector(to_unsigned(c_divisor,w_divisor'length));
			w_thr <= (others => '0');
			w_lcr <= (others => '0');

			o_thr_wr <= '0';
		elsif (rising_edge(i_clk)) then
			o_ack <= i_stb;
			o_thr_wr <= '0';

			if(w_dlab = '0' and  i_we = '1' and i_stb = '1') then 
				case i_addr is 
					when THR =>
						w_thr <= i_data(7 downto 0);
						o_thr_wr <= '1';
					when LCR =>
						w_lcr <= i_data(7 downto 0);
					when others => 
				end case;
			elsif(w_dlab = '1' and i_we = '1' and i_stb = '1' and i_addr = DIVISOR) then
				w_divisor <= i_data;
			end if;	
		end if;
	end process; -- manage_intf_regs

	o_data <= std_ulogic_vector(to_unsigned(0,8)) & w_data;
	
	o_data_proc : process(i_clk,i_arstn) is
	begin
		if(i_arstn = '0') then
			w_data <= (others => '0');
		elsif(rising_edge(i_clk)) then
			if(w_dlab = '0' and  i_stb = '1' and i_we = '0') then
				case i_addr is 
					when RHR => 
						w_data <= i_rhr;
					when others =>
						w_data <= (others => '1');
				end case;
			end if;
		end if;
	end process; -- o_data_proc

	o_divisor <= w_divisor;
	o_thr <= w_thr;


	o_data_bits <= w_lcr(1 downto 0); 
	o_stop_bits <= "00" when (w_lcr(2) = '0') else
					"01" when (w_lcr(2 downto 0) = "100") else
					"10";	
	o_parity_en <=  w_lcr(3);
	o_parity_even <= w_lcr(4);
	o_tx_break <= w_lcr(6);
end rtl;