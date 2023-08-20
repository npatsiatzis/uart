import pkg::*;
class rand_sequence extends uvm_sequence;
  `uvm_object_utils(rand_sequence)
  
  sequence_item #(G_WORD_WIDTH) sa_tx;
  covergroup cg;
    data:   coverpoint sa_tx.i_data;
    // wr:   coverpoint sa_tx.i_wr;
    // data_wr : cross data,wr;
  endgroup: cg
  
  function new(string name = "");
    super.new(name);
    cg = new();
  endfunction 
  
  task body();
    

    while(cg.get_coverage != 100.0) begin
      sa_tx = sequence_item #(G_WORD_WIDTH)::type_id::create("sa_tx");
      start_item(sa_tx);
      assert(sa_tx.randomize());
      cg.sample();
      finish_item(sa_tx);
      `uvm_info(get_type_name(), $sformatf("Current Coverage = %0f", cg.get_coverage()), UVM_LOW)
    end
  endtask
  
  function void report_phase(uvm_phase phase);
    `uvm_info(get_type_name(), $sformatf("Current Coverage = %0f", cg.get_coverage()), UVM_LOW)
  endfunction: report_phase
  
endclass : rand_sequence