module audio(
  input wire [8:0] pwm_clock,
  input wire [1:0] atick_clock,
  input wire [3:0] pattern_clock,
  input wire rst_n,
  input wire [5:0] rng,
  output wire audio
);
  wire [2:0] audio_note0;  // per-channel note values
  wire [2:0] audio_note1;
  wire [2:0] audio_note2;
  wire [9:0] audio_freq0;  // per-channel frequency values
  wire [9:0] audio_freq1;
  wire [9:0] audio_freq2;
  wire [1:0] audio_vol0;   // per-channel volume values
  wire [1:0] audio_vol1;
  wire [1:0] audio_vol2;

  instrument0 i0(
    .select(atick_clock),
    .vol(audio_vol0)
  );

  instrument1 i1(
    .select(atick_clock),
    .vol(audio_vol1)
  );

  instrument2 i2(
    .select(atick_clock),
    .vol(audio_vol2)
  );

  sequence_generator sequence_generator_inst(
    .pattern_tick(atick_clock[1]),
    .pattern_clock(pattern_clock),
    .rng(rng),
    .note0(audio_note0),
    .note1(audio_note1),
    .note2(audio_note2)
  );

  note_map nm0(
    .select(audio_note0),
    .freq(audio_freq0)
  );

  note_map nm1(
    .select(audio_note1),
    .freq(audio_freq1)
  );

  note_map nm2(
    .select(audio_note2),
    .freq(audio_freq2)
  );

  audio_gen audio_gen_inst(
    .pwm_clock(pwm_clock),
    .rst_n(rst_n),
    .timer0(audio_freq0),
    .timer1(audio_freq1 << 1),
    .timer2(audio_freq2),
    .vol0(audio_vol0),
    .vol1(audio_vol1),
    .vol2(audio_vol2),
    .rng(rng[2:0]),
    .audio(audio)
  );

endmodule

/* Three sine wave generator */
module audio_gen(
  input wire [8:0] pwm_clock,
  input wire rst_n,
  input wire [9:0] timer0,
  input wire [9:0] timer1,
  input wire [9:0] timer2,
  input wire [1:0] vol0,
  input wire [1:0] vol1,
  input wire [1:0] vol2,
  input wire [2:0] rng,
  output wire audio
);
  wire [8:0] level;
  wire [6:0] ch0_state, ch1_state, ch2_state;

  wire f_clock = pwm_clock == 0;

  // verilator lint_off WIDTHTRUNC
  wire _unused = {timer0, timer1, timer2, vol0, vol1, vol2, ch1_state, ch2_state};
  // verilator lint_on WIDTHTRUNC

  audio_psg_sin_gen chan0(
    .clk(f_clock),
    .rst_n(rst_n),
    .speed(timer0),
    .out(ch0_state)
  );
  audio_psg_sin_gen chan1(
    .clk(f_clock),
    .rst_n(rst_n),
    .speed(timer1),
    .out(ch1_state)
  );
  audio_psg_sin_gen chan2(
    .clk(f_clock),
    .rst_n(rst_n),
    .speed(timer2),
    .out(ch2_state)
  );

  // There's probably a better way to do this.
  assign level = {2'd0, ch0_state} + {2'd0, ch1_state} + {2'd0, ch2_state} + {6'd0, rng};
  /*
  assign level = 31 + {(ch0_state ? {3'b0, vol0} : -{3'b0, vol0}), rng}
                    + {(ch1_state ? {3'b0, vol1} : -{3'b0, vol1}), rng}
                    + {(ch2_state ? {3'b0, vol2} : -{3'b0, vol2}), rng}
                    + {(ch3_state ? {3'b0, vol3} : -{3'b0, vol3}), rng};
  */
  assign audio = pwm_clock <= level;
endmodule

/* Signal generator for noise channel */
/*
module audio_psg_noise_gen(
  input wire clk,           // the audio clock, which is the main clock
                            // divided by 64.
  input wire rst_n,
  input wire [11:0] timer,  // the timer value
  input wire rng,           // random bit from lfsr
  output wire out           // the square wave output
);
  reg [11:0] ch_counter;
  reg ch_state;

  always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
      ch_counter <= 0;
      ch_state <= 0;
    end
    else begin
      if (ch_counter == timer) begin
        ch_state <= rng;
        ch_counter <= 0;
      end
      else
        ch_counter <= ch_counter + 1;
    end
  end

  assign out = ch_state;
endmodule
*/

/* Signal generator for square wave channel */
/*
module audio_psg_square_gen(
  input wire clk,           // the audio clock, which is the main clock
                            // divided by 64.
  input wire rst_n,
  input wire [11:0] timer,  // the timer value
  output wire out           // the square wave output
);
  reg [11:0] ch_counter;
  reg ch_state;

  always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
      ch_counter <= 0;
      ch_state <= 0;
    end
    else begin
      if (ch_counter == timer) begin
        ch_state <= !ch_state;
        ch_counter <= 0;
      end
      else
        ch_counter <= ch_counter + 1;
    end
  end

  assign out = ch_state;
endmodule
*/

module audio_psg_sin_gen(
  input wire clk,          // audio clock
  input wire rst_n,
  input wire [9:0] speed,  // speed value (how much the table pointer advances in a clock tick)
  output wire [6:0] out    // the 7-bit output
);
  reg [13:0] ch_counter;
  wire _unused;
  sin_rom sin(
    .addr(ch_counter[13:8]),
    .data(out)
  );

  always @(posedge clk, negedge rst_n) begin
    if (~rst_n)
      ch_counter <= 0;
    else
      ch_counter <= ch_counter + {4'd0, speed};
  end
endmodule

// verilator lint_off UNUSEDPARAM
parameter T_C = 10'd87;   // 261.63 Hz
parameter T_D = 10'd97;   // 293.66 Hz
parameter T_E = 10'd109;  // 329.63 Hz
parameter T_F = 10'd116;  // 349.23 Hz
parameter T_G = 10'd130;  // 392    Hz
parameter T_A = 10'd146;  // 440    Hz
parameter T_B = 10'd164;  // 493.88 Hz

parameter N_C = 1;
parameter N_D = 2;
parameter N_E = 3;
parameter N_F = 4;
parameter N_G = 5;
parameter N_A = 6;
parameter N_B = 7;
// verilator lint_on UNUSEDPARAM

module note_map(
  input wire [2:0] select,
  output reg [9:0] freq
);
  reg [9:0] notes [0:7];

  initial begin
    notes[0]     = 0;
    notes[N_C] = T_C;
    notes[N_D] = T_D;
    notes[N_E] = T_E;
    notes[N_F] = T_F;
    notes[N_G] = T_G;
    notes[N_A] = T_A;
    notes[N_B] = T_B;
  end

  always @(*)
    freq = notes[select];
endmodule

module instrument0(
  input wire [1:0] select,
  output reg [1:0] vol
);
  reg [1:0] vol_sequence [3:0];

  initial begin
    vol_sequence[0] = 2'b11;
    vol_sequence[1] = 2'b11;
    vol_sequence[2] = 2'b10;
    vol_sequence[3] = 2'b00;
  end

  always @(*)
    vol = vol_sequence[select];
endmodule

module instrument1(
  input wire [1:0] select,
  output reg [1:0] vol
);
  reg [1:0] vol_sequence [3:0];

  initial begin
    vol_sequence[0] = 2'b10;
    vol_sequence[1] = 2'b10;
    vol_sequence[2] = 2'b01;
    vol_sequence[3] = 2'b00;
  end

  always @(*)
    vol = vol_sequence[select];
endmodule

module instrument2(
  input wire [1:0] select,
  output reg [1:0] vol
);
  reg [1:0] vol_sequence [3:0];

  initial begin
    vol_sequence[0] = 2'b11;
    vol_sequence[1] = 2'b01;
    vol_sequence[2] = 2'b00;
    vol_sequence[3] = 2'b00;
  end

  always @(*)
    vol = vol_sequence[select];
endmodule

module sequence_generator(
  input wire [3:0] pattern_clock,
  input wire pattern_tick,
  input wire [5:0] rng,
  output wire [2:0] note0,
  output wire [2:0] note1,
  output wire [2:0] note2
);
  reg [2:0] next_pattern0 [0:3];
  reg [2:0] next_pattern1 [0:7];
  reg [2:0] pattern0 [0:3];
  reg [2:0] pattern1 [0:7];

  always @(posedge pattern_tick) begin
    if (pattern_clock < 4)
      next_pattern0[pattern_clock[1:0]] <= rng[2:0];
    if (pattern_clock < 8)
      next_pattern1[pattern_clock[2:0]] <= rng[5:3];
    if (pattern_clock == 15) begin
      pattern0[0] <= next_pattern0[0];
      pattern0[1] <= next_pattern0[1];
      pattern0[2] <= next_pattern0[2];
      pattern0[3] <= next_pattern0[3];
      pattern1[0] <= next_pattern1[0];
      pattern1[1] <= next_pattern1[1];
      pattern1[2] <= next_pattern1[2];
      pattern1[3] <= next_pattern1[3];
      pattern1[4] <= next_pattern1[4];
      pattern1[5] <= next_pattern1[5];
      pattern1[6] <= next_pattern1[6];
      pattern1[7] <= next_pattern1[7];
    end
  end
  assign note0 = pattern0[pattern_clock[3:2]];
  assign note1 = pattern1[pattern_clock[3:1]];
  assign note2 = pattern1[{1'd0,pattern_clock[2:1]}];
endmodule
