`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// ECE369 - Computer Architecture
//
// Module - Mux5Bit3To1.v
// Description - 3-to-1 multiplexer for 5-bit register numbers.
//               Used as the write-register (RegDst) mux in the EX stage:
//               sel = 00 -> inA (rt), 01 -> inB (rd), 10 -> inC (31 for jal).
//               sel = 11 is unused and outputs inA.
////////////////////////////////////////////////////////////////////////////////

module Mux5Bit3To1(out, inA, inB, inC, sel);

    output reg [4:0] out;

    input [4:0] inA;
    input [4:0] inB;
    input [4:0] inC;
    input [1:0] sel;

    always @(*) begin
        case (sel)
            2'b00:   out = inA;
            2'b01:   out = inB;
            2'b10:   out = inC;
            default: out = inA;
        endcase
    end

endmodule
