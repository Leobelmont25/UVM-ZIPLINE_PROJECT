`include "uvm_macros.svh"
import uvm_pkg::*;

class apb_seq_item extends uvm_sequence_item;
  typedef enum {APB_READ, APB_WRITE} op_e;

  rand op_e           op;
  rand bit [`N_RBUS_ADDR_BITS-1:0] addr;
  rand bit [`N_RBUS_DATA_BITS-1:0] data;       // write data or expected read data
       bit [`N_RBUS_DATA_BITS-1:0] rdata;      // actual readback (for READ)
       bit                         resp_err;   // PSLVERR/timeout

  `uvm_object_utils(apb_seq_item)

  function new(string name="apb_seq_item"); super.new(name); endfunction

  function string convert2string();
    return $sformatf("op=%s addr=0x%0h wdata=0x%0h rdata=0x%0h resp_err=%0b",
      (op==APB_WRITE)?"W":"R", addr, data, rdata, resp_err);
  endfunction
endclass
