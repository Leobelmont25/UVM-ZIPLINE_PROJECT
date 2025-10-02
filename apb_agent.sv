`include "uvm_macros.svh"
import uvm_pkg::*;

class apb_agent extends uvm_agent;
  `uvm_component_utils(apb_agent)

  apb_sequencer m_sequencer;
  apb_driver    m_driver;
  apb_monitor   m_monitor;

  virtual apb_if.mst vif_mst;
  virtual apb_if     vif_mon;

  function new(string name, uvm_component parent); super.new(name,parent); endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Garanta que o agent est?? ACTIVO (por padr??o j?? ??, mas vamos assegurar)
    if (get_is_active() == UVM_ACTIVE) begin
      m_sequencer = apb_sequencer::type_id::create("m_sequencer", this);
      m_driver    = apb_driver   ::type_id::create("m_driver", this);

      if (!uvm_config_db#(virtual apb_if.mst)::get(this,"","vif_mst",vif_mst))
        `uvm_fatal("NOVIF","apb_agent: vif_mst not set")
      uvm_config_db#(virtual apb_if.mst)::set(m_driver,"","vif",vif_mst);
    end

    m_monitor = apb_monitor::type_id::create("m_monitor", this);
    if (!uvm_config_db#(virtual apb_if)::get(this,"","vif_mon",vif_mon))
      `uvm_fatal("NOVIF","apb_agent: vif_mon not set")
    uvm_config_db#(virtual apb_if)::set(m_monitor,"","vif",vif_mon);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if (get_is_active() == UVM_ACTIVE) begin
      // >>> CONEX??O QUE FALTAVA <<<
      m_driver.seq_item_port.connect(m_sequencer.seq_item_export);
    end
  endfunction
endclass
