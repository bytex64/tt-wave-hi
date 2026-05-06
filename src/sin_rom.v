module sin_rom(
  input [5:0] addr,
  output reg [6:0] data
);
  reg [6:0] rom [0:63];

  initial begin
    rom[0] = 7'd64;
    rom[1] = 7'd70;
    rom[2] = 7'd76;
    rom[3] = 7'd82;
    rom[4] = 7'd88;
    rom[5] = 7'd94;
    rom[6] = 7'd99;
    rom[7] = 7'd104;
    rom[8] = 7'd109;
    rom[9] = 7'd113;
    rom[10] = 7'd117;
    rom[11] = 7'd120;
    rom[12] = 7'd123;
    rom[13] = 7'd125;
    rom[14] = 7'd126;
    rom[15] = 7'd127;
    rom[16] = 7'd127;
    rom[17] = 7'd127;
    rom[18] = 7'd126;
    rom[19] = 7'd125;
    rom[20] = 7'd123;
    rom[21] = 7'd120;
    rom[22] = 7'd117;
    rom[23] = 7'd113;
    rom[24] = 7'd109;
    rom[25] = 7'd104;
    rom[26] = 7'd99;
    rom[27] = 7'd94;
    rom[28] = 7'd88;
    rom[29] = 7'd82;
    rom[30] = 7'd76;
    rom[31] = 7'd70;
    rom[32] = 7'd64;
    rom[33] = 7'd58;
    rom[34] = 7'd52;
    rom[35] = 7'd46;
    rom[36] = 7'd40;
    rom[37] = 7'd34;
    rom[38] = 7'd29;
    rom[39] = 7'd24;
    rom[40] = 7'd19;
    rom[41] = 7'd15;
    rom[42] = 7'd11;
    rom[43] = 7'd8;
    rom[44] = 7'd5;
    rom[45] = 7'd3;
    rom[46] = 7'd2;
    rom[47] = 7'd1;
    rom[48] = 7'd1;
    rom[49] = 7'd1;
    rom[50] = 7'd2;
    rom[51] = 7'd3;
    rom[52] = 7'd5;
    rom[53] = 7'd8;
    rom[54] = 7'd11;
    rom[55] = 7'd15;
    rom[56] = 7'd19;
    rom[57] = 7'd24;
    rom[58] = 7'd29;
    rom[59] = 7'd34;
    rom[60] = 7'd40;
    rom[61] = 7'd46;
    rom[62] = 7'd52;
    rom[63] = 7'd58;
  end

  always @(*) begin
    data = rom[addr];
  end
endmodule
