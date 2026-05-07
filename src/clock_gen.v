module clock_generator(
  input wire clk,                  // 25.175MHz main clock
  input wire rst_n,                // active low reset
  output wire [5:0] pwm_clock,     // 393kHz PWM clock (main / 64)
  input wire vsync,                // ~60Hz video clock
  output wire [1:0] atick_clock,   // audio tick clock state, used for volume modulation
  output wire [3:0] pattern_clock  // pattern clock, increments with audio_tick
);
  reg [5:0] r_pwm_clock;
  reg [2:0] r_atick_clock;
  reg [3:0] r_pattern_clock;

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

  assign atick_clock = r_atick_clock[2:1];
  wire audio_tick = (r_atick_clock == 0);

  always @(posedge audio_tick, negedge rst_n) begin
    if (!rst_n)
      r_pattern_clock <= 0;
    else
      r_pattern_clock <= r_pattern_clock + 1;
  end

  assign pattern_clock = r_pattern_clock;
endmodule
