`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// ECE369 - Computer Architecture
//
// Module - ID_EX_Reg.v
// Description - ID/EX pipeline register. Carries the decoded data and every
//               control signal from the ID stage into the EX stage.
//               Synchronous reset (same style as EX_MEM_Reg and MEM_WB_Reg).
////////////////////////////////////////////////////////////////////////////////

module ID_EX_Reg(
    input         Clk,
    input         Rst,

    // ---------------- WB control ----------------
    input         RegWrite_in,
    input  [1:0]  MemToReg_in,

    // ---------------- MEM control ----------------
    input         MemRead_in,
    input         MemWrite_in,
    input  [1:0]  MemSize_in,
    input         Branch_in,
    input         BranchOnZero_in,
    input         Jump_in,
    input         JumpReg_in,

    // ---------------- EX control ----------------
    input         ALUSrc_in,
    input         Shift_in,
    input  [4:0]  ALUControl_in,
    input  [1:0]  RegDst_in,

    // ---------------- data ----------------
    input  [31:0] PCPlus4_in,
    input  [31:0] ReadData1_in,     // rs value
    input  [31:0] ReadData2_in,     // rt value
    input  [31:0] Imm_in,           // sign/zero-extended immediate
    input  [31:0] JumpTarget_in,    // {PC+4[31:28], instr[25:0], 2'b00}
    input  [4:0]  Shamt_in,         // instr[10:6]
    input  [4:0]  Rt_in,            // instr[20:16]
    input  [4:0]  Rd_in,            // instr[15:11]

    // ---------------- outputs to EX ----------------
    output reg        RegWrite_out,
    output reg [1:0]  MemToReg_out,
    output reg        MemRead_out,
    output reg        MemWrite_out,
    output reg [1:0]  MemSize_out,
    output reg        Branch_out,
    output reg        BranchOnZero_out,
    output reg        Jump_out,
    output reg        JumpReg_out,
    output reg        ALUSrc_out,
    output reg        Shift_out,
    output reg [4:0]  ALUControl_out,
    output reg [1:0]  RegDst_out,
    output reg [31:0] PCPlus4_out,
    output reg [31:0] ReadData1_out,
    output reg [31:0] ReadData2_out,
    output reg [31:0] Imm_out,
    output reg [31:0] JumpTarget_out,
    output reg [4:0]  Shamt_out,
    output reg [4:0]  Rt_out,
    output reg [4:0]  Rd_out
);

    always @(posedge Clk) begin
        if (Rst) begin
            RegWrite_out     <= 1'b0;
            MemToReg_out     <= 2'b00;
            MemRead_out      <= 1'b0;
            MemWrite_out     <= 1'b0;
            MemSize_out      <= 2'b00;
            Branch_out       <= 1'b0;
            BranchOnZero_out <= 1'b0;
            Jump_out         <= 1'b0;
            JumpReg_out      <= 1'b0;
            ALUSrc_out       <= 1'b0;
            Shift_out        <= 1'b0;
            ALUControl_out   <= 5'd0;
            RegDst_out       <= 2'b00;
            PCPlus4_out      <= 32'd0;
            ReadData1_out    <= 32'd0;
            ReadData2_out    <= 32'd0;
            Imm_out          <= 32'd0;
            JumpTarget_out   <= 32'd0;
            Shamt_out        <= 5'd0;
            Rt_out           <= 5'd0;
            Rd_out           <= 5'd0;
        end else begin
            RegWrite_out     <= RegWrite_in;
            MemToReg_out     <= MemToReg_in;
            MemRead_out      <= MemRead_in;
            MemWrite_out     <= MemWrite_in;
            MemSize_out      <= MemSize_in;
            Branch_out       <= Branch_in;
            BranchOnZero_out <= BranchOnZero_in;
            Jump_out         <= Jump_in;
            JumpReg_out      <= JumpReg_in;
            ALUSrc_out       <= ALUSrc_in;
            Shift_out        <= Shift_in;
            ALUControl_out   <= ALUControl_in;
            RegDst_out       <= RegDst_in;
            PCPlus4_out      <= PCPlus4_in;
            ReadData1_out    <= ReadData1_in;
            ReadData2_out    <= ReadData2_in;
            Imm_out          <= Imm_in;
            JumpTarget_out   <= JumpTarget_in;
            Shamt_out        <= Shamt_in;
            Rt_out           <= Rt_in;
            Rd_out           <= Rd_in;
        end
    end

endmodule
