interface apb_if #(parameter ADDR_W = `N_RBUS_ADDR_BITS,
                   parameter DATA_W = `N_RBUS_DATA_BITS)
  (input  logic clk,
   input  logic rst_n);

  logic [ADDR_W-1:0] paddr;
  logic              psel;
  logic              penable;
  logic              pwrite;
  logic [DATA_W-1:0] pwdata;
  logic [DATA_W-1:0] prdata;
  logic              pready;
  logic              pslverr;

  // >>> ADICIONE clk/rst_n aqui <<<
  modport mst (
    input  clk, rst_n,
    output paddr, psel, penable, pwrite, pwdata,
    input  prdata, pready, pslverr
  );

  // monitor pode usar a interface inteira (ou um modport pr??prio, se quiser)
  modport slv (
    input  paddr, psel, penable, pwrite, pwdata,
    output prdata, pready, pslverr
  );

endinterface
