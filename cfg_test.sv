`include "uvm_macros.svh"
import uvm_pkg::*;

class cfg_test extends uvm_test;
  `uvm_component_utils(cfg_test)

  zip_env   env;
  string    testname;

  // >>> declare aqui, no escopo da classe <<<
  cfg_seq   seq;

  function new(string name = "cfg_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = zip_env::type_id::create("env", this);
    void'(uvm_config_db#(string)::get(this, "", "testname", testname));
  endfunction

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);

    // s?? cria/usa aqui
    seq = cfg_seq::type_id::create("seq");
    seq.testname = testname;
    seq.start(env.apb.m_sequencer);

    phase.drop_objection(this);
  endtask
endclass
