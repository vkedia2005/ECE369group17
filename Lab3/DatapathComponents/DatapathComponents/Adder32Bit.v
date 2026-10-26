`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// ECE369 - Computer Architecture
//
// Module - Adder32Bit.v
// Description - 32-bit adder (overflow ignored).
//               Used for the branch target (PC+4 + offset<<2) in EX,
//               and can be reused for PC+4 in IF.
////////////////////////////////////////////////////////////////////////////////

module Adder32Bit(A, B, Sum);

    input  [31:0] A;
    input  [31:0] B;
    output [31:0] Sum;

    assign Sum = A + B;

endmodule
