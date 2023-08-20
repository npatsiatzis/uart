`include "uvm_macros.svh"
`include "pkg.sv"
`include "testbench_pkg.sv"

module tb_top;
  import uvm_pkg::*;
  import pkg::*;
  import testbench_pkg::*;
  
  uart_intf #(.G_WORD_WIDTH(pkg::G_WORD_WIDTH)) intf();
  uart_top 
  #
  (
    .G_SYS_CLK(pkg::G_SYS_CLK),
    .G_BAUD(pkg::G_BAUD),
    .G_OVERSAMPLE(pkg::G_OVERSAMPLE),
    .G_WORD_WIDTH(pkg::G_WORD_WIDTH),
    .G_PARITY_TYPE(pkg::G_PARITY_TYPE)
  )	
  dut 
  (
    .i_clk(intf.i_clk),
    .i_rst(intf.i_rst),
    .i_we(intf.i_we),
    .i_stb(intf.i_stb),
    .i_addr(intf.i_addr),
    .i_data(intf.i_data),
    .o_ack(intf.o_ack),
    .o_data(intf.o_data),
    .o_tx(intf.o_tx),
    .i_rx(intf.i_rx),
    .o_tx_busy(intf.o_tx_busy),
    .o_rx_busy(intf.o_rx_busy),
    .f_rx_busy_prev(intf.f_rx_busy_prev),
    .o_rx_error(intf.o_rx_error),
    .o_data_valid( intf.o_data_valid)
  );
  

 
  initial begin
    //Registers the Interface in the configuration block
    //so that other blocks can use it
    uvm_resource_db#(virtual uart_intf)::set(.scope("ifs"), .name("uart_intf"), .val(intf));

    //Executes the test
    run_test("test");
  end
  
  //Variable initialization
  initial begin
    intf.i_clk = 1'b1;
    // Dump waves
    $dumpfile("dump.vcd");
    $dumpvars(0, tb_top);
  end

  //Clock generation
  always begin
    #5 intf.i_clk = ~intf.i_clk;
  end 
  
endmodule : tb_top