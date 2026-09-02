`timescale 1ns / 1ps

module Top(Clk, Reset, out7, en_out);

    input  Clk;                 // 100 MHz, pin E3
    input  Reset;               // center button, pin N17
    output [6:0] out7;          // cathodes
    output [7:0] en_out;        // anodes

    wire slow_clk;
    wire [31:0] Instruction;
    wire [31:0] PCResult;

    ClkDiv divider(
        .Clk(Clk),
        .Rst(1'b0),
        .ClkOut(slow_clk)
    );

    InstructionFetchUnit ifu(
        .Instruction(Instruction),
        .PCResult(PCResult),
        .Reset(Reset),
        .Clk(slow_clk)
    );

    Two4DigitDisplay display(
        .Clk(Clk),
        .NumberA(PCResult[15:0]),
        .NumberB(Instruction[15:0]),
        .out7(out7),
        .en_out(en_out)
    );

endmodule