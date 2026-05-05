/*
 * Copyright (c) 2024 Chip
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_bytex64_wave_hi (
  input  wire [7:0] ui_in,    // Dedicated inputs
  output wire [7:0] uo_out,   // Dedicated outputs
  input  wire [7:0] uio_in,   // IOs: Input path
  output wire [7:0] uio_out,  // IOs: Output path
  output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
  input  wire       ena,      // always 1 when the design is powered, so you can ignore it
  input  wire       clk,      // clock
  input  wire       rst_n     // reset_n - low to reset
);

  // VGA signals
  wire hsync;
  wire vsync;
  wire [1:0] R;
  wire [1:0] G;
  wire [1:0] B;
  wire video_active;
  wire [9:0] pix_x;
  wire [9:0] pix_y;

  // TinyVGA PMOD
  assign uo_out = {hsync, B[0], G[0], R[0], vsync, B[1], G[1], R[1]};

  // Unused outputs assigned to 0.
  assign uio_out = 0;
  assign uio_oe  = 0;

  // Suppress unused signals warning
  wire _unused_ok = &{ena, ui_in, uio_in};

  reg [9:0] counter;

  hvsync_generator hvsync_gen(
    .clk(clk),
    .reset(~rst_n),
    .hsync(hsync),
    .vsync(vsync),
    .display_on(video_active),
    .hpos(pix_x),
    .vpos(pix_y)
  );
  
  wire [9:0] moving_x = pix_x + counter;

  wire [6:0] wave [63:0];
  assign wave[0] = 7'd64;
  assign wave[1] = 7'd70;
  assign wave[2] = 7'd76;
  assign wave[3] = 7'd82;
  assign wave[4] = 7'd88;
  assign wave[5] = 7'd94;
  assign wave[6] = 7'd99;
  assign wave[7] = 7'd104;
  assign wave[8] = 7'd109;
  assign wave[9] = 7'd113;
  assign wave[10] = 7'd117;
  assign wave[11] = 7'd120;
  assign wave[12] = 7'd123;
  assign wave[13] = 7'd125;
  assign wave[14] = 7'd126;
  assign wave[15] = 7'd127;
  assign wave[16] = 7'd127;
  assign wave[17] = 7'd127;
  assign wave[18] = 7'd126;
  assign wave[19] = 7'd125;
  assign wave[20] = 7'd123;
  assign wave[21] = 7'd120;
  assign wave[22] = 7'd117;
  assign wave[23] = 7'd113;
  assign wave[24] = 7'd109;
  assign wave[25] = 7'd104;
  assign wave[26] = 7'd99;
  assign wave[27] = 7'd94;
  assign wave[28] = 7'd88;
  assign wave[29] = 7'd82;
  assign wave[30] = 7'd76;
  assign wave[31] = 7'd70;
  assign wave[32] = 7'd64;
  assign wave[33] = 7'd58;
  assign wave[34] = 7'd52;
  assign wave[35] = 7'd46;
  assign wave[36] = 7'd40;
  assign wave[37] = 7'd34;
  assign wave[38] = 7'd29;
  assign wave[39] = 7'd24;
  assign wave[40] = 7'd19;
  assign wave[41] = 7'd15;
  assign wave[42] = 7'd11;
  assign wave[43] = 7'd8;
  assign wave[44] = 7'd5;
  assign wave[45] = 7'd3;
  assign wave[46] = 7'd2;
  assign wave[47] = 7'd1;
  assign wave[48] = 7'd0;
  assign wave[49] = 7'd1;
  assign wave[50] = 7'd2;
  assign wave[51] = 7'd3;
  assign wave[52] = 7'd5;
  assign wave[53] = 7'd8;
  assign wave[54] = 7'd11;
  assign wave[55] = 7'd15;
  assign wave[56] = 7'd19;
  assign wave[57] = 7'd24;
  assign wave[58] = 7'd29;
  assign wave[59] = 7'd34;
  assign wave[60] = 7'd40;
  assign wave[61] = 7'd46;
  assign wave[62] = 7'd52;
  assign wave[63] = 7'd58;

  wire [6:0] VX = pix_y[7:0] - 100;
  wire [5:0] SX = pix_x[5:0] + counter[5:0];
  wire PX = (pix_y >= 100 & pix_y < 228)
      & (
        ((VX >= wave[SX]) & (VX < wave[(SX + 1) % 64])) |
        ((VX < wave[SX]) & (VX >= wave[(SX + 1) % 64]))
      );

  assign R = video_active ? {PX, PX} : 2'b00;
  assign G = video_active ? {PX, PX} : 2'b00;
  assign B = video_active ? {PX, PX} : 2'b00;
  
  always @(posedge vsync, negedge rst_n) begin
    if (~rst_n) begin
      counter <= 0;
    end else begin
      counter <= counter + 1;
    end
  end

  // Suppress unused signals warning
  wire _unused_ok_ = &{moving_x, pix_y};

endmodule
