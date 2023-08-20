import pkg::*;
class scoreboard extends uvm_scoreboard;
  `uvm_component_utils(scoreboard)
  
  function new(string name = "", uvm_component parent);
    super.new(name,parent);
  endfunction : new
  
  uvm_tlm_analysis_fifo #(sequence_item #(G_WORD_WIDTH)) fifo_in;
  uvm_tlm_analysis_fifo #(sequence_item #(G_WORD_WIDTH)) fifo_out;

  uvm_get_port #(sequence_item #(G_WORD_WIDTH)) data_get_port;
  uvm_get_port #(sequence_item #(G_WORD_WIDTH)) result_get_port;
  
  sequence_item #(G_WORD_WIDTH) in;
  sequence_item #(G_WORD_WIDTH) out;

  function void build_phase (uvm_phase phase);
    super.build_phase(phase);
    
    fifo_in = new("fifo_in",this);
    fifo_out = new("fifo_out",this);
    
    data_get_port = new("data_get_port",this);
    result_get_port = new("result_get_port",this);
  endfunction : build_phase
  
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    data_get_port.connect(fifo_in.get_export);
    result_get_port.connect(fifo_out.get_export);
  endfunction : connect_phase
  
  function void check_phase(uvm_phase phase);
    super.check_phase(phase);

    while(result_get_port.can_get()) begin
      in  = sequence_item #(G_WORD_WIDTH)::type_id::create("in",this);
      out = sequence_item #(G_WORD_WIDTH)::type_id::create("out",this);
      
      result_get_port.try_get(out);
      data_get_port.try_get(in);
      
      if(in.i_data != out.o_data)
        `uvm_error(get_type_name(),$sformatf("FAIL i_data=0x%0h, o_data=0x%0h",in.i_data,out.o_data))
      else
        `uvm_info(get_type_name(),$sformatf("PASS i_data=0x%0h,o_data=0x%0h",in.i_data,out.o_data),UVM_LOW)
    end 
  endfunction : check_phase

  
endclass : scoreboard