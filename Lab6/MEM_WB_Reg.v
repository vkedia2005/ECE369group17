`timescale 1ns / 1ps

module MEM_WB_Reg(
    input         Clk,
    input         Rst,

    // WB Control Signals
    input         RegWrite_in,
    input  [1:0]  MemToReg_in,

    // Datapath Values
    input  [31:0] PCPlus4_in,
    input  [31:0] ReadData_in,      // Output from DataMemory
    input  [31:0] ALUResult_in,     // Bypassed ALU result
    input  [4:0]  WriteReg_in,      // Destination register index

    // Outputs to WB Stage
    output reg        RegWrite_out,
    output reg [1:0]  MemToReg_out,
    output reg [31:0] PCPlus4_out,
    output reg [31:0] ReadData_out,
    output reg [31:0] ALUResult_out,
    output reg [4:0]  WriteReg_out
);

    always @(posedge Clk) begin
        if (Rst) begin
            RegWrite_out  <= 1'b0;
            MemToReg_out  <= 2'b00;
            PCPlus4_out   <= 32'd0;
            ReadData_out  <= 32'd0;
            ALUResult_out <= 32'd0;
            WriteReg_out  <= 5'd0;
        end else begin
            RegWrite_out  <= RegWrite_in;
            MemToReg_out  <= MemToReg_in;
            PCPlus4_out   <= PCPlus4_in;
            ReadData_out  <= ReadData_in;
            ALUResult_out <= ALUResult_in;
            WriteReg_out  <= WriteReg_in;
        end
    end

endmodule