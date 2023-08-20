import pkg::*;
class monitor_in extends uvm_monitor;
  `uvm_component_utils(monitor_in)
  
  uvm_analysis_port #(sequence_item #(G_WORD_WIDTH)) mon_in;
  sequence_item #(G_WORD_WIDTH) datum;
  virtual uart_intf intf;
  
  function new (string name = "", uvm_component parent);
    super.new(name,parent);
  endfunction : new
  
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    void'(uvm_resource_db#(virtual uart_intf)::read_by_name(.scope("ifs"), .name("uart_intf"), .val(intf)));
    
 
    mon_in = new ("mon_in",this);
  endfunction: build_phase
  
  virtual task run_phase(uvm_phase phase);
    forever begin
      if(intf.i_we && intf.i_stb && intf.i_addr == 0) begin
        datum = sequence_item #(G_WORD_WIDTH)::type_id::create("datum",this);
        datum.i_data = intf.i_data;
        `uvm_info(get_type_name(),$sformatf("MONITOR IN  i_data=0x%0h",datum.i_data),UVM_LOW)
        mon_in.write(datum);
        @(posedge intf.i_clk);
      end else
        @(posedge intf.i_clk);
    end 
  endtask : run_phase
  
  
endclass : monitor_in