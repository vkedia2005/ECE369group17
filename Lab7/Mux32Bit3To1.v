`timescale 1ns / 1ps

module Mux32Bit3To1(out, inA, inB, inC, sel);

    output reg [31:0] out;
    
    input [31:0] inA; // 2'b00: ALUResult
    input [31:0] inB; // 2'b01: MemReadData
    input [31:0] inC; // 2'b10: PC + 4 (for jal)
    input [1:0]  sel;

    always @(*) begin
        case (sel)
            2'b00:   out = inA;
            2'b01:   out = inB;
            2'b10:   out = inC;
            default: out = inA;
        endcase
    end

endmodule