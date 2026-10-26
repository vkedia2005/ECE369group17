`timescale 1ns / 1ps

module JumpTarget(
    input  [31:0] PCPlus4,
    input  [25:0] Target,
    output [31:0] JumpAddress
);

    assign JumpAddress = {PCPlus4[31:28], Target, 2'b00};

endmodule