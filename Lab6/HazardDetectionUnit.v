`timescale 1ns / 1ps

module HazardDetectionUnit #(
    parameter ENABLE_WB_STALL = 0 // Set to 1 if RegisterFile.v is unchanged; set to 0 if using RegisterFile WB bypass
)(
    input  [5:0] Opcode_ID,
    input  [5:0] Funct_ID,
    input  [4:0] Rs_ID,
    input  [4:0] Rt_ID,

    input        EX_RegWrite,
    input  [4:0] EX_WriteReg,
    input        MEM_RegWrite,
    input  [4:0] MEM_WriteReg,
    input        WB_RegWrite,
    input  [4:0] WB_WriteReg,

    output reg   PCWrite,
    output reg   IF_ID_Write,
    output reg   ControlMux_Stall // 1 = stall pipeline and insert NOP bubble into ID/EX
);

    localparam RTYPE  = 6'b000000;
    localparam J      = 6'b000010;
    localparam JAL    = 6'b000011;
    localparam BEQ    = 6'b000100;
    localparam BNE    = 6'b000101;
    localparam MUL    = 6'b011100;
    localparam SB     = 6'b101000;
    localparam SH     = 6'b101001;
    localparam SW     = 6'b101011;

    localparam F_SLL  = 6'b000000;
    localparam F_SRL  = 6'b000010;
    localparam F_JR   = 6'b001000;

    reg uses_rs;
    reg uses_rt;

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
    end

    wire hazard_EX  = EX_RegWrite  && (EX_WriteReg  != 5'd0) &&
                      ((uses_rs && (EX_WriteReg  == Rs_ID)) || (uses_rt && (EX_WriteReg  == Rt_ID)));

    wire hazard_MEM = MEM_RegWrite && (MEM_WriteReg != 5'd0) &&
                      ((uses_rs && (MEM_WriteReg == Rs_ID)) || (uses_rt && (MEM_WriteReg == Rt_ID)));

    wire hazard_WB  = ENABLE_WB_STALL && WB_RegWrite && (WB_WriteReg != 5'd0) &&
                      ((uses_rs && (WB_WriteReg  == Rs_ID)) || (uses_rt && (WB_WriteReg  == Rt_ID)));

    wire stall = hazard_EX || hazard_MEM || hazard_WB;

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