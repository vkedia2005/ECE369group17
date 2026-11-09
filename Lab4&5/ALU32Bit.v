`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// ECE369 - Computer Architecture
// 
// Module - ALU32Bit.v
// Description - 32-Bit wide arithmetic logic unit (ALU).
//
// INPUTS:-
// ALUControl: N-Bit input control bits to select an ALU operation.
// A: 32-Bit input port A.
// B: 32-Bit input port B.
//
// OUTPUTS:-
// ALUResult: 32-Bit ALU result output.
// ZERO: 1-Bit output flag. 
//
// FUNCTIONALITY:-
// Design a 32-Bit ALU, so that it supports all arithmetic operations 
// needed by the MIPS instructions given in Labs5-8.docx document. 
//   The 'ALUResult' will output the corresponding result of the operation 
//   based on the 32-Bit inputs, 'A', and 'B'. 
//   The 'Zero' flag is high when 'ALUResult' is '0'. 
//   The 'ALUControl' signal should determine the function of the ALU 
//   You need to determine the bitwidth of the ALUControl signal based on the number of 
//   operations needed to support. 
////////////////////////////////////////////////////////////////////////////////
module ALU32Bit(ALUControl, A, B, ALUResult, ALUResult64, Zero);

    input  [4:0]  ALUControl;
    input  [31:0] A, B;

    output reg [31:0] ALUResult;    // normal 32-bit result
    output reg [63:0] ALUResult64;  // full product for mul (HI = [63:32], LO = [31:0])
    output Zero;

    // ---- operation encoding ----
    localparam OP_ADD  = 5'd0;
    localparam OP_SUB  = 5'd1;
    localparam OP_MUL  = 5'd2;
    localparam OP_AND  = 5'd3;
    localparam OP_OR   = 5'd4;
    localparam OP_XOR  = 5'd5;
    localparam OP_NOR  = 5'd6;
    localparam OP_SLL  = 5'd7;
    localparam OP_SRL  = 5'd8;
    localparam OP_SLT  = 5'd9;
    localparam OP_BGEZ = 5'd10;
    localparam OP_BGTZ = 5'd11;
    localparam OP_BLEZ = 5'd12;
    localparam OP_BLTZ = 5'd13;

    always @(*) begin
        // defaults first, so no latch is inferred (see FAQ Q7)
        ALUResult   = 32'd0;
        ALUResult64 = 64'd0;

        case (ALUControl)
            OP_ADD : ALUResult = A + B;
            OP_SUB : ALUResult = A - B;
            OP_MUL : begin
                     ALUResult64 = $signed(A) * $signed(B);
                     ALUResult   = ALUResult64[31:0];
                     end
            OP_AND : ALUResult =  A & B;
            OP_OR  : ALUResult =  A | B;
            OP_XOR : ALUResult =  A ^ B;
            OP_NOR : ALUResult = ~(A | B);
            OP_SLL : ALUResult = A << B[4:0];
            OP_SRL : ALUResult = A >> B[4:0];
            OP_SLT : ALUResult = ($signed(A) <  $signed(B)) ? 32'd1 : 32'd0;
            OP_BGEZ: ALUResult = ($signed(A) >= 0) ? 32'd1 : 32'd0;
            OP_BGTZ: ALUResult = ($signed(A) >  0) ? 32'd1 : 32'd0;
            OP_BLEZ: ALUResult = ($signed(A) <= 0) ? 32'd1 : 32'd0;
            OP_BLTZ: ALUResult = ($signed(A) <  0) ? 32'd1 : 32'd0;
            default: ALUResult = 32'd0;
        endcase
    end

    assign Zero = (ALUResult == 32'd0);

endmodule