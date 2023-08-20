class sequence_item #(parameter int G_WORD_WIDTH = 4) extends uvm_sequence_item;
  `uvm_object_utils(sequence_item #(G_WORD_WIDTH))
  
  rand logic [G_WORD_WIDTH-1:0] i_data;
  logic i_we;
  logic i_stb;
  logic i_addr;
  logic [G_WORD_WIDTH-1:0] o_data;
  logic o_rx_error;
  
  function new(string name = "");
    super.new(name);
  endfunction : new
  
endclass : sequence_item