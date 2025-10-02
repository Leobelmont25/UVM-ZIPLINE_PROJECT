`include "cr_global_params.vh"
`include "uvm_macros.svh"

import uvm_pkg::*;

module top_cfg_tb;

  // clock/reset
  logic clk; logic rst_n;
  initial begin
    clk = 0;
    forever #0.625 clk = ~clk;  // 800 MHz (como no seu tb)
  end

  initial begin
    rst_n = 0;
    #150; rst_n = 1;
  end

  // Outros sinais do DUT mantidos est??veis/idle
  logic                         ib_tready;
  logic [`AXI_S_TID_WIDTH-1:0]  ib_tid;
  logic [`AXI_S_DP_DWIDTH-1:0]  ib_tdata;
  logic [`AXI_S_TSTRB_WIDTH-1:0] ib_tstrb;
  logic [`AXI_S_USER_WIDTH-1:0]  ib_tuser;
  logic                         ib_tvalid;
  logic                         ib_tlast;

  logic                         ob_tready;
  logic [`AXI_S_TID_WIDTH-1:0]  ob_tid;
  logic [`AXI_S_DP_DWIDTH-1:0]  ob_tdata;
  logic [`AXI_S_TSTRB_WIDTH-1:0] ob_tstrb;
  logic [`AXI_S_USER_WIDTH-1:0]  ob_tuser;
  logic                         ob_tvalid;
  logic                         ob_tlast;

  logic                         sch_update_tready;
  logic [7:0]                   sch_update_tdata;
  logic                         sch_update_tvalid;
  logic                         sch_update_tlast;
  logic [1:0]                   sch_update_tuser;

  logic                         engine_int, engine_idle;
  logic                         key_mode, dbg_cmd_disable, xp9_disable;

  // APB interface
  apb_if #(.ADDR_W(`N_RBUS_ADDR_BITS), .DATA_W(`N_RBUS_DATA_BITS)) apb (.*);

  // DUT
  cr_cceip_64 dut(
    .ib_tready(ib_tready),
    .ib_tvalid(ib_tvalid),
    .ib_tlast(ib_tlast),
    .ib_tid(ib_tid),
    .ib_tstrb(ib_tstrb),
    .ib_tuser(ib_tuser),
    .ib_tdata(ib_tdata),

    .ob_tready(ob_tready),
    .ob_tvalid(ob_tvalid),
    .ob_tlast(ob_tlast),
    .ob_tid(ob_tid),
    .ob_tstrb(ob_tstrb),
    .ob_tuser(ob_tuser),
    .ob_tdata(ob_tdata),

    .sch_update_tready(sch_update_tready),
    .sch_update_tvalid(sch_update_tvalid),
    .sch_update_tlast(sch_update_tlast),
    .sch_update_tuser(sch_update_tuser),
    .sch_update_tdata(sch_update_tdata),

    .apb_paddr(apb.paddr),
    .apb_psel(apb.psel),
    .apb_penable(apb.penable),
    .apb_pwrite(apb.pwrite),
    .apb_pwdata(apb.pwdata),
    .apb_prdata(apb.prdata),
    .apb_pready(apb.pready),
    .apb_pslverr(apb.pslverr),

    .clk(clk),
    .rst_n(rst_n),
    .key_mode(key_mode),
    .dbg_cmd_disable(dbg_cmd_disable),
    .xp9_disable(xp9_disable),
    .cceip_int(engine_int),
    .cceip_idle(engine_idle),
    .scan_en(1'b0),
    .scan_mode(1'b0),
    .scan_rst_n(1'b0),
    .ovstb(1'b1),
    .lvm(1'b0),
    .mlvm(1'b0)
  );

  // Defaults de I/O n??o usados neste passo
  initial begin
    key_mode = 1'b0; dbg_cmd_disable = 1'b0; xp9_disable = 1'b0;

    ib_tid=0; ib_tvalid=0; ib_tlast=0; ib_tdata=0; ib_tstrb=0; ib_tuser=0;
    ob_tready=1'b1; // pronto para receber caso DUT gere algo
    sch_update_tready=1'b1;// sch_update_tdata=0; sch_update_tvalid=0; sch_update_tlast=0; sch_update_tuser=0;
  end

  // UVM bring-up
  string testname, seed_str;
  initial begin
    // pegar TESTNAME/SEED via +args
    if (!$value$plusargs("TESTNAME=%s", testname)) testname = "unknown";
    if (!$value$plusargs("SEED=%s", seed_str))     seed_str = "1";

    // Passar VIFs e testname para o ambiente
    uvm_config_db#(virtual apb_if.mst)::set(null, "uvm_test_top.env.apb.m_driver", "vif", apb);
    uvm_config_db#(virtual apb_if.mst)::set(null, "uvm_test_top.env.apb", "vif_mst", apb);
    uvm_config_db#(virtual apb_if)::set(null, "uvm_test_top.env.apb", "vif_mon", apb);

    uvm_config_db#(string)::set(null, "uvm_test_top", "testname", testname);

    run_test("cfg_test");
  end

endmodule
