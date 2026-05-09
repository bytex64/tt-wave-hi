module audio(
  input wire [8:0] pwm_clock,
  input wire beat_tick,
  input wire [1:0] beat_clock,
  input wire manual_override,     // active high
  input wire [2:0] manual_note0,
  input wire [2:0] manual_note1,
  input wire rst_n,
  input wire [5:0] rng,
  output wire audio
);
  wire [2:0] seq_note0;    // sequenced note values
  wire [2:0] seq_note1;
  wire [9:0] audio_freq0;  // per-channel frequency values
  wire [9:0] audio_freq1;

  sequence_generator sequence_generator_inst(
    .beat_tick(beat_tick),
    .beat_clock(beat_clock[1:0]),
    .rng(rng),
    .rst_n(rst_n),
    .note0(seq_note0),
    .note1(seq_note1)
  );

  note_map nm0(
    .select(manual_override ? manual_note0 : seq_note0),
    .freq(audio_freq0)
  );

  note_map nm1(
    .select(manual_override ? manual_note1 : seq_note1),
    .freq(audio_freq1)
  );

  audio_gen audio_gen_inst(
    .pwm_clock(pwm_clock),
    .rst_n(rst_n),
    .timer0(audio_freq0),
    .timer1(audio_freq1 << 1),
    .rng(rng[0]),
    .audio(audio)
  );
endmodule

/* Three sine wave generator */
module audio_gen(
  input wire [8:0] pwm_clock,
  input wire rst_n,
  input wire [9:0] timer0,
  input wire [9:0] timer1,
  input wire rng,
  output wire audio
);
  wire [8:0] level;
  wire [6:0] ch0_state, ch1_state;

  wire f_clock = pwm_clock == 0;

  audio_sin_gen chan0(
    .clk(f_clock),
    .rst_n(rst_n),
    .speed(timer0),
    .out(ch0_state)
  );
  audio_sin_gen chan1(
    .clk(f_clock),
    .rst_n(rst_n),
    .speed(timer1),
    .out(ch1_state)
  );

  assign level = {2'd0, ch0_state} + {2'd0, ch1_state} + {8'd0, rng};
  assign audio = pwm_clock <= level;
endmodule

module audio_sin_gen(
  input wire clk,          // audio clock
  input wire rst_n,
  input wire [9:0] speed,  // speed value (how much the table pointer advances in a clock tick)
  output wire [6:0] out    // the 7-bit output
);
  reg [13:0] ch_counter;
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

module sequence_generator(
  input wire [1:0] beat_clock,
  input wire beat_tick,
  input wire [5:0] rng,
  input wire rst_n,
  output reg [2:0] note0,
  output reg [2:0] note1
);
  always @(posedge beat_tick, negedge rst_n) begin
    if (~rst_n) begin
      note0 <= 0;
      note1 <= 0;
    end
    else begin
      if (beat_clock[1:0] == 0)
        note0 <= rng[2:0];
      if (beat_clock[0] == 0)
        note1 <= rng[5:3];
    end
  end
endmodule
