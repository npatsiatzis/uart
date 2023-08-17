library ieee;
use ieee.std_logic_1164.all;

entity uart_top_axi is
	--if there is a need for at least some of these parameters to be able to change
	--in real time, then create a configuration register that is controlled in real time 
	--via the interface.
	generic(
		g_sys_clk : natural :=40_000_000;		--system clock rate in Hz
		g_baud : natural :=256000;				--baud rate in bits/sec
		g_oversample : natural :=16; 			--oversample rate
		g_word_width : natural :=8;				--width of the data to transmit 
		g_parity_type : std_ulogic := '0';		--'0' for even parity, '1' for odd
		C_S_AXI_ADDR_WIDTH : natural := 4;
		C_S_AXI_DATA_WIDTH : natural :=32);
	port(
		--AXI4-Lite interface
		S_AXI_ACLK : in std_ulogic;
		S_AXI_ARESETN : in std_ulogic;
		--
		S_AXI_AWVALID : in std_ulogic;
		S_AXI_AWREADY : out std_ulogic;
		S_AXI_AWADDR : in std_ulogic_vector(C_S_AXI_ADDR_WIDTH -1 downto 0);
		S_AXI_AWPROT : in std_ulogic_vector(2 downto 0);
		--
		S_AXI_WVALID : in std_ulogic;
		S_AXI_WREADY : out std_ulogic;
		S_AXI_WDATA : in std_ulogic_vector(C_S_AXI_DATA_WIDTH -1 downto 0);
		S_AXI_WSTRB : in std_ulogic_vector(C_S_AXI_DATA_WIDTH/8 -1 downto 0);
		--
		S_AXI_BVALID : out std_ulogic;
		S_AXI_BREADY : in std_ulogic;
		S_AXI_BRESP : out std_ulogic_vector(1 downto 0);
		--
		S_AXI_ARVALID : in std_ulogic;
		S_AXI_ARREADY : out std_ulogic;
		S_AXI_ARADDR : in std_ulogic_vector(C_S_AXI_ADDR_WIDTH -1 downto 0);
		S_AXI_ARPROT : in std_ulogic_vector(2 downto 0);
		--
		S_AXI_RVALID : out std_ulogic;
		S_AXI_RREADY : in std_ulogic;
		S_AXI_RDATA : out std_ulogic_vector(C_S_AXI_DATA_WIDTH -1 downto 0);
		S_AXI_RRESP : out std_ulogic_vector(1 downto 0);

		o_data : out std_ulogic_vector(g_word_width -1 downto 0);	--received data

		--tx, rx serial lines
		o_tx : out std_ulogic := '1';			--transmit line
		i_rx : in std_ulogic;					--receive line
		
		--interrupts
		o_tx_busy : out std_ulogic :='0';		--uart transmit under way flag
		o_rx_busy : out std_ulogic;				--uart receive under way flag

		o_rx_error : out std_ulogic);			--error on received data(wrong parity,end etc...)
end uart_top_axi;

architecture rtl of uart_top_axi is 
	signal i_rst : std_ulogic;
	alias i_clk  : std_ulogic is S_AXI_ACLK;
	signal w_tx_reg, w_rd_data : std_ulogic_vector(g_word_width -1 downto 0);
	signal w_tx_en : std_ulogic;

begin

	i_rst <= not S_AXI_ARESETN;

	axil_regs : entity work.axil_regs(rtl)
	generic map(
		g_word_width => g_word_width
		)
	port map(
		i_clk =>i_clk,
		i_arst =>i_rst,

		S_AXI_AWVALID => S_AXI_AWVALID,
		S_AXI_AWREADY => S_AXI_AWREADY,
		S_AXI_AWADDR => S_AXI_AWADDR,
		S_AXI_AWPROT => S_AXI_AWPROT,
		--
		S_AXI_WVALID => S_AXI_WVALID,
		S_AXI_WREADY => S_AXI_WREADY,
		S_AXI_WDATA => S_AXI_WDATA,
		S_AXI_WSTRB => S_AXI_WSTRB,
		--
		S_AXI_BVALID => S_AXI_BVALID,
		S_AXI_BREADY => S_AXI_BREADY,
		S_AXI_BRESP => S_AXI_BRESP,
		--
		S_AXI_ARVALID => S_AXI_ARVALID,
		S_AXI_ARREADY => S_AXI_ARREADY,
		S_AXI_ARADDR => S_AXI_ARADDR,
		S_AXI_ARPROT => S_AXI_ARPROT,
		--
		S_AXI_RVALID => S_AXI_RVALID,
		S_AXI_RREADY => S_AXI_RREADY,
		S_AXI_RDATA => S_AXI_RDATA,
		S_AXI_RRESP => S_AXI_RRESP,

		--data read from sdram
		i_uart_rd_data =>w_rd_data,

		--ports for write regs to hierarchy
		o_tx_en => w_tx_en,
		o_tx_reg => w_tx_reg
		);

	o_data <= S_AXI_RDATA(g_word_width -1 downto 0);

	uart : entity work.uart(rtl)
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
