`include "uvm_macros.svh"
import uvm_pkg::*;

class cfg_seq extends uvm_sequence #(apb_seq_item);
  `uvm_object_utils(cfg_seq)

  string testname; // recebido via config_db
  int    max_fatals = 10;

  function new(string name="cfg_seq"); super.new(name); endfunction

task body();
  // *** DECLARA????ES PRIMEIRO ***
  string file_name, vector, op;
  int    fd, rc, str_get;
  bit [31:0] address, data;
  int    error_cntr;
  apb_seq_item tr;

  // *** IN??CIO DA L??GICA ***
  error_cntr = 0;

  if (testname == "") begin
    `uvm_warning("CFGSEQ","testname vazio; usando 'unknown'")
    testname = "unknown";
  end

  file_name = $psprintf("../tests/%s.config", testname);
  fd = $fopen(file_name, "r");
  if (fd == 0) begin
    `uvm_info("CFGSEQ", $sformatf("Arquivo %s nao encontrado; sequencia retorna.", file_name), UVM_LOW)
    return;
  end
  `uvm_info("CFGSEQ", $sformatf("Abrindo config: %s", file_name), UVM_MEDIUM)

  while (!$feof(fd)) begin
    rc = $fgets(vector, fd);
    if (rc == 0) break;

    if (vector.len() == 0 || vector[0] == "#") continue;

    str_get = $sscanf(vector, "%s 0x%h 0x%h", op, address, data);

    if (str_get == 3 && (op == "r" || op == "R" || op == "w" || op == "W")) begin
      tr = apb_seq_item::type_id::create("tr");

      if (op.tolower() == "w") begin
        tr.op   = apb_seq_item::APB_WRITE;
        tr.addr = address;
        tr.data = data;
        start_item(tr); finish_item(tr);
        if (tr.resp_err) begin
          `uvm_error("CFGSEQ", $sformatf("WRITE PSLVERR/timeout @0x%h", address))
          if (++error_cntr > max_fatals) `uvm_fatal("CFGSEQ","Muitos erros em WRITE")
        end
      end
      else begin
        tr.op   = apb_seq_item::APB_READ;
        tr.addr = address;
        tr.data = data; // esperado
        start_item(tr); finish_item(tr);
        if (tr.resp_err) `uvm_fatal("CFGSEQ", $sformatf("READ PSLVERR/timeout @0x%h", address))
        if (tr.rdata !== tr.data) begin
          `uvm_error("CFGSEQ", $sformatf("READ mismatch @0x%h got=0x%0h exp=0x%0h", address, tr.rdata, tr.data))
          if (++error_cntr > max_fatals) `uvm_fatal("CFGSEQ","Muitos erros em READ")
        end
      end
    end
    else if (op != "#") begin
      `uvm_fatal("CFGSEQ", $sformatf("Linha invalida: %s", vector))
    end
  end

  $fclose(fd);

  if (error_cntr) `uvm_error("CFGSEQ", $sformatf("Config terminou com %0d erros", error_cntr))
  else            `uvm_info ("CFGSEQ", "Config OK (sem erros)", UVM_LOW)
endtask
endclass
