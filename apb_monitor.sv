`include "uvm_macros.svh"
import uvm_pkg::*;

class apb_monitor extends uvm_component;
  `uvm_component_utils(apb_monitor)
  virtual apb_if vif;
  uvm_analysis_port#(apb_seq_item) ap;

  function new(string name, uvm_component parent); super.new(name,parent); ap=new("ap",this); endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db#(virtual apb_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF","apb_monitor: virtual interface not set")
  endfunction

  // Passivo: observa transfer??ncias conclu??das
  task run_phase(uvm_phase phase);
    apb_seq_item tr;
    bit prev_enable;
    prev_enable = 0;
    forever begin
      @(posedge vif.clk);
      if (vif.psel && vif.penable && !prev_enable) begin
        tr = new();
        tr.addr = vif.paddr;
        tr.op   = (vif.pwrite) ? apb_seq_item::APB_WRITE : apb_seq_item::APB_READ;
        if (tr.op == apb_seq_item::APB_WRITE) tr.data = vif.pwdata;
        wait (vif.pready === 1'b1);
        if (tr.op == apb_seq_item::APB_READ)  tr.rdata = vif.prdata;
        tr.resp_err = (vif.pslverr === 1'b1);
        ap.write(tr);
      end
      prev_enable = vif.penable;
    end
  endtask
endclass
