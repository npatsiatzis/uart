import pkg::*;
class monitor_out extends uvm_monitor;
  `uvm_component_utils(monitor_out)
  
  uvm_analysis_port #(sequence_item #(G_WORD_WIDTH)) mon_out;
  virtual uart_intf intf;
  sequence_item #(G_WORD_WIDTH) datum;
  
  function new (string name = "", uvm_component parent);
    super.new(name,parent);
  endfunction : new
  
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    void'(uvm_resource_db#(virtual uart_intf)::read_by_name(.scope("ifs"), .name("uart_intf"), .val(intf)));
 
    mon_out = new ("mon_out",this);
  endfunction: build_phase
  
  virtual task run_phase(uvm_phase phase);
    
    forever begin
//       if(intf.o_data_valid) begin
      if(!intf.i_we && intf.i_stb && intf.i_addr == 1) begin
        datum = sequence_item #(G_WORD_WIDTH)::type_id::create("datum",this);
        @(posedge intf.i_clk);
        datum.o_data = intf.o_data;
//         `uvm_info(get_type_name(),$sformatf("MONITOR OUT  o_data=0x%0h",datum.o_data),UVM_LOW)
        mon_out.write(datum);
      end else
        @(posedge intf.i_clk);
    end 
  endtask : run_phase
  
  
endclass : monitor_out