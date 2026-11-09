`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// ECE369 - Computer Architecture
//
// Module - Top_Datapath.v
// Description - 5-stage pipelined MIPS datapath (IF, ID, EX, MEM, WB).
//               No hazard detection: programs need 5 nops between instructions.
//               Branches, jumps and jr are all resolved in the MEM stage.
//
// INPUTS:-
// Clk : clock
// Rst : reset (PC and all pipeline registers go to 0)
//
// OUTPUTS:-
// PC        : address of the instruction currently in WB (matches the
//             "display PC, value" pairs in the lab handout)
// WriteData : value written to the register file by that instruction
//             (0 when it writes no register: sw, branches, j, jr)
////////////////////////////////////////////////////////////////////////////////

module Top_Datapath(
    input         Clk,
    input         Rst,
    output [31:0] PC,
    output [31:0] WriteData
);

    // =========================================================================
    // WIRE DECLARATIONS
    // =========================================================================

    // ---------------- IF stage ----------------
    wire [31:0] IF_PC;
    wire [31:0] IF_PCPlus4;
    wire [31:0] IF_Instruction;
    reg  [31:0] NextPC;

    // ---------------- ID stage ----------------
    wire [31:0] ID_PCPlus4;
    wire [31:0] ID_Instruction;
    wire [31:0] ID_ReadData1;
    wire [31:0] ID_ReadData2;
    wire [31:0] ID_Imm;
    wire [31:0] ID_JumpTarget;

    // controller outputs
    wire        ID_RegWrite;
    wire [1:0]  ID_RegDst;
    wire        ID_ALUSrc;
    wire        ID_ExtOp;
    wire        ID_Shift;
    wire [4:0]  ID_ALUControl;
    wire        ID_MemRead;
    wire        ID_MemWrite;
    wire [1:0]  ID_MemSize;
    wire [1:0]  ID_MemToReg;
    wire        ID_Branch;
    wire        ID_BranchOnZero;
    wire        ID_Jump;
    wire        ID_JumpReg;

    // ---------------- EX stage (ID/EX outputs) ----------------
    wire        EX_RegWrite;
    wire [1:0]  EX_MemToReg;
    wire        EX_MemRead;
    wire        EX_MemWrite;
    wire [1:0]  EX_MemSize;
    wire        EX_Branch;
    wire        EX_BranchOnZero;
    wire        EX_Jump;
    wire        EX_JumpReg;
    wire        EX_ALUSrc;
    wire        EX_Shift;
    wire [4:0]  EX_ALUControl;
    wire [1:0]  EX_RegDst;
    wire [31:0] EX_PCPlus4;
    wire [31:0] EX_ReadData1;
    wire [31:0] EX_ReadData2;
    wire [31:0] EX_Imm;
    wire [31:0] EX_JumpTarget;
    wire [4:0]  EX_Shamt;
    wire [4:0]  EX_Rt;
    wire [4:0]  EX_Rd;

    // EX stage results
    wire [31:0] EX_ALUInA;
    wire [31:0] EX_RegOrImm;
    wire [31:0] EX_ALUInB;
    wire [31:0] EX_ALUResult;
    wire        EX_Zero;
    wire [31:0] EX_BranchTarget;
    wire [4:0]  EX_WriteReg;

    // ---------------- MEM stage (EX/MEM outputs) ----------------
    wire        MEM_RegWrite;
    wire [1:0]  MEM_MemToReg;
    wire        MEM_MemRead;
    wire        MEM_MemWrite;
    wire [1:0]  MEM_MemSize;
    wire        MEM_Branch;
    wire        MEM_BranchOnZero;
    wire        MEM_Jump;
    wire        MEM_JumpReg;
    wire [31:0] MEM_PCPlus4;
    wire [31:0] MEM_BranchTarget;
    wire [31:0] MEM_JumpTarget;
    wire [31:0] MEM_ReadData1;
    wire [31:0] MEM_ALUResult;
    wire        MEM_Zero;
    wire [31:0] MEM_WriteData;
    wire [4:0]  MEM_WriteReg;

    wire [31:0] MEM_ReadData;   // data memory output
    wire        PCSrc;          // 1 = branch taken

    // ---------------- WB stage (MEM/WB outputs) ----------------
    wire        WB_RegWrite;
    wire [1:0]  WB_MemToReg;
    wire [31:0] WB_PCPlus4;
    wire [31:0] WB_ReadData;
    wire [31:0] WB_ALUResult;
    wire [4:0]  WB_WriteReg;
    wire [31:0] WB_WriteData;   // goes to RegisterFile.WriteData

    // =========================================================================
    // IF STAGE
    // =========================================================================

    // Next PC: redirects come from the MEM stage (branches, j/jal, jr)
    always @(*) begin
        if (MEM_Jump)
            NextPC = MEM_JumpTarget;     // j / jal
        else if (MEM_JumpReg)
            NextPC = MEM_ReadData1;      // jr (rs value)
        else if (PCSrc)
            NextPC = MEM_BranchTarget;   // taken branch
        else
            NextPC = IF_PCPlus4;         // next instruction
    end

    ProgramCounter PCReg (
        .Clk(Clk),
        .Rst(Rst),
        .NextPC(NextPC),
        .PC(IF_PC)
    );

    PCAdder PCAdd (
        .PC(IF_PC),
        .PCPlus4(IF_PCPlus4)
    );

    InstructionMemory IMem (
        .Address(IF_PC),
        .Instruction(IF_Instruction)
    );

    // =========================================================================
    // IF/ID PIPELINE REGISTER
    // =========================================================================
    IF_ID_Register IF_ID (
        .Clk(Clk),
        .Reset(Rst),
        .IF_PCPlus4(IF_PCPlus4),
        .IF_Instruction(IF_Instruction),
        .ID_PCPlus4(ID_PCPlus4),
        .ID_Instruction(ID_Instruction)
    );

    // =========================================================================
    // ID STAGE
    // =========================================================================
    Controller Ctrl (
        .Opcode(ID_Instruction[31:26]),
        .Funct(ID_Instruction[5:0]),
        .Rt(ID_Instruction[20:16]),
        .RegWrite(ID_RegWrite),
        .RegDst(ID_RegDst),
        .ALUSrc(ID_ALUSrc),
        .ExtOp(ID_ExtOp),
        .Shift(ID_Shift),
        .ALUControl(ID_ALUControl),
        .MemRead(ID_MemRead),
        .MemWrite(ID_MemWrite),
        .MemSize(ID_MemSize),
        .MemToReg(ID_MemToReg),
        .Branch(ID_Branch),
        .BranchOnZero(ID_BranchOnZero),
        .Jump(ID_Jump),
        .JumpReg(ID_JumpReg)
    );

    // Reads use ID-stage register numbers; the write port is driven from WB.
    RegisterFile RegFile (
        .ReadRegister1(ID_Instruction[25:21]),   // rs
        .ReadRegister2(ID_Instruction[20:16]),   // rt
        .WriteRegister(WB_WriteReg),
        .WriteData(WB_WriteData),
        .RegWrite(WB_RegWrite),
        .Clk(Clk),
        .ReadData1(ID_ReadData1),
        .ReadData2(ID_ReadData2)
    );

    SignExtension SignExt (
        .in(ID_Instruction[15:0]),
        .ExtOp(ID_ExtOp),
        .out(ID_Imm)
    );

    JumpTarget JTarget (
        .PCPlus4(ID_PCPlus4),
        .Target(ID_Instruction[25:0]),
        .JumpAddress(ID_JumpTarget)
    );

    // =========================================================================
    // ID/EX PIPELINE REGISTER
    // =========================================================================
    ID_EX_Reg ID_EX (
        .Clk(Clk),
        .Rst(Rst),
        // control in
        .RegWrite_in(ID_RegWrite),
        .MemToReg_in(ID_MemToReg),
        .MemRead_in(ID_MemRead),
        .MemWrite_in(ID_MemWrite),
        .MemSize_in(ID_MemSize),
        .Branch_in(ID_Branch),
        .BranchOnZero_in(ID_BranchOnZero),
        .Jump_in(ID_Jump),
        .JumpReg_in(ID_JumpReg),
        .ALUSrc_in(ID_ALUSrc),
        .Shift_in(ID_Shift),
        .ALUControl_in(ID_ALUControl),
        .RegDst_in(ID_RegDst),
        // data in
        .PCPlus4_in(ID_PCPlus4),
        .ReadData1_in(ID_ReadData1),
        .ReadData2_in(ID_ReadData2),
        .Imm_in(ID_Imm),
        .JumpTarget_in(ID_JumpTarget),
        .Shamt_in(ID_Instruction[10:6]),
        .Rt_in(ID_Instruction[20:16]),
        .Rd_in(ID_Instruction[15:11]),
        // control out
        .RegWrite_out(EX_RegWrite),
        .MemToReg_out(EX_MemToReg),
        .MemRead_out(EX_MemRead),
        .MemWrite_out(EX_MemWrite),
        .MemSize_out(EX_MemSize),
        .Branch_out(EX_Branch),
        .BranchOnZero_out(EX_BranchOnZero),
        .Jump_out(EX_Jump),
        .JumpReg_out(EX_JumpReg),
        .ALUSrc_out(EX_ALUSrc),
        .Shift_out(EX_Shift),
        .ALUControl_out(EX_ALUControl),
        .RegDst_out(EX_RegDst),
        // data out
        .PCPlus4_out(EX_PCPlus4),
        .ReadData1_out(EX_ReadData1),
        .ReadData2_out(EX_ReadData2),
        .Imm_out(EX_Imm),
        .JumpTarget_out(EX_JumpTarget),
        .Shamt_out(EX_Shamt),
        .Rt_out(EX_Rt),
        .Rd_out(EX_Rd)
    );

    // =========================================================================
    // EX STAGE
    // =========================================================================

    // ALU A: rs normally, rt for sll/srl (the register being shifted)
    Mux32Bit2To1 ALUAMux (
        .out(EX_ALUInA),
        .inA(EX_ReadData1),
        .inB(EX_ReadData2),
        .sel(EX_Shift)
    );

    // ALU B step 1: rt value or immediate
    Mux32Bit2To1 ALUSrcMux (
        .out(EX_RegOrImm),
        .inA(EX_ReadData2),
        .inB(EX_Imm),
        .sel(EX_ALUSrc)
    );

    // ALU B step 2: shift amount for sll/srl
    Mux32Bit2To1 ShamtMux (
        .out(EX_ALUInB),
        .inA(EX_RegOrImm),
        .inB({27'b0, EX_Shamt}),
        .sel(EX_Shift)
    );

    ALU32Bit ALU (
        .ALUControl(EX_ALUControl),
        .A(EX_ALUInA),
        .B(EX_ALUInB),
        .ALUResult(EX_ALUResult),
        .ALUResult64(),              // unused
        .Zero(EX_Zero)
    );

    // branch target = PC+4 + (offset << 2)
    Adder32Bit BranchAdder (
        .A(EX_PCPlus4),
        .B({EX_Imm[29:0], 2'b00}),
        .Sum(EX_BranchTarget)
    );

    // write register: rt / rd / $31
    Mux5Bit3To1 RegDstMux (
        .out(EX_WriteReg),
        .inA(EX_Rt),
        .inB(EX_Rd),
        .inC(5'd31),
        .sel(EX_RegDst)
    );

    // =========================================================================
    // EX/MEM PIPELINE REGISTER
    // =========================================================================
    EX_MEM_Reg EX_MEM (
        .Clk(Clk),
        .Rst(Rst),
        .RegWrite_in(EX_RegWrite),
        .MemToReg_in(EX_MemToReg),
        .MemRead_in(EX_MemRead),
        .MemWrite_in(EX_MemWrite),
        .MemSize_in(EX_MemSize),
        .Branch_in(EX_Branch),
        .BranchOnZero_in(EX_BranchOnZero),
        .Jump_in(EX_Jump),
        .JumpReg_in(EX_JumpReg),
        .PCPlus4_in(EX_PCPlus4),
        .BranchTarget_in(EX_BranchTarget),
        .JumpTarget_in(EX_JumpTarget),
        .ReadData1_in(EX_ReadData1),
        .ALUResult_in(EX_ALUResult),
        .Zero_in(EX_Zero),
        .WriteData_in(EX_ReadData2),     // store data for sw/sh/sb
        .WriteReg_in(EX_WriteReg),
        .RegWrite_out(MEM_RegWrite),
        .MemToReg_out(MEM_MemToReg),
        .MemRead_out(MEM_MemRead),
        .MemWrite_out(MEM_MemWrite),
        .MemSize_out(MEM_MemSize),
        .Branch_out(MEM_Branch),
        .BranchOnZero_out(MEM_BranchOnZero),
        .Jump_out(MEM_Jump),
        .JumpReg_out(MEM_JumpReg),
        .PCPlus4_out(MEM_PCPlus4),
        .BranchTarget_out(MEM_BranchTarget),
        .JumpTarget_out(MEM_JumpTarget),
        .ReadData1_out(MEM_ReadData1),
        .ALUResult_out(MEM_ALUResult),
        .Zero_out(MEM_Zero),
        .WriteData_out(MEM_WriteData),
        .WriteReg_out(MEM_WriteReg)
    );

    // =========================================================================
    // MEM STAGE
    // =========================================================================

    // beq: taken when Zero == 1. bne/bgtz/blez/bgez/bltz: taken when Zero == 0.
    assign PCSrc = MEM_Branch & (MEM_Zero == MEM_BranchOnZero);

    DataMemory DataMem (
        .Address(MEM_ALUResult),
        .WriteData(MEM_WriteData),
        .Clk(Clk),
        .MemWrite(MEM_MemWrite),
        .MemRead(MEM_MemRead),
        .MemSize(MEM_MemSize),
        .ReadData(MEM_ReadData)
    );

    // =========================================================================
    // MEM/WB PIPELINE REGISTER
    // =========================================================================
    MEM_WB_Reg MEM_WB (
        .Clk(Clk),
        .Rst(Rst),
        .RegWrite_in(MEM_RegWrite),
        .MemToReg_in(MEM_MemToReg),
        .PCPlus4_in(MEM_PCPlus4),
        .ReadData_in(MEM_ReadData),
        .ALUResult_in(MEM_ALUResult),
        .WriteReg_in(MEM_WriteReg),
        .RegWrite_out(WB_RegWrite),
        .MemToReg_out(WB_MemToReg),
        .PCPlus4_out(WB_PCPlus4),
        .ReadData_out(WB_ReadData),
        .ALUResult_out(WB_ALUResult),
        .WriteReg_out(WB_WriteReg)
    );

    // =========================================================================
    // WB STAGE
    // =========================================================================
    Mux32Bit3To1 MemToRegMux (
        .out(WB_WriteData),
        .inA(WB_ALUResult),   // 00: ALU result
        .inB(WB_ReadData),    // 01: data memory
        .inC(WB_PCPlus4),     // 10: PC+4 (jal)
        .sel(WB_MemToReg)
    );

    // =========================================================================
    // TOP-LEVEL OUTPUTS (for simulation and the 7-segment display)
    // =========================================================================
    // PC of the instruction in WB = its PC+4 minus 4 (0 while the pipeline fills)
    assign PC        = (WB_PCPlus4 == 32'd0) ? 32'd0 : (WB_PCPlus4 - 32'd4);
    // value written to the register file, or 0 if nothing is written
    assign WriteData = WB_RegWrite ? WB_WriteData : 32'd0;

endmodule
