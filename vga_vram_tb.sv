module vga_vram_tb;

logic clk    = 0;
logic resetn = 1;
logic button = 1;

logic hsync;
logic vsync;
logic pixel;

always #10 clk = ~clk;

vga_vram uut (
  .i_clk(clk),
  .i_resetn(resetn),
  .i_button(button),
  .o_hsync(hsync),
  .o_vsync(vsync),
  .o_pixel(pixel)
);

endmodule
