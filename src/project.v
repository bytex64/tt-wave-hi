/*
 * Copyright (c) 2024 bytex64
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

  // Audio
  wire audio;

  // TinyVGA PMOD
  assign uo_out = {hsync, B[0], G[0], R[0], vsync, B[1], G[1], R[1]};

  // Unused outputs assigned to 0.
  assign uio_out = {audio, 7'b0};
  assign uio_oe  = 8'b10000000;

  // Suppress unused signals warning
  wire _unused_ok = &{ena, ui_in, uio_in};

  reg [6:0] counter;

  hvsync_generator hvsync_gen(
    .clk(clk),
    .reset(~rst_n),
    .hsync(hsync),
    .vsync(vsync),
    .display_on(video_active),
    .hpos(pix_x),
    .vpos(pix_y)
  );
  
  wire [6:0] moving_x = pix_x[6:0] + counter[6:0];

  wire [6:0] wave [0:1];
  wire [5:0] wave_addr [0:1];

  sin_rom sin_rom_1(
    .addr(wave_addr[0]),
    .data(wave[0])
  );

  sin_rom sin_rom_2(
    .addr(wave_addr[1]),
    .data(wave[1])
  );

  reg [6:0] last_wave [0:1];
  always @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
      last_wave[0] <= 64;
      last_wave[1] <= 64;
    end else begin
      last_wave[0] <= wave[0];
      last_wave[1] <= wave[1];
    end
  end

  assign wave_addr[0] = moving_x[5:0];
  wire _unused;
  assign {_unused, wave_addr[1]} = moving_x[6:0] - 7'd100;
  wire PX1 = wave[0] > last_wave[0] ?
              (pix_y + {3'd0, wave[0]} > pix_x & pix_y + {3'd0, last_wave[0]} < pix_x) :
              (pix_y + {3'd0, wave[0]} <= pix_x & pix_y + {3'd0, last_wave[0]} >= pix_x);
  wire PX2 = wave[1] > last_wave[1] ?
              (pix_y + {3'd0, wave[1]} + 100 > pix_x & pix_y + {3'd0, last_wave[1]} + 100 < pix_x) :
              (pix_y + {3'd0, wave[1]} + 100 <= pix_x & pix_y + {3'd0, last_wave[1]} + 100 >= pix_x);

  wire [6:0] delta = wave[0] > last_wave[0] ? wave[0] - last_wave[0] : last_wave[0] - wave[0];
  reg [2:0] hit [0:1];
  reg [1:0] brightness;
  always @(posedge clk, negedge hsync) begin
    if (~hsync) begin
      hit[0] <= 0;
      hit[1] <= 0;
    end
    else begin
      if (PX1)
        hit[0] <= hit[0] + 1;
      if (PX2)
        hit[1] <= hit[1] + 1;
    end
  end

  wire [2:0] next_color = (hit[0] == 3'b000 ? 3'b000 :
                            (hit[0] == 3'b001 ? 3'b110 :
                              (hit[0] == 3'b010 ? 3'b001 :
                                (hit[0] == 3'b011 ? (hit[1] == 3'b011 ? 3'b000 : 3'b110) :
                                  (hit[0] == 3'b100 ? 3'b001 :
                                    (hit[0] == 3'b101 ? (hit[1] == 3'b101 ? 3'b000 : 3'b110) :
                                      3'b000))))));
  reg [2:0] color;
  always @(posedge clk) begin
    if (next_color != color) begin
      if (next_color == 3'b110 || next_color == 3'b111)
        brightness <= (delta > 3 ? 2'b10 : 2'b11);
      else
        brightness <= (delta > 4 ? 2'b11 : delta[2:1]);
    end
    color <= next_color;
  end

  wire [5:0] layer0 = {
    color[2] ? brightness : 2'b00,
    color[1] ? brightness : 2'b00,
    color[0] ? brightness : 2'b00
  };

  wire [2:0] audio_data;
  wire [16:0] bitmap [0:4];
  assign bitmap[0] = 17'b11101010111010101;
  assign bitmap[1] = 17'b00101010101010101;
  assign bitmap[2] = 17'b11101010111010101;
  assign bitmap[3] = 17'b00101010101010101;
  assign bitmap[4] = 17'b11100100101011111;
  reg [1:0] sound_color;
  always @(posedge pix_x[4], negedge rst_n) begin
    if (~rst_n)
      sound_color <= 0;
    else
      sound_color <= audio_data[2:1];
  end
  wire [5:0] layer1 = pix_x >= 16 & pix_x < 288 & pix_y >= 384 & pix_y < 464 & pix_x[3:2] != 0 & pix_y[3:2] != 0 ? (
    bitmap[pix_y[6:4]][pix_x[8:4] - 1] ? {sound_color, 1'd0, audio_data[0], sound_color} : 0
  ) : 6'd0;

  wire [5:0] final_color = layer1 != 0 ? layer1 : layer0;

  assign R = video_active ? final_color[5:4] : 2'b00;
  assign G = video_active ? final_color[3:2] : 2'b00;
  assign B = video_active ? final_color[1:0] : 2'b00;
  
  always @(posedge vsync, negedge rst_n) begin
    if (~rst_n) begin
      counter <= 0;
    end else begin
      counter <= counter + 1;
    end
  end

  wire [8:0] pwm_clock;
  wire beat_tick;
  wire [1:0] beat_clock;
  clock_generator clock_generator_dev(
    .clk(clk),
    .rst_n(rst_n),
    .pwm_clock(pwm_clock),
    .vsync(vsync),
    .beat_tick(beat_tick),
    .beat_clock(beat_clock)
  );

  wire [5:0] lfsr;
  lfsr lfsr_dev(
    .clk(clk),
    .rst_n(rst_n),
    .bits(lfsr)
  );

  audio audio_mod(
    .pwm_clock(pwm_clock),
    .beat_tick(beat_tick),
    .beat_clock(beat_clock),
    .manual_override(ui_in[7]),
    .manual_note0(ui_in[2:0]),
    .manual_note1(ui_in[5:3]),
    .rst_n(rst_n),
    .rng(lfsr),
    .audio(audio),
    .audio_data(audio_data)
  );
endmodule
