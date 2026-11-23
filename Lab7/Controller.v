`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// ECE369 - Computer Architecture
//
// Module - Controller.v
// Description - Combinational main controller. Decodes Opcode / Funct / Rt
//               into every datapath control signal.
//
// INPUTS:-
// Opcode : instr[31:26]
// Funct  : instr[5:0]    (R-type and mul)
// Rt     : instr[20:16]  (only used to tell bgez from bltz)
//
// OUTPUTS:-
// RegWrite     : 1 = write register file
// RegDst       : 00 = rt, 01 = rd, 10 = $31 (jal)
// ALUSrc       : 0 = ALU B from register, 1 = from immediate
// ExtOp        : 1 = sign-extend immediate, 0 = zero-extend (andi/ori/xori)
// Shift        : 1 = sll/srl (ALU A = rt, ALU B = shamt)
// ALUControl   : operation code sent to ALU32Bit
// MemRead      : 1 = load
// MemWrite     : 1 = store
// Me      : 00 = word, 01 = half, 10 = byte
// MemToReg     : 00 = ALU result, 01 = memory data, 10 = PC+4 (jal)
// Branch       : 1 = branch instruction
// BranchOnZero : branch taken when Zero == BranchOnZero
// Jump         : 1 = j / jal
// JumpReg      : 1 = jr
////////////////////////////////////////////////////////////////////////////////

module Controller(Opcode, Funct, Rt,
                  RegWrite, RegDst, ALUSrc, ExtOp, Shift, ALUControl,
                  MemRead, MemWrite, MemSize, MemToReg,
                  Branch, BranchOnZero, Jump, JumpReg);

    input  [5:0] Opcode;
    input  [5:0] Funct;
    input  [4:0] Rt;

    output reg       RegWrite;
    output reg [1:0] RegDst;
    output reg       ALUSrc;
    output reg       ExtOp;
    output reg       Shift;
    output reg [4:0] ALUControl;
    output reg       MemRead;
    output reg       MemWrite;
    output reg [1:0] MemSize;
    output reg [1:0] MemToReg;
    output reg       Branch;
    output reg       BranchOnZero;
    output reg       Jump;
    output reg       JumpReg;

    // ---------------- Opcodes (instr[31:26]) ----------------
    localparam RTYPE  = 6'b000000;   // add sub and or xor nor slt sll srl jr
    localparam REGIMM = 6'b000001;   // bgez / bltz (picked by Rt)
    localparam J      = 6'b000010;
    localparam JAL    = 6'b000011;
    localparam BEQ    = 6'b000100;
    localparam BNE    = 6'b000101;
    localparam BLEZ   = 6'b000110;
    localparam BGTZ   = 6'b000111;
    localparam ADDI   = 6'b001000;
    localparam SLTI   = 6'b001010;
    localparam ANDI   = 6'b001100;
    localparam ORI    = 6'b001101;
    localparam XORI   = 6'b001110;
    localparam MUL    = 6'b011100;   // with Funct = 000010
    localparam LB     = 6'b100000;
    localparam LH     = 6'b100001;
    localparam LW     = 6'b100011;
    localparam SB     = 6'b101000;
    localparam SH     = 6'b101001;
    localparam SW     = 6'b101011;

    // ---------------- Funct codes (instr[5:0]) ----------------
    localparam F_SLL = 6'b000000;
    localparam F_SRL = 6'b000010;
    localparam F_JR  = 6'b001000;
    localparam F_ADD = 6'b100000;
    localparam F_SUB = 6'b100010;
    localparam F_AND = 6'b100100;
    localparam F_OR  = 6'b100101;
    localparam F_XOR = 6'b100110;
    localparam F_NOR = 6'b100111;
    localparam F_SLT = 6'b101010;
    localparam F_MUL = 6'b000010;    // under opcode MUL

    // ---------------- Rt codes (opcode REGIMM) ----------------
    localparam RT_BLTZ = 5'b00000;
    localparam RT_BGEZ = 5'b00001;

    always @(*) begin
        // ---------- defaults: do nothing (prevents latches) ----------
        RegWrite     = 1'b0;
        RegDst       = 2'b00;
        ALUSrc       = 1'b0;
        ExtOp        = 1'b1;
        Shift        = 1'b0;
        ALUControl   = 5'd0;
        MemRead      = 1'b0;
        MemWrite     = 1'b0;
        MemSize      = 2'b00;
        MemToReg     = 2'b00;
        Branch       = 1'b0;
        BranchOnZero = 1'b0;
        Jump         = 1'b0;
        JumpReg      = 1'b0;

        case (Opcode)

            // ======================= R-TYPE =======================
            RTYPE: begin
                RegWrite = 1'b1;
                RegDst   = 2'b01;                    // rd
                case (Funct)
                    F_ADD: ALUControl = 5'd0;        // add
                    F_SUB: ALUControl = 5'd1;        // sub
                    F_AND: ALUControl = 5'd3;        // and
                    F_OR:  ALUControl = 5'd4;        // or
                    F_XOR: ALUControl = 5'd5;        // xor
                    F_NOR: ALUControl = 5'd6;        // nor
                    F_SLT: ALUControl = 5'd9;        // slt
                    F_SLL: begin                     // sll (also nop)
                        ALUControl = 5'd7;
                        Shift      = 1'b1;
                    end
                    F_SRL: begin                     // srl
                        ALUControl = 5'd8;
                        Shift      = 1'b1;
                    end
                    F_JR: begin                      // jr
                        RegWrite = 1'b0;
                        JumpReg  = 1'b1;
                    end
                    default: RegWrite = 1'b0;        // unknown: do nothing
                endcase
            end

            MUL: begin
                if (Funct == F_MUL) begin
                    RegWrite   = 1'b1;
                    RegDst     = 2'b01;              // rd
                    ALUControl = 5'd2;               // mul
                end
            end

            // ================= I-TYPE ARITHMETIC / LOGIC =================
            ADDI: begin
                RegWrite   = 1'b1;
                ALUSrc     = 1'b1;
                ALUControl = 5'd0;                   // add
            end

            SLTI: begin
                RegWrite   = 1'b1;
                ALUSrc     = 1'b1;
                ALUControl = 5'd9;                   // slt
            end

            ANDI: begin
                RegWrite   = 1'b1;
                ALUSrc     = 1'b1;
                ExtOp      = 1'b0;                   // zero-extend
                ALUControl = 5'd3;                   // and
            end

            ORI: begin
                RegWrite   = 1'b1;
                ALUSrc     = 1'b1;
                ExtOp      = 1'b0;                   // zero-extend
                ALUControl = 5'd4;                   // or
            end

            XORI: begin
                RegWrite   = 1'b1;
                ALUSrc     = 1'b1;
                ExtOp      = 1'b0;                   // zero-extend
                ALUControl = 5'd5;                   // xor
            end

            // ============ LOADS (address = rs + imm, ALU add) ============
            LW: begin
                RegWrite = 1'b1;
                ALUSrc   = 1'b1;
                MemRead  = 1'b1;
                MemToReg = 2'b01;                    // memory data
                MemSize  = 2'b00;                    // word
            end

            LH: begin
                RegWrite = 1'b1;
                ALUSrc   = 1'b1;
                MemRead  = 1'b1;
                MemToReg = 2'b01;                    // memory data
                MemSize  = 2'b01;                    // half
            end

            LB: begin
                RegWrite = 1'b1;
                ALUSrc   = 1'b1;
                MemRead  = 1'b1;
                MemToReg = 2'b01;                    // memory data
                MemSize  = 2'b10;                    // byte
            end

            // ============ STORES (address = rs + imm, ALU add) ============
            SW: begin
                ALUSrc   = 1'b1;
                MemWrite = 1'b1;
                MemSize  = 2'b00;                    // word
            end

            SH: begin
                ALUSrc   = 1'b1;
                MemWrite = 1'b1;
                MemSize  = 2'b01;                    // half
            end

            SB: begin
                ALUSrc   = 1'b1;
                MemWrite = 1'b1;
                MemSize  = 2'b10;                    // byte
            end

            // ============ BRANCHES (taken when Zero == BranchOnZero) ============
            BEQ: begin
                Branch       = 1'b1;
                BranchOnZero = 1'b1;                 // equal -> Zero = 1
                ALUControl   = 5'd1;                 // sub
            end

            BNE: begin
                Branch       = 1'b1;
                BranchOnZero = 1'b0;                 // not equal -> Zero = 0
                ALUControl   = 5'd1;                 // sub
            end

            BGTZ: begin
                Branch       = 1'b1;
                BranchOnZero = 1'b0;                 // true -> result 1 -> Zero = 0
                ALUControl   = 5'd11;                // bgtz
            end

            BLEZ: begin
                Branch       = 1'b1;
                BranchOnZero = 1'b0;
                ALUControl   = 5'd12;                // blez
            end

            REGIMM: begin
                case (Rt)
                    RT_BGEZ: begin
                        Branch       = 1'b1;
                        BranchOnZero = 1'b0;
                        ALUControl   = 5'd10;        // bgez
                    end
                    RT_BLTZ: begin
                        Branch       = 1'b1;
                        BranchOnZero = 1'b0;
                        ALUControl   = 5'd13;        // bltz
                    end
                    default: ;                       // unknown: do nothing
                endcase
            end

            // ======================= JUMPS =======================
            J: begin
                Jump = 1'b1;
            end

            JAL: begin
                Jump     = 1'b1;
                RegWrite = 1'b1;
                RegDst   = 2'b10;                    // $31
                MemToReg = 2'b10;                    // PC+4
            end

            default: ;                               // unknown opcode: do nothing
        endcase
    end

endmodule