`include "uvm_macros.svh"
import uvm_pkg::*;

class apb_driver extends uvm_driver #(apb_seq_item);
  `uvm_component_utils(apb_driver)

  virtual apb_if.mst vif;

  function new(string name, uvm_component parent); super.new(name,parent); endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db#(virtual apb_if.mst)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF","apb_driver: virtual interface not set")
  endfunction

  task apb_write(apb_seq_item tr);
    // APB2 classic: setup -> enable
    @(posedge vif.clk);
    vif.psel   <= 1'b1;
    vif.pwrite <= 1'b1;
    vif.paddr  <= tr.addr;
    vif.pwdata <= tr.data;
    vif.penable<= 1'b0;

    @(posedge vif.clk);
    vif.penable<= 1'b1;

    wait (vif.pready === 1'b1);
    tr.resp_err = (vif.pslverr === 1'b1);

    // deassert
    @(posedge vif.clk);
    vif.psel    <= 1'b0;
    vif.penable <= 1'b0;
    vif.pwrite  <= 1'b0;
  endtask

  task apb_read(apb_seq_item tr);
    @(posedge vif.clk);
    vif.psel   <= 1'b1;
    vif.pwrite <= 1'b0;
    vif.paddr  <= tr.addr;
    vif.penable<= 1'b0;

    @(posedge vif.clk);
    vif.penable<= 1'b1;

    wait (vif.pready === 1'b1);
    tr.rdata   = vif.prdata;
    tr.resp_err= (vif.pslverr === 1'b1);

    @(posedge vif.clk);
    vif.psel    <= 1'b0;
    vif.penable <= 1'b0;
  endtask

  task run_phase(uvm_phase phase);
    apb_seq_item tr;
    // idle defaults
    vif.psel    <= 0; vif.penable <= 0; vif.pwrite <= 0;
    vif.paddr   <= '0; vif.pwdata  <= '0;

    forever begin
      seq_item_port.get_next_item(tr);
      if (tr.op == apb_seq_item::APB_WRITE) apb_write(tr);
      else                                  apb_read(tr);
      seq_item_port.item_done();
    end
  endtask
endclass
