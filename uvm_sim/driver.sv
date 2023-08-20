import pkg::*;
class driver extends uvm_driver #(sequence_item #(pkg::G_WORD_WIDTH));
  `uvm_component_utils(driver)
  
  virtual uart_intf intf;
  
  function new (string name = "", uvm_component parent);
    super.new(name,parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    void'(uvm_resource_db#(virtual uart_intf)::read_by_name(.scope("ifs"), .name("uart_intf"), .val(intf)));
  endfunction
  
  virtual task reset_phase(uvm_phase phase);
    phase.raise_objection(this);
    intf.i_rst = 1'b1;
    
    repeat(5)
      @(posedge intf.i_clk)
    intf.i_rst = 1'b0;

    phase.drop_objection(this);
  endtask: reset_phase 
  
 
  virtual task run_phase(uvm_phase phase);
    sequence_item #(pkg::G_WORD_WIDTH) req_item;
    
    forever begin
      if(!intf.i_rst) begin
        seq_item_port.get_next_item(req_item);
        intf.i_we = 1;
        intf.i_stb = 1;
        intf.i_addr = 0;
        intf.i_data = req_item.i_data;
        @(posedge intf.i_clk);
        

        intf.i_we = 1;
        intf.i_stb = 0;
        intf.i_addr = 0;
        intf.i_data = req_item.i_data;
        @(posedge intf.i_clk);

        while(!(!intf.o_rx_busy && intf.f_rx_busy_prev)) begin
//           `uvm_info(get_type_name(),$sformatf("DRIVER rx_busy=0x%0h rx_busy_prev=0x%oh",intf.o_rx_busy,intf.f_rx_busy_prev),UVM_LOW)
          
//           `uvm_info(get_type_name(),$sformatf("DRIVER we=0x%0h stb=0x%oh, addr=0x%oh, o_data_valid =0x%oh",intf.i_we,intf.i_stb,intf.i_addr,intf.o_data_valid),UVM_LOW)
          intf.i_we = 1;
          intf.i_stb = 0;
          intf.i_addr = 0;
          intf.i_data = req_item.i_data;
          @(posedge intf.i_clk);
        end
        
        intf.i_we = 0;
        intf.i_stb = 1;
        intf.i_addr = 1;
        intf.i_data = req_item.i_data;
        @(posedge intf.i_clk);

        seq_item_port.item_done();
      end else
        @(posedge intf.i_clk);
    end 
  endtask
  
endclass : driver
