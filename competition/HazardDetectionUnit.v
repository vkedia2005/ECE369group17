`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// ECE369A - Computer Organization
// Group 17
//
// Module - HazardDetectionUnit.v
// Description - Decides when the instruction in ID must wait (stall).
//   On a stall: PC and IF/ID hold, and a bubble (all control = 0) goes into
//   ID/EX.
//
//   ENABLE_FORWARDING = 0 (Lab 6/7 behavior): stall whenever an instruction in
//   EX or MEM will write a register the ID instruction reads.
//
//   ENABLE_FORWARDING = 1 (Lab 8): forwarding supplies most values, so only
//   stall when the value does not exist yet:
//     1. Load-use: a LOAD in EX writes a register the ID instruction reads.
//        (Its data appears only at the end of MEM.)              -> 1 stall
//     2. A branch or jr in ID (they compare/jump in ID) reads a register
//        written by ANY instruction in EX (still being computed). -> 1 stall
//     3. A branch or jr in ID reads a register written by a LOAD in MEM
//        (memory not read yet).                                   -> 1 stall
//   A branch depending on a load therefore waits 2 cycles (rules 2 then 3).
//   Producers in WB never stall: the register file write-through covers them.
////////////////////////////////////////////////////////////////////////////////

module HazardDetectionUnit #(
    parameter ENABLE_WB_STALL   = 0,   // 1 only if RegisterFile has no WB bypass
    parameter ENABLE_FORWARDING = 1    // Lab 8: 0 = original stall-only rules
)(
    input  [5:0] Opcode_ID,
    input  [5:0] Funct_ID,
    input  [4:0] Rs_ID,
    input  [4:0] Rt_ID,
    input        EX_RegWrite,
    input        EX_MemRead,      // Lab 8: instruction in EX is a load
    input  [4:0] EX_WriteReg,
    input        MEM_RegWrite,
    input        MEM_MemRead,     // Lab 8: instruction in MEM is a load
    input  [4:0] MEM_WriteReg,
    input        WB_RegWrite,
    input  [4:0] WB_WriteReg,
    output reg   PCWrite,
    output reg   IF_ID_Write,
    output reg   ControlMux_Stall // 1 = stall pipeline and insert NOP bubble into ID/EX
);

    localparam RTYPE  = 6'b000000;
    localparam REGIMM = 6'b000001;   // bgez / bltz
    localparam J      = 6'b000010;
    localparam JAL    = 6'b000011;
    localparam BEQ    = 6'b000100;
    localparam BNE    = 6'b000101;
    localparam BLEZ   = 6'b000110;
    localparam BGTZ   = 6'b000111;
    localparam MUL    = 6'b011100;
    localparam SB     = 6'b101000;
    localparam SH     = 6'b101001;
    localparam SW     = 6'b101011;
    localparam F_SLL  = 6'b000000;
    localparam F_SRL  = 6'b000010;
    localparam F_JR   = 6'b001000;

    reg uses_rs;
    reg uses_rt;
    reg uses_in_id;   // Lab 8: reads its registers in ID (branches and jr)

    always @(*) begin
        // Does the instruction in ID read rs?
        case (Opcode_ID)
            J, JAL:  uses_rs = 1'b0;
            RTYPE:   uses_rs = (Funct_ID == F_SLL || Funct_ID == F_SRL) ? 1'b0 : 1'b1;
            default: uses_rs = 1'b1; // All other R-type, MUL, loads, stores, I-type ALU, branches, jr read rs
        endcase

        // Does the instruction in ID read rt as a source operand?
        case (Opcode_ID)
            RTYPE:   uses_rt = (Funct_ID == F_JR) ? 1'b0 : 1'b1; // All R-type except jr read rt (including sll/srl)
            MUL,
            SW, SH, SB,
            BEQ, BNE: uses_rt = 1'b1;
            default:  uses_rt = 1'b0; // Loads, I-type ALU, bgez/bltz/bgtz/blez, j, jal do NOT read rt
        endcase

        // Does it need its registers already in ID? (branches compare in ID, jr jumps in ID)
        case (Opcode_ID)
            BEQ, BNE, BLEZ, BGTZ, REGIMM: uses_in_id = 1'b1;
            RTYPE:                        uses_in_id = (Funct_ID == F_JR);
            default:                      uses_in_id = 1'b0;
        endcase
    end

    // Does a later instruction write a register that the ID instruction reads?
    wire match_EX  = EX_RegWrite  && (EX_WriteReg  != 5'd0) &&
                     ((uses_rs && (EX_WriteReg  == Rs_ID)) || (uses_rt && (EX_WriteReg  == Rt_ID)));
    wire match_MEM = MEM_RegWrite && (MEM_WriteReg != 5'd0) &&
                     ((uses_rs && (MEM_WriteReg == Rs_ID)) || (uses_rt && (MEM_WriteReg == Rt_ID)));
    wire match_WB  = WB_RegWrite  && (WB_WriteReg  != 5'd0) &&
                     ((uses_rs && (WB_WriteReg  == Rs_ID)) || (uses_rt && (WB_WriteReg  == Rt_ID)));

    // ---------- original rules (no forwarding) ----------
    wire stall_noFwd = match_EX || match_MEM || (ENABLE_WB_STALL && match_WB);

    // ---------- Lab 8 rules (with forwarding) ----------
    wire load_use       = match_EX && EX_MemRead;                  // rule 1
    wire branch_on_EX   = match_EX && uses_in_id;                  // rule 2
    wire branch_on_load = match_MEM && MEM_MemRead && uses_in_id;  // rule 3
    wire stall_fwd      = load_use || branch_on_EX || branch_on_load ||
                          (ENABLE_WB_STALL && match_WB);

    wire stall = ENABLE_FORWARDING ? stall_fwd : stall_noFwd;

    always @(*) begin
        if (stall) begin
            PCWrite          = 1'b0;
            IF_ID_Write      = 1'b0;
            ControlMux_Stall = 1'b1;
        end else begin
            PCWrite          = 1'b1;
            IF_ID_Write      = 1'b1;
            ControlMux_Stall = 1'b0;
        end
    end

endmodule
