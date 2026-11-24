`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// ECE369A - Computer Organization (Lab 8 competition)
// Group 17
//
// Module - ForwardingUnit.v
// Description - Decides where the EX stage should get its two register
//               operands (rs -> ALU side A, rt -> ALU side B / store data).
//
//   The instruction in EX read its registers back in ID. If an instruction
//   ahead of it (now in MEM or WB) writes one of those registers, the value
//   read in ID is stale. The correct value already exists further down the
//   pipeline, so we take it from there instead of stalling:
//
//     ForwardX = 2'b00 : use the value read from the register file (no hazard)
//     ForwardX = 2'b10 : take it from EX/MEM  (instruction 1 ahead, now in MEM)
//     ForwardX = 2'b01 : take it from MEM/WB  (instruction 2 ahead, now in WB)
//
//   EX/MEM has priority: if both later instructions write the same register,
//   the one in MEM is newer (it came later in program order).
//
//   A load in MEM is never forwarded from EX/MEM (its data isn't read until
//   the end of MEM). The hazard unit stalls a load-use pair for one cycle, so
//   by the time the user reaches EX, the load is in WB and 2'b01 is used.
//
//   ENABLE_FORWARDING = 0 forces 2'b00, giving the original stall-only design
//   (used to report cycles with and without forwarding).
////////////////////////////////////////////////////////////////////////////////

module ForwardingUnit #(
    parameter ENABLE_FORWARDING = 1
)(
    input  [4:0] EX_Rs,          // rs of the instruction in EX
    input  [4:0] EX_Rt,          // rt of the instruction in EX
    input        MEM_RegWrite,   // instruction in MEM writes a register?
    input  [4:0] MEM_WriteReg,   //   ...which one
    input        WB_RegWrite,    // instruction in WB writes a register?
    input  [4:0] WB_WriteReg,    //   ...which one
    output reg [1:0] ForwardA,   // select for the rs operand
    output reg [1:0] ForwardB    // select for the rt operand
);

    localparam FROM_REGFILE = 2'b00;
    localparam FROM_MEM     = 2'b10;
    localparam FROM_WB      = 2'b01;

    // A later stage can supply a register only if it really writes one,
    // and never for $zero (writes to $0 are discarded).
    wire mem_writes = ENABLE_FORWARDING && MEM_RegWrite && (MEM_WriteReg != 5'd0);
    wire wb_writes  = ENABLE_FORWARDING && WB_RegWrite  && (WB_WriteReg  != 5'd0);

    always @(*) begin
        // ---------- operand A (rs) ----------
        if (mem_writes && (MEM_WriteReg == EX_Rs))
            ForwardA = FROM_MEM;          // newest value wins
        else if (wb_writes && (WB_WriteReg == EX_Rs))
            ForwardA = FROM_WB;
        else
            ForwardA = FROM_REGFILE;

        // ---------- operand B (rt) ----------
        if (mem_writes && (MEM_WriteReg == EX_Rt))
            ForwardB = FROM_MEM;
        else if (wb_writes && (WB_WriteReg == EX_Rt))
            ForwardB = FROM_WB;
        else
            ForwardB = FROM_REGFILE;
    end

endmodule
