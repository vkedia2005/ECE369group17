`timescale 1ns / 1ps

module ProgramCounter(
    input Clk,
    input Reset,
    input [31:0] NextPC,
    output reg [31:0] PC
);

    always @(posedge Clk or posedge Reset) begin
        if (Reset) begin
            PC <= 32'd0;
        end else begin
            PC <= NextPC;
        end
    end

endmodule