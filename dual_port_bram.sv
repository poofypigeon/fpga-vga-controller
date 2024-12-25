`default_nettype none

module dual_port_bram #(
  parameter DATA_WIDTH = 16,
  parameter DATA_DEPTH = 1024
) (
  i_clk, 
  i_ena, i_enb, i_wea,
  i_addra, i_addrb,
  i_dia,
  o_dob
);

  localparam ADDRESS_WIDTH = $clog2(DATA_DEPTH);


  // PORT DECLARATIONS
  input  wire i_clk;
  input  var i_ena;
  input  var i_enb;
  input  var i_wea;

  input  var [ADDRESS_WIDTH-1:0] i_addra;
  input  var [ADDRESS_WIDTH-1:0] i_addrb;

  input  var [DATA_WIDTH-1:0] i_dia;

  output var [DATA_WIDTH-1:0] o_dob;
  //initial o_dob = '0;


  // BRAM
  bit [DATA_WIDTH-1:0] ram [DATA_DEPTH-1:0];

  //initial for (int i = 0; i < DATA_DEPTH; i++) ram[i] = '0;


  // READ / WRITE
  always_ff @(posedge i_clk)
    if (i_ena && i_wea) ram[i_addra] <= i_dia;

  always_ff @(posedge i_clk)
    if (i_enb) o_dob <= ram[i_addrb];

endmodule
