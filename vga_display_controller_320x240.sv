`default_nettype none

module vga_display_controller_320x240 (
  i_clk, i_resetn,
  o_hsync, o_vsync,
  o_hblank, o_vblank,
  o_vsubpx,
  o_counter
);

  localparam int H_FRONT_PORCH_TIME = 16;
  localparam int H_SYNC_TIME        = 96;
  localparam int H_BACK_PORCH_TIME  = 48;
  localparam int H_DISPLAY_TIME     = 640;

  localparam int V_FRONT_PORCH_TIME = 10;
  localparam int V_SYNC_TIME        = 2;
  localparam int V_BACK_PORCH_TIME  = 33;
  localparam int V_DISPLAY_TIME     = 480;

  localparam int COUNTER_WIDTH = $clog2(H_DISPLAY_TIME * V_DISPLAY_TIME);


  // PORT DECLARATIONS
  input  var i_clk;
  input  var i_resetn;

  output var o_hsync;
  output var o_vsync;
  output var o_hblank;
  output var o_vblank;
  output var o_vsubpx;

  output var [COUNTER_WIDTH-1:0] o_counter;


  // SYNC TIMING UNITS
  logic blank;
  logic vlast, hlast, last;

  vga_sync_timing #(
    .FRONT_PORCH_TIME(H_FRONT_PORCH_TIME),
    .SYNC_TIME(H_SYNC_TIME),
    .BACK_PORCH_TIME(H_BACK_PORCH_TIME),
    .DISPLAY_TIME(H_DISPLAY_TIME)
  ) u_hsync (
    .i_clk(i_clk),
    .i_clk_en(1'b1),
    .i_resetn(i_resetn),
    .o_sync(o_hsync),
    .o_blank(o_hblank),
    .o_last(hlast)
  );

  vga_sync_timing #(
    .FRONT_PORCH_TIME(V_FRONT_PORCH_TIME),
    .SYNC_TIME(V_SYNC_TIME),
    .BACK_PORCH_TIME(V_BACK_PORCH_TIME),
    .DISPLAY_TIME(V_DISPLAY_TIME)
  ) u_vsync (
    .i_clk(i_clk),
    .i_clk_en(hlast),
    .i_resetn(i_resetn),
    .o_sync(o_vsync),
    .o_blank(o_vblank),
    .o_last(vlast)
  );

  assign blank = o_hblank | o_vblank;
  assign last  = hlast & vlast;


  // POSITION COUNTERS
  logic vsubpx = 1'b0;
  always_ff @(posedge i_clk)
    if      (last)  vsubpx <= 1'b0;
    else if (hlast) vsubpx <= ~vsubpx;

  logic [1:0][COUNTER_WIDTH-1:0] counters = '0;
  always_ff @(posedge i_clk)
    if      (!i_resetn || last) counters         <= '0;
    else if (!blank)            counters[vsubpx] <= counters[vsubpx] + 1;

  assign o_vsubpx  = vsubpx;
  assign o_counter = counters[vsubpx];
    
endmodule

