// =========================================================================
    // WIRE DECLARATIONS FOR MEM & WB STAGES
    // =========================================================================
    // EX/MEM Outputs (MEM Stage Wires)
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

    // Data Memory Output & Branch Logic Wire
    wire [31:0] MEM_ReadData;
    wire        PCSrc; // 1 = take branch in MEM stage

    // MEM/WB Outputs (WB Stage Wires)
    wire        WB_RegWrite;
    wire [1:0]  WB_MemToReg;
    wire [31:0] WB_PCPlus4;
    wire [31:0] WB_ReadData;
    wire [31:0] WB_ALUResult;
    wire [4:0]  WB_WriteReg;
    wire [31:0] WB_WriteData; // Final mux output sent to RegisterFile.WriteData

    // =========================================================================
    // EX/MEM PIPELINE REGISTER
    // =========================================================================
    EX_MEM_Reg EX_MEM (
        .Clk(Clk),
        .Rst(Rst),
        // Inputs from EX stage
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
        .WriteData_in(EX_ReadData2),
        .WriteReg_in(EX_WriteReg),
        // Outputs to MEM stage
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
    // MEMORY (MEM) STAGE
    // =========================================================================
    // Branch resolution: Controller sets BranchOnZero=1 for beq (taken when Zero==1),
    // and BranchOnZero=0 for bne/bgtz/blez/bgez/bltz (taken when ALUResult==1, so Zero==0).
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
        // Inputs from MEM stage
        .RegWrite_in(MEM_RegWrite),
        .MemToReg_in(MEM_MemToReg),
        .PCPlus4_in(MEM_PCPlus4),
        .ReadData_in(MEM_ReadData),
        .ALUResult_in(MEM_ALUResult),
        .WriteReg_in(MEM_WriteReg),
        // Outputs to WB stage
        .RegWrite_out(WB_RegWrite),
        .MemToReg_out(WB_MemToReg),
        .PCPlus4_out(WB_PCPlus4),
        .ReadData_out(WB_ReadData),
        .ALUResult_out(WB_ALUResult),
        .WriteReg_out(WB_WriteReg)
    );

    // =========================================================================
    // WRITE-BACK (WB) STAGE
    // =========================================================================
    Mux32Bit3To1 MemToRegMux (
        .out(WB_WriteData),
        .inA(WB_ALUResult), // 2'b00: ALU output
        .inB(WB_ReadData),  // 2'b01: DataMemory output
        .inC(WB_PCPlus4),   // 2'b10: PC + 4 (for jal)
        .sel(WB_MemToReg)
    );

    // Note: Connect WB_WriteReg, WB_WriteData, and WB_RegWrite directly to the 
    // WriteRegister, WriteData, and RegWrite ports of your RegisterFile in the ID stage!