import pkg::*;
class env extends uvm_env;
  `uvm_component_utils(env)
  
  uvm_sequencer #(sequence_item #(G_WORD_WIDTH)) seqr;
  driver drv;
  monitor_out res_mon;
  monitor_in data_mon;
  scoreboard scb;
    
  function new (string name = "", uvm_component parent);
    super.new(name,parent);
  endfunction : new
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    seqr = uvm_sequencer #(sequence_item #(G_WORD_WIDTH))::type_id::create("seqr",this);

    drv = driver::type_id::create("drv",this);
    res_mon = monitor_out::type_id::create("res_mon",this);
    data_mon = monitor_in::type_id::create("data_mon",this);
    scb = scoreboard::type_id::create("scb",this);
  endfunction : build_phase
  
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    drv.seq_item_port.connect(seqr.seq_item_export);
    data_mon.mon_in.connect(scb.fifo_in.analysis_export);
    res_mon.mon_out.connect(scb.fifo_out.analysis_export);
  endfunction : connect_phase
  
endclass : env