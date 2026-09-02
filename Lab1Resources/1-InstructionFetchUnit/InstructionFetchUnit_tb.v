`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////
// ECE369A - Computer Architecture
// Laboratory 1
// Module - InstructionFetchUnit_tb.v
// Description - Testbench for the instruction fetch unit.
//
// Drives Clk and Reset, then lets the fetch loop run freely. PCResult should
// step 0, 4, 8, 12, ... and Instruction should track 0, 3, 6, 9, ...
////////////////////////////////////////////////////////////////////////////////
module InstructionFetchUnit_tb();

    reg Reset, Clk;
    wire [31:0] Instruction;
    wire [31:0] PCResult;

    InstructionFetchUnit dut(
        .Instruction(Instruction),
        .PCResult(PCResult),
        .Reset(Reset),
        .Clk(Clk)
    );

    initial begin
        Clk = 1'b0;
        forever #10 Clk = ~Clk;
    end

    initial begin
        Reset = 1'b1;
        #45;

        Reset = 1'b0;
        #400;

        $finish;
    end

    initial begin
        $monitor("t=%4d ns   PC=%3d   Instruction=%3d",
                 $time, PCResult, Instruction);
    end

endmodule