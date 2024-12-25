`default_nettype none

module vga_sync_timing #(
  parameter int FRONT_PORCH_TIME = 16,
  parameter int SYNC_TIME        = 96,
  parameter int BACK_PORCH_TIME  = 48,
  parameter int DISPLAY_TIME     = 640
) (
  i_clk, i_clk_en, i_resetn,
  o_sync, o_blank, o_last
);

  localparam T1 = FRONT_PORCH_TIME;
  localparam T2 = T1 + SYNC_TIME;
  localparam T3 = T2 + BACK_PORCH_TIME;
  localparam T4 = T3 + DISPLAY_TIME;

  localparam COUNTER_WIDTH = $clog2(T4);

  // PORT DECLARATIONS
  input  var i_clk;
  input  var i_clk_en;
  input  var i_resetn;

  output var o_sync;
  output var o_blank;
  output var o_last;


  // SYNC TIMING COUNTER
  logic [COUNTER_WIDTH-1:0] counter = '0;
  always_ff @(posedge i_clk)
    if      (!i_resetn)                   counter <= '0;
    else if (i_clk_en && counter == T4-1) counter <= '0;
    else if (i_clk_en)                    counter <= counter + 1;


  // TIMING STATE MACHINE
  typedef enum bit [1:0]{
    s_front_porch,
    s_sync,
    s_back_porch,
    s_display
  } t_state;

  t_state state = s_front_porch;
  t_state next_state;

  always_comb
    case (state)
      s_front_porch : next_state = (counter == T1-1) ? s_sync        : state;
      s_sync        : next_state = (counter == T2-1) ? s_back_porch  : state;
      s_back_porch  : next_state = (counter == T3-1) ? s_display     : state;
      s_display     : next_state = (counter == T4-1) ? s_front_porch : state;
      default       : next_state = s_front_porch;
    endcase

  always_ff @(posedge i_clk)
    if      (!i_resetn) state <= s_front_porch;
    else if (i_clk_en)  state <= next_state;


  // DERIVED TIMING SIGNALS
  logic sync, blank, clk_en, last;
  assign sync   = (state == s_sync);
  assign blank  = (state != s_display);
  assign last   = (counter == FRONT_PORCH_TIME-1);


//  // PIPELINE
//  logic sync_d  = 1'b0;
//  logic blank_d = 1'b1;
//  logic last_d  = 1'b0;

//  always_ff @(posedge i_clk)
//    if (!i_resetn) begin
//      sync_d  <= 1'b0;
//      blank_d <= 1'b1;
//      last_d  <= 1'b0;
//    end
//    else begin
//      sync_d  <= sync;
//      blank_d <= blank;
//      last_d  <= last;
//    end
  
  assign o_sync  = sync;
  assign o_blank = blank;
  assign o_last  = last;

endmodule
