class test extends uvm_test;
  `uvm_component_utils(test)
  
  env environment;
  rand_sequence seq;
  
      
  function new (string name = "", uvm_component parent);
    super.new(name,parent);
  endfunction : new
  
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    environment = env::type_id::create("env",this);
  endfunction : build_phase
  
  task run_phase(uvm_phase phase);
    seq = rand_sequence::type_id::create("seq",this);
    phase.raise_objection(this);
    seq.start(environment.seqr);
    
    phase.phase_done.set_drain_time(this, 50ns);
    phase.drop_objection(this);
      
  endtask : run_phase 
  
endclass : test