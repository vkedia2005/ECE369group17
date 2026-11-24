`timescale 1ns / 1ps

module InstructionMemory(
    input  [31:0] Address,
    output [31:0] Instruction
);

    reg [31:0] memory [0:1023];
    integer i;
    initial begin
    for (i = 0; i < 1024; i = i + 1)
            memory[i] = 32'h00000000;            // fill with nops first
        $readmemh("instruction_memory.mem", memory);
    end
    
    
    
    // Address[11:2] extracts the 10-bit word index
    assign Instruction = memory[Address[11:2]];

endmodule