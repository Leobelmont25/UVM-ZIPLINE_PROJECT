`include "uvm_macros.svh"
import uvm_pkg::*;

class apb_scoreboard extends uvm_component;
  `uvm_component_utils(apb_scoreboard)

  // Em vez de export, use IMP (implementa????o do write)
  uvm_analysis_imp#(apb_seq_item, apb_scoreboard) ap_imp;
  int error_cnt;

  function new(string name, uvm_component parent);
    super.new(name,parent);
    ap_imp = new("ap_imp", this);
  endfunction

  // Recebe itens do monitor
  function void write(apb_seq_item tr);
    `uvm_info("APB_MON", $sformatf("Observed: %s", tr.convert2string()), UVM_LOW)
    // (aqui depois voc?? pode comparar com um predictor, etc.)
  endfunction
endclass
