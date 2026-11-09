`timescale 1ns / 1ps

module IF_ID_Register(
    input Clk,
    input Reset,
    input  [31:0] IF_PCPlus4,
    input  [31:0] IF_Instruction,
    output reg [31:0] ID_PCPlus4,
    output reg [31:0] ID_Instruction
);

    always @(posedge Clk or posedge Reset) begin
        if (Reset) begin
            ID_PCPlus4     <= 32'd0;
            ID_Instruction <= 32'd0;
        end else begin
            ID_PCPlus4     <= IF_PCPlus4;
            ID_Instruction <= IF_Instruction;
        end
    end

endmodule