interface axis_if #(
  parameter int DATA_W = 64
)(
  input  logic aclk,
  input  logic aresetn
);

  logic                 tvalid;
  logic                 tready;
  logic                 tlast;
  logic [DATA_W-1:0]    tdata;

  clocking cb @(posedge aclk);
    input tvalid;
    input tready;
    input tlast;
    input tdata;
  endclocking

  // monitor agora exp??e aclk/aresetn e os sinais crus
  modport monitor (
    input aclk, aresetn,
    input tvalid, tready, tlast, tdata
  );

  modport master  (input aresetn, input tready,
                   output tvalid, output tlast, output tdata);

  modport slave   (input aresetn, input tvalid, input tlast, input tdata,
                   output tready);

endinterface
