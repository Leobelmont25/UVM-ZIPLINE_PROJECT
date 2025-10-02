`include "uvm_macros.svh"
import uvm_pkg::*;

class zip_env extends uvm_env;
  `uvm_component_utils(zip_env)
  apb_agent       apb;
  apb_scoreboard  scb;

  function new(string name, uvm_component parent); super.new(name,parent); endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    apb = apb_agent      ::type_id::create("apb", this);
    scb = apb_scoreboard ::type_id::create("scb", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    apb.m_monitor.ap.connect(scb.ap_imp);
  endfunction
endclass
