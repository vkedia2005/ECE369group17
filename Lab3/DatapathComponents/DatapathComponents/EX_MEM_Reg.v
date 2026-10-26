`timescale 1ns / 1ps

module EX_MEM_Reg(
    input         Clk,
    input         Reset,
    
    // Control Signals (WB Stage)
    input         RegWrite_in,
    input  [1:0]  MemToReg_in,
    
    // Control Signals (MEM Stage)
    input         MemRead_in,
    input         MemWrite_in,
    input  [1:0]  MemSize_in,
    input         Branch_in,
    input         BranchOnZero_in,
    
    // Data Signals
    input  [31:0] PCPlus4_in,
    input  [31:0] BranchTarget_in,
    input         Zero_in,
    input  [31:0] ALUResult_in,
    input  [31:0] WriteData_in,    // ReadData2 from ID/EX
    input  [4:0]  WriteReg_in,     // Selected destination register (rt, rd, or $31)

    // Outputs to MEM Stage
    output reg        RegWrite_out,
    output reg [1:0]  MemToReg_out,
    output reg        MemRead_out,
    output reg        MemWrite_out,
    output reg [1:0]  MemSize_out,
    output reg        Branch_out,
    output reg        BranchOnZero_out,
    output reg [31:0] PCPlus4_out,
    output reg [31:0] BranchTarget_out,
    output reg        Zero_out,
    output reg [31:0] ALUResult_out,
    output reg [31:0] WriteData_out,
    output reg [4:0]  WriteReg_out
);

    alwaysTo complete the **MEM** and **WB** stages for your pipelined datapath, you need the two final pipeline registers (`EX_MEM_Reg.v` and `MEM_WB_Reg.v`), a 3-to-1 multiplexer for the `MemToReg` signal (`Mux32Bit3To1.v`), and the top-level structural wiring to connect your `DataMemory` and `RegisterFile`.

Because your `Controller.v` outputs a 2-bit `MemToReg` signal to support `jal` (`00` = ALU result, `01` = memory data, `10` = `PC+4`) and a `BranchOnZero` signal to distinguish between `beq` (`Zero == 1`) and `bne`/`bgtz`/`blez`/`bgez`/`bltz` (`Zero == 0`)[cite: 11], the pipeline registers and branch resolution logic below are tailored specifically to match your controller's exact signals[cite: 11].

---

### 1. EX/MEM Pipeline Register (`EX_MEM_Reg.v`)
This register sits at the boundary between the Execute and Memory stages. It captures the control signals needed by MEM and WB, the calculated branch/jump targets, the ALU outputs, and the selected 5-bit destination register (`WriteReg`).

```verilog
`timescale 1ns / 1ps

module EX_MEM_Reg(
    input         Clk,
    input         Rst,

    // WB Control Signals
    input         RegWrite_in,
    input  [1:0]  MemToReg_in,

    // MEM Control Signals
    input         MemRead_in,
    input         MemWrite_in,
    input  [1:0]  MemSize_in,
    input         Branch_in,
    input         BranchOnZero_in,
    input         Jump_in,
    input         JumpReg_in,

    // Datapath Values
    input  [31:0] PCPlus4_in,       // Needed for jal write-back
    input  [31:0] BranchTarget_in,  // PC + 4 + (imm << 2)
    input  [31:0] JumpTarget_in,    // {PCPlus4, instr[25:0], 2'b00}
    input  [31:0] ReadData1_in,     // rs value (target for jr)
    input  [31:0] ALUResult_in,
    input         Zero_in,
    input  [31:0] WriteData_in,     // rt value (data to store for sw/sh/sb)
    input  [4:0]  WriteReg_in,      // Selected destination register (rt, rd, or $31)

    // Outputs to MEM Stage
    output reg        RegWrite_out,
    output reg [1:0]  MemToReg_out,
    output reg        MemRead_out,
    output reg        MemWrite_out,
    output reg [1:0]  MemSize_out,
    output reg        Branch_out,
    output reg        BranchOnZero_out,
    output reg        Jump_out,
    output reg        JumpReg_out,
    output reg [31:0] PCPlus4_out,
    output reg [31:0] BranchTarget_out,
    output reg [31:0] JumpTarget_out,
    output reg [31:0] ReadData1_out,
    output reg [31:0] ALUResult_out,
    output reg        Zero_out,
    output reg [31:0] WriteData_out,
    output reg [4:0]  WriteReg_out
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
            PCPlus4_out      <= 32'd0;
            BranchTarget_out <= 32'd0;
            JumpTarget_out   <= 32'd0;
            ReadData1_out    <= 32'd0;
            ALUResult_out    <= 32'd0;
            Zero_out         <= 1'b0;
            WriteData_out    <= 32'd0;
            WriteReg_out     <= 5'd0;
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
            PCPlus4_out      <= PCPlus4_in;
            BranchTarget_out <= BranchTarget_in;
            JumpTarget_out   <= JumpTarget_in;
            ReadData1_out    <= ReadData1_in;
            ALUResult_out    <= ALUResult_in;
            Zero_out         <= Zero_in;
            WriteData_out    <= WriteData_in;
            WriteReg_out     <= WriteReg_in;
        end
    end

endmodule