module clock_generator(
  input wire clk,                  // 25.175MHz main clock
  input wire rst_n,                // active low reset
  output wire [8:0] pwm_clock,     // 49.17kHz PWM clock (main / 512)
  input wire vsync,                // ~60Hz video clock
  output wire beat_tick,           // beat tick, every time beat_clock increments
  output wire [1:0] beat_clock     // pattern clock, increments with audio_tick
);
  reg [8:0] r_pwm_clock;
  reg [2:0] r_atick_clock;
  reg [1:0] r_beat_clock;

  always @(posedge clk, negedge rst_n) begin
    if (!rst_n)
      r_pwm_clock <= 0;
    else
      r_pwm_clock <= r_pwm_clock + 1;
  end
  assign pwm_clock = r_pwm_clock;

  always @(posedge vsync, negedge rst_n) begin
    if (!rst_n)
      r_atick_clock <= 0;
    else begin
      // Divide vsync by 6 to get 10Hz sequencer clock
      // 10Hz = 600 ticks per minute
      // four ticks per beat
      // 150 BPM
      if (r_atick_clock == 5)
        r_atick_clock <= 0;
      else
        r_atick_clock <= r_atick_clock + 1;
    end
  end

  assign beat_tick = r_atick_clock[2];
  wire audio_tick = (r_atick_clock == 0);

  always @(posedge audio_tick, negedge rst_n) begin
    if (~rst_n)
      r_beat_clock <= 0;
    else
      r_beat_clock <= r_beat_clock + 1;
  end

  assign beat_clock = r_beat_clock;
endmodule
