`default_nettype none

module vga_vram (
  i_clk, i_resetn,
  i_button,
  o_hsync, o_vsync, o_pixel
);

  localparam int DATA_WIDTH          = 16;

  localparam int DISPLAY_COLUMNS     = 640;
  localparam int DISPLAY_ROWS        = 480;
  localparam int PIXEL_COLUMNS       = DISPLAY_COLUMNS / 2;
  localparam int PIXEL_ROWS          = DISPLAY_ROWS / 2;
  localparam int WORDS_PER_PIXEL_ROW = PIXEL_COLUMNS / DATA_WIDTH;

  localparam int COUNTER_WIDTH       = $clog2(DISPLAY_COLUMNS * DISPLAY_ROWS);
  localparam int PIXEL_ADDRESS_WIDTH = $clog2(PIXEL_COLUMNS * PIXEL_ROWS);
  localparam int BIT_SELECT_WIDTH    = $clog2(DATA_WIDTH);
  localparam int VRAM_ADDRESS_WIDTH  = PIXEL_ADDRESS_WIDTH - BIT_SELECT_WIDTH;


  // PORT DECLARATIONS
  input  var i_clk;
  input  var i_resetn;
  input  var i_button;

  output var o_hsync;
  output var o_vsync;
  output var o_pixel;


  // DISPLAY CONTROLLER
  logic hsync, vsync;
  logic hblank, vblank, blank;
  logic vsubpx;
  logic [COUNTER_WIDTH-1:0] counter;

  vga_display_controller_320x240 u_controller (
    .i_clk(i_clk),
    .i_resetn(i_resetn),
    .o_hsync(hsync),
    .o_vsync(vsync),
    .o_hblank(hblank),
    .o_vblank(vblank),
    .o_vsubpx(vsubpx),
    .o_counter(counter)
  );

  assign blank = vblank | hblank;

  logic [PIXEL_ADDRESS_WIDTH-1:0] pixel_address;
  logic [ VRAM_ADDRESS_WIDTH-1:0] vram_address;
  logic [   BIT_SELECT_WIDTH-1:0] bit_select;

  assign pixel_address = counter >> 1;
  assign vram_address  = pixel_address[PIXEL_ADDRESS_WIDTH-1:BIT_SELECT_WIDTH];
  assign bit_select    = pixel_address[BIT_SELECT_WIDTH-1:0];


  // XORSHIFT -- TODO: version with external VRAM control
  logic [1:0] xorshift_step = '0;
  always_ff @(posedge i_clk)
    xorshift_step <= xorshift_step + 1;

  logic [31:0] random = 32'hDEADBEEF;
  always_ff @(posedge i_clk)
    case (xorshift_step)
      2'b00 : random <= random ^ (random << 13);
      2'b01 : random <= random ^ (random >> 17);
      2'b10 : random <= random ^ (random << 5);
      2'b11 : random <= random;
    endcase


  // VRAM -- TODO: make true dual port with 2 clocks and external signals for port A
  logic vram_re, vram_we;

  assign vram_re = (counter[(BIT_SELECT_WIDTH-1)+1:0] == 0);
  assign vram_we = !blank && vram_re && i_button && (vsubpx == 1'b0);

  logic [DATA_WIDTH-1:0] data_word;

  dual_port_bram #(
    .DATA_WIDTH(DATA_WIDTH),
    .DATA_DEPTH(PIXEL_ROWS * WORDS_PER_PIXEL_ROW)
  ) vram (
    .i_clk(i_clk),
    .i_ena(vram_we),
    .i_enb(vram_re),
    .i_wea(vram_we),
    .i_addra(vram_address),
    .i_addrb(vram_address),
    .i_dia(random[15:0]),
    .o_dob(data_word)
  );


  // PIPELINE
  logic [1:0] hsync_d = 2'b00;
  logic [1:0] vsync_d = 2'b00;
  logic       blank_d = 1'b1;
  logic [1:0][BIT_SELECT_WIDTH-1:0] bit_select_d = '0;

  // PIPELINE STAGE 1
  always_ff @(posedge i_clk)
    if (!i_resetn) begin
      hsync_d[0]      <= 1'b0;
      vsync_d[0]      <= 1'b0;
      blank_d         <= 1'b1;
      bit_select_d[0] <= '0;
    end
    else begin
      hsync_d[0]      <= hsync;
      vsync_d[0]      <= vsync;
      blank_d         <= blank;
      bit_select_d[0] <= bit_select;
    end

  // PIPELINE STAGE 2 -- in sync with 'data_word'
  logic [DATA_WIDTH-1:0] reverse_data_word;
  logic pixel;

  for (genvar i = 0; i < DATA_WIDTH; i++) begin
    assign reverse_data_word[i] = data_word[(DATA_WIDTH-1)-i];
  end

  assign pixel = !blank_d & reverse_data_word[bit_select_d];

  logic pixel_d = 1'b0;

  always_ff @(posedge i_clk)
    if (!i_resetn) begin
      hsync_d[1] <= 1'b0;
      vsync_d[1] <= 1'b0;
      pixel_d    <= 1'b0;
    end
    else begin
      hsync_d[1] <= hsync_d[0];
      vsync_d[1] <= vsync_d[0];
      pixel_d    <= pixel;
    end

  assign o_hsync = hsync_d[1];
  assign o_vsync = vsync_d[1];
  assign o_pixel = pixel_d;

endmodule
