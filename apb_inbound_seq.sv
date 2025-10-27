`include "uvm_macros.svh"
import uvm_pkg::*;

class apb_inbound_seq extends uvm_sequence #(apb_seq_item);
  `uvm_object_utils(apb_inbound_seq)

  string testname;

  // === MAPA APB (AJUSTE) ===
  localparam bit HAS_TREADY = 1'b0;
  localparam bit [`N_RBUS_ADDR_BITS-1:0] ADDR_TDATA_LO = 'h0000;
  localparam bit [`N_RBUS_ADDR_BITS-1:0] ADDR_TDATA_HI = 'h0004;
  localparam bit [`N_RBUS_ADDR_BITS-1:0] ADDR_TSTRB    = 'h0008;
  localparam bit [`N_RBUS_ADDR_BITS-1:0] ADDR_TUSER    = 'h000C;
  localparam bit [`N_RBUS_ADDR_BITS-1:0] ADDR_TLAST    = 'h0010;
  localparam bit [`N_RBUS_ADDR_BITS-1:0] ADDR_TVALID   = 'h0014;
  localparam bit [`N_RBUS_ADDR_BITS-1:0] ADDR_TREADY   = 'h0018; // RO opcional
  // ==========================

  int unsigned max_ready_polls = 100000;

  function new(string name="apb_inbound_seq");
    super.new(name);
  endfunction

  // --- helpers APB ---
  task apb_write(bit [`N_RBUS_ADDR_BITS-1:0] addr,
                 bit [`N_RBUS_DATA_BITS-1:0] data32or64);
    apb_seq_item tr;
    tr = apb_seq_item::type_id::create("wr");
    tr.op   = apb_seq_item::APB_WRITE;
    tr.addr = addr;
    tr.data = data32or64;
    start_item(tr); finish_item(tr);
    if (tr.resp_err)
      `uvm_fatal("APB_IB", $sformatf("WRITE PSLVERR/timeout @0x%0h", addr));
  endtask

  // >>> CORRIGIDO: agora ?? TASK com output (n??o mais function) <<<
  task apb_read(bit [`N_RBUS_ADDR_BITS-1:0] addr,
                output bit [`N_RBUS_DATA_BITS-1:0] rdata);
    apb_seq_item tr;
    tr = apb_seq_item::type_id::create("rd");
    tr.op   = apb_seq_item::APB_READ;
    tr.addr = addr;
    start_item(tr); finish_item(tr);
    if (tr.resp_err)
      `uvm_fatal("APB_IB", $sformatf("READ PSLVERR/timeout @0x%0h", addr));
    rdata = tr.rdata;
  endtask

  task write_tdata64(bit [63:0] tdata);
    int W;
    bit [31:0] lo, hi;
    W = `N_RBUS_DATA_BITS;
    if (W >= 64) begin
      apb_write(ADDR_TDATA_LO, tdata[`N_RBUS_DATA_BITS-1:0]);
    end
    else begin
      lo = tdata[31:0];
      hi = tdata[63:32];
      apb_write(ADDR_TDATA_LO, lo);
      apb_write(ADDR_TDATA_HI, hi);
    end
  endtask

  function automatic bit [7:0] translate_tuser(string s);
    bit [7:0] u;
    u = 8'h00;
    if (s == "SoT")       u = 8'h01;
    else if (s == "EoT")  u = 8'h02;
    else if (s.len()>=3 && (s.substr(0,1)=="0x" || s.substr(0,1)=="0X"))
      void'($sscanf(s, "0x%h", u));
    return u;
  endfunction

  task wait_tready_if_present();
    bit           has_tready;
    bit           ready;
    int unsigned  tries;
    bit [`N_RBUS_DATA_BITS-1:0] rdata_tmp;

    // Se n??o existir TREADY mapeado no seu IP, pode setar 0 aqui
    has_tready = 1'b1;
    if (!HAS_TREADY) return;

    tries = 0;
    ready = 1'b0;
    do begin
      apb_read(ADDR_TREADY, rdata_tmp);
      ready = rdata_tmp[0];
      tries++;
      if (!ready && tries > max_ready_polls)
        `uvm_fatal("APB_IB","Timeout esperando TREADY via APB");
    end while (!ready);
  endtask

  task body();
    string file_name, vector, tuser_string;
    int    fd, rc, nfields;
    bit [63:0] tdata;
    bit [7:0]  tstrb, tuser;
    bit        saw_cqe;

    if (testname == "") begin
      `uvm_warning("APB_IB","testname vazio; usando 'unknown'")
      testname = "unknown";
    end

    file_name = $psprintf("../tests/%s.inbound", testname);
    fd = $fopen(file_name, "r");
    if (fd == 0) `uvm_fatal("APB_IB", $sformatf("Arquivo %s NAO encontrado", file_name));
    `uvm_info("APB_IB", $sformatf("Abrindo inbound: %s", file_name), UVM_MEDIUM)

    apb_write(ADDR_TVALID, '0);
    apb_write(ADDR_TLAST,  '0);
    saw_cqe = 1'b0;

    while (!$feof(fd)) begin
      rc = $fgets(vector, fd);
      if (rc == 0) break;
      if (vector.len()==0) continue;
      if (vector.toupper()[0] == "#") continue;

      nfields = $sscanf(vector, "0x%h %s 0x%h", tdata, tuser_string, tstrb);
      if (nfields < 2) begin
        `uvm_error("APB_IB",$sformatf("Linha invalida: %s", vector))
        continue;
      end
      if (nfields == 2) tstrb = 8'hFF;

      tuser = translate_tuser(tuser_string);
      if (tuser_string == "SoT" && tdata[7:0] == 8'h09)
        saw_cqe = 1'b1;

      wait_tready_if_present();

      write_tdata64(tdata);
      apb_write(ADDR_TSTRB, {{(`N_RBUS_DATA_BITS-8){1'b0}}, tstrb});
      apb_write(ADDR_TUSER, {{(`N_RBUS_DATA_BITS-8){1'b0}}, tuser});

      if (tuser_string == "EoT" && saw_cqe) begin
        apb_write(ADDR_TLAST, '1);
        saw_cqe = 1'b0;
      end else begin
        apb_write(ADDR_TLAST, '0);
      end

      apb_write(ADDR_TVALID, '1);
      apb_write(ADDR_TVALID, '0);

      `uvm_info("APB_IB",
        $sformatf("INB: data=0x%016h user=0x%02h strb=0x%02h last=%0d",
                  tdata, tuser, tstrb, (tuser_string=="EoT")),
        UVM_HIGH)
    end

    apb_write(ADDR_TVALID, '0);
    apb_write(ADDR_TLAST,  '0);

    $fclose(fd);
    `uvm_info("APB_IB","Fim do arquivo .inbound",UVM_LOW)
  endtask
endclass
