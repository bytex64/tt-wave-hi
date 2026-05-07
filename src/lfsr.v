module lfsr(
  input wire clk,
  input wire rst_n,
  output wire [5:0] bits
);
  reg [10:0] lfsr;          // LFSR

  always @(posedge clk, negedge rst_n) begin
    if (!rst_n)
      lfsr <= 11'h0;
    else
      lfsr <= {lfsr[0] ~^ lfsr[2], lfsr[10:1]};
  end

  assign bits = lfsr[5:0];
endmodule
