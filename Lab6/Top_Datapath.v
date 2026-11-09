`timescale 1ns / 1ps

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

    // ---------------- Hazard & Flush signals ----------------
    wire        PCWrite;
    wire        IF_ID_Write;
    wire        ControlMux_Stall;
    wire        IF_Flush;

    // ---------------- ID stage ----------------
    wire [31:0] ID_PCPlus4;
    wire [31:0] ID_Instruction;
    wire [31:0] ID_ReadData1;
    wire [31:0] ID_ReadData2;
    wire [31:0] ID_Imm;
    wire [31:0] ID_JumpTarget;
    wire [31:0] ID_BranchTarget;
    reg         ID_BranchCond;
    wire        ID_PCSrc;

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
    wire [31:0] MEM_ReadData;

    // ---------------- WB stage (MEM/WB outputs) ----------------
    wire        WB_RegWrite;
    wire [1:0]  WB_MemToReg;
    wire [31:0] WB_PCPlus4;
    wire [31:0] WB_ReadData;
    wire [31:0] WB_ALUResult;
    wire [4:0]  WB_WriteReg;
    wire [31:0] WB_WriteData;

    // =========================================================================
    // IF STAGE (Redirects resolved in ID Stage, gated by ~ControlMux_Stall)
    // =========================================================================
    always @(*) begin
        if (!ControlMux_Stall && ID_Jump)
            NextPC = ID_JumpTarget;     // j / jal resolved in ID
        else if (!ControlMux_Stall && ID_JumpReg)
            NextPC = ID_ReadData1;      // jr resolved in ID
        else if (!ControlMux_Stall && ID_PCSrc)
            NextPC = ID_BranchTarget;   // taken branch resolved in ID
        else
            NextPC = IF_PCPlus4;        // sequential PC + 4
    end

    // Flush the speculatively fetched instruction in IF when a branch/jump in ID is taken
    assign IF_Flush = (!ControlMux_Stall) && (ID_Jump || ID_JumpReg || ID_PCSrc);

    ProgramCounter PCReg (
        .Clk(Clk),
        .Rst(Rst),
        .PCWrite(PCWrite),
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
        .IF_ID_Write(IF_ID_Write),
        .IF_Flush(IF_Flush),
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

    HazardDetectionUnit #(
        .ENABLE_WB_STALL(0)
    ) HDU (
        .Opcode_ID(ID_Instruction[31:26]),
        .Funct_ID(ID_Instruction[5:0]),
        .Rs_ID(ID_Instruction[25:21]),
        .Rt_ID(ID_Instruction[20:16]),
        .EX_RegWrite(EX_RegWrite),
        .EX_WriteReg(EX_WriteReg),
        .MEM_RegWrite(MEM_RegWrite),
        .MEM_WriteReg(MEM_WriteReg),
        .WB_RegWrite(WB_RegWrite),
        .WB_WriteReg(WB_WriteReg),
        .PCWrite(PCWrite),
        .IF_ID_Write(IF_ID_Write),
        .ControlMux_Stall(ControlMux_Stall)
    );

    RegisterFile RegFile (
        .ReadRegister1(ID_Instruction[25:21]),
        .ReadRegister2(ID_Instruction[20:16]),
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

    // Branch target adder moved to ID stage: PC+4 + (sign_ext_imm << 2)
    Adder32Bit BranchAdder (
        .A(ID_PCPlus4),
        .B({ID_Imm[29:0], 2'b00}),
        .Sum(ID_BranchTarget)
    );

    // ID-stage branch comparator for beq, bne, bgtz, blez, bgez, bltz
    wire signed [31:0] ID_SignedRs = ID_ReadData1;
    always @(*) begin
        case (ID_Instruction[31:26])
            6'b000100: ID_BranchCond = (ID_ReadData1 == ID_ReadData2); // beq
            6'b000101: ID_BranchCond = (ID_ReadData1 != ID_ReadData2); // bne
            6'b000111: ID_BranchCond = (ID_SignedRs >  0);             // bgtz
            6'b000110: ID_BranchCond = (ID_SignedRs <= 0);             // blez
            6'b000001: begin                                           // REGIMM
                if (ID_Instruction[20:16] == 5'b00001)
                    ID_BranchCond = (ID_SignedRs >= 0);                // bgez
                else
                    ID_BranchCond = (ID_SignedRs <  0);                // bltz
            end
            default:   ID_BranchCond = 1'b0;
        endcase
    end

    assign ID_PCSrc = ID_Branch & ID_BranchCond;

    // =========================================================================
    // ID/EX PIPELINE REGISTER (with ControlMux_Stall bubble injection)
    // =========================================================================
    ID_EX_Reg ID_EX (
        .Clk(Clk),
        .Rst(Rst),
        // control in (zeroed when ControlMux_Stall == 1 to insert NOP bubble)
        .RegWrite_in(ControlMux_Stall ? 1'b0  : ID_RegWrite),
        .MemToReg_in(ControlMux_Stall ? 2'b00 : ID_MemToReg),
        .MemRead_in(ControlMux_Stall  ? 1'b0  : ID_MemRead),
        .MemWrite_in(ControlMux_Stall ? 1'b0  : ID_MemWrite),
        .MemSize_in(ControlMux_Stall  ? 2'b00 : ID_MemSize),
        .Branch_in(ControlMux_Stall   ? 1'b0  : ID_Branch),
        .BranchOnZero_in(ControlMux_Stall ? 1'b0 : ID_BranchOnZero),
        .Jump_in(ControlMux_Stall     ? 1'b0  : ID_Jump),
        .JumpReg_in(ControlMux_Stall  ? 1'b0  : ID_JumpReg),
        .ALUSrc_in(ControlMux_Stall   ? 1'b0  : ID_ALUSrc),
        .Shift_in(ControlMux_Stall    ? 1'b0  : ID_Shift),
        .ALUControl_in(ControlMux_Stall ? 5'd0 : ID_ALUControl),
        .RegDst_in(ControlMux_Stall   ? 2'b00 : ID_RegDst),
        // data in (zero PCPlus4 on bubble so WB displays PC=0 during stall bubbles)
        .PCPlus4_in(ControlMux_Stall  ? 32'd0 : ID_PCPlus4),
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
    Mux32Bit2To1 ALUAMux (
        .out(EX_ALUInA),
        .inA(EX_ReadData1),
        .inB(EX_ReadData2),
        .sel(EX_Shift)
    );

    Mux32Bit2To1 ALUSrcMux (
        .out(EX_RegOrImm),
        .inA(EX_ReadData2),
        .inB(EX_Imm),
        .sel(EX_ALUSrc)
    );

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
        .ALUResult64(),
        .Zero(EX_Zero)
    );

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
        .BranchTarget_in(32'd0),
        .JumpTarget_in(EX_JumpTarget),
        .ReadData1_in(EX_ReadData1),
        .ALUResult_in(EX_ALUResult),
        .Zero_in(EX_Zero),
        .WriteData_in(EX_ReadData2),
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
        .inA(WB_ALUResult),
        .inB(WB_ReadData),
        .inC(WB_PCPlus4),
        .sel(WB_MemToReg)
    );

    // =========================================================================
    // TOP-LEVEL OUTPUTS (for simulation and the 7-segment display)
    // =========================================================================
    assign PC        = (WB_PCPlus4 == 32'd0) ? 32'd0 : (WB_PCPlus4 - 32'd4);
    assign WriteData = WB_RegWrite ? WB_WriteData : 32'd0;

endmodule