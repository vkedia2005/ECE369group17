`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// ECE369 - Computer Architecture
//
// Module - Controller_tb.v
// Description - Feeds every Table 1 instruction (plus nop and some invalid
//               encodings) into Controller.v and checks all 14 outputs.
//               Prints PASS/FAIL per instruction and a summary.
////////////////////////////////////////////////////////////////////////////////

module Controller_tb();

    reg  [5:0] Opcode;
    reg  [5:0] Funct;
    reg  [4:0] Rt;

    wire       RegWrite, ALUSrc, ExtOp, Shift;
    wire [1:0] RegDst, MemSize, MemToReg;
    wire [4:0] ALUControl;
    wire       MemRead, MemWrite, Branch, BranchOnZero, Jump, JumpReg;

    // ---------------- Opcodes (same values as Controller.v) ----------------
    localparam RTYPE  = 6'b000000;
    localparam REGIMM = 6'b000001;
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
    localparam MUL    = 6'b011100;
    localparam LB     = 6'b100000;
    localparam LH     = 6'b100001;
    localparam LW     = 6'b100011;
    localparam SB     = 6'b101000;
    localparam SH     = 6'b101001;
    localparam SW     = 6'b101011;

    // ---------------- Funct codes ----------------
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
    localparam F_MUL = 6'b000010;

    integer errors = 0;

    Controller u0(
        .Opcode(Opcode), .Funct(Funct), .Rt(Rt),
        .RegWrite(RegWrite), .RegDst(RegDst), .ALUSrc(ALUSrc), .ExtOp(ExtOp),
        .Shift(Shift), .ALUControl(ALUControl),
        .MemRead(MemRead), .MemWrite(MemWrite), .MemSize(MemSize), .MemToReg(MemToReg),
        .Branch(Branch), .BranchOnZero(BranchOnZero), .Jump(Jump), .JumpReg(JumpReg)
    );

    // all outputs packed into one 21-bit vector for easy comparison
    wire [20:0] got = {RegWrite, RegDst, ALUSrc, ExtOp, Shift, ALUControl,
                       MemRead, MemWrite, MemSize, MemToReg,
                       Branch, BranchOnZero, Jump, JumpReg};

    // Apply one instruction and compare every output to the expected values.
    task check(input [8*8-1:0] name,
               input [5:0] op, input [5:0] fn, input [4:0] rt,
               input rw, input [1:0] rd, input as, input ex, input sh,
               input [4:0] alu, input mr, input mw, input [1:0] sz,
               input [1:0] m2r, input br, input bz, input j, input jr);
        reg [20:0] exp;
        begin
            Opcode = op;
            Funct  = fn;
            Rt     = rt;
            #10;
            exp = {rw, rd, as, ex, sh, alu, mr, mw, sz, m2r, br, bz, j, jr};
            if (got === exp)
                $display("PASS  %0s", name);
            else begin
                $display("FAIL  %0s", name);
                $display("        RW RD AS EX SH ALU MR MW SZ M2R BR BZ J JR");
                $display("  got   %b  %0d  %b  %b  %b  %2d  %b  %b  %0d  %0d   %b  %b  %b %b",
                         RegWrite, RegDst, ALUSrc, ExtOp, Shift, ALUControl,
                         MemRead, MemWrite, MemSize, MemToReg,
                         Branch, BranchOnZero, Jump, JumpReg);
                $display("  exp   %b  %0d  %b  %b  %b  %2d  %b  %b  %0d  %0d   %b  %b  %b %b",
                         rw, rd, as, ex, sh, alu, mr, mw, sz, m2r, br, bz, j, jr);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        Opcode = 6'd0; Funct = 6'd0; Rt = 5'd0;
        #10;

        // Columns:  RW RD AS EX SH ALU MR MW SZ M2R BR BZ J JR
        // RD: 0=rt 1=rd 2=$31   SZ: 0=word 1=half 2=byte   M2R: 0=ALU 1=mem 2=PC+4
        // Rt = 9 on non-REGIMM instructions to show it is ignored.

        // ---------------- R-type ----------------
        //     name      op     fn     rt     RW RD AS EX SH ALU MR MW SZ M2R BR BZ J  JR
        check("add",     RTYPE, F_ADD, 5'd9,  1, 1, 0, 1, 0,  0, 0, 0, 0, 0,  0, 0, 0, 0);
        check("sub",     RTYPE, F_SUB, 5'd9,  1, 1, 0, 1, 0,  1, 0, 0, 0, 0,  0, 0, 0, 0);
        check("and",     RTYPE, F_AND, 5'd9,  1, 1, 0, 1, 0,  3, 0, 0, 0, 0,  0, 0, 0, 0);
        check("or",      RTYPE, F_OR,  5'd9,  1, 1, 0, 1, 0,  4, 0, 0, 0, 0,  0, 0, 0, 0);
        check("xor",     RTYPE, F_XOR, 5'd9,  1, 1, 0, 1, 0,  5, 0, 0, 0, 0,  0, 0, 0, 0);
        check("nor",     RTYPE, F_NOR, 5'd9,  1, 1, 0, 1, 0,  6, 0, 0, 0, 0,  0, 0, 0, 0);
        check("slt",     RTYPE, F_SLT, 5'd9,  1, 1, 0, 1, 0,  9, 0, 0, 0, 0,  0, 0, 0, 0);
        check("sll",     RTYPE, F_SLL, 5'd9,  1, 1, 0, 1, 1,  7, 0, 0, 0, 0,  0, 0, 0, 0);
        check("srl",     RTYPE, F_SRL, 5'd9,  1, 1, 0, 1, 1,  8, 0, 0, 0, 0,  0, 0, 0, 0);
        check("jr",      RTYPE, F_JR,  5'd9,  0, 1, 0, 1, 0,  0, 0, 0, 0, 0,  0, 0, 0, 1);
        check("nop",     RTYPE, F_SLL, 5'd0,  1, 1, 0, 1, 1,  7, 0, 0, 0, 0,  0, 0, 0, 0);
        check("mul",     MUL,   F_MUL, 5'd9,  1, 1, 0, 1, 0,  2, 0, 0, 0, 0,  0, 0, 0, 0);

        // ---------------- I-type arithmetic / logic ----------------
        check("addi",    ADDI,  6'd0,  5'd9,  1, 0, 1, 1, 0,  0, 0, 0, 0, 0,  0, 0, 0, 0);
        check("slti",    SLTI,  6'd0,  5'd9,  1, 0, 1, 1, 0,  9, 0, 0, 0, 0,  0, 0, 0, 0);
        check("andi",    ANDI,  6'd0,  5'd9,  1, 0, 1, 0, 0,  3, 0, 0, 0, 0,  0, 0, 0, 0);
        check("ori",     ORI,   6'd0,  5'd9,  1, 0, 1, 0, 0,  4, 0, 0, 0, 0,  0, 0, 0, 0);
        check("xori",    XORI,  6'd0,  5'd9,  1, 0, 1, 0, 0,  5, 0, 0, 0, 0,  0, 0, 0, 0);

        // ---------------- loads ----------------
        check("lw",      LW,    6'd0,  5'd9,  1, 0, 1, 1, 0,  0, 1, 0, 0, 1,  0, 0, 0, 0);
        check("lh",      LH,    6'd0,  5'd9,  1, 0, 1, 1, 0,  0, 1, 0, 1, 1,  0, 0, 0, 0);
        check("lb",      LB,    6'd0,  5'd9,  1, 0, 1, 1, 0,  0, 1, 0, 2, 1,  0, 0, 0, 0);

        // ---------------- stores ----------------
        check("sw",      SW,    6'd0,  5'd9,  0, 0, 1, 1, 0,  0, 0, 1, 0, 0,  0, 0, 0, 0);
        check("sh",      SH,    6'd0,  5'd9,  0, 0, 1, 1, 0,  0, 0, 1, 1, 0,  0, 0, 0, 0);
        check("sb",      SB,    6'd0,  5'd9,  0, 0, 1, 1, 0,  0, 0, 1, 2, 0,  0, 0, 0, 0);

        // ---------------- branches ----------------
        check("beq",     BEQ,   6'd0,  5'd9,  0, 0, 0, 1, 0,  1, 0, 0, 0, 0,  1, 1, 0, 0);
        check("bne",     BNE,   6'd0,  5'd9,  0, 0, 0, 1, 0,  1, 0, 0, 0, 0,  1, 0, 0, 0);
        check("bgtz",    BGTZ,  6'd0,  5'd0,  0, 0, 0, 1, 0, 11, 0, 0, 0, 0,  1, 0, 0, 0);
        check("blez",    BLEZ,  6'd0,  5'd0,  0, 0, 0, 1, 0, 12, 0, 0, 0, 0,  1, 0, 0, 0);
        check("bgez",    REGIMM,6'd0,  5'd1,  0, 0, 0, 1, 0, 10, 0, 0, 0, 0,  1, 0, 0, 0);
        check("bltz",    REGIMM,6'd0,  5'd0,  0, 0, 0, 1, 0, 13, 0, 0, 0, 0,  1, 0, 0, 0);

        // ---------------- jumps ----------------
        check("j",       J,     6'd0,  5'd9,  0, 0, 0, 1, 0,  0, 0, 0, 0, 0,  0, 0, 1, 0);
        check("jal",     JAL,   6'd0,  5'd9,  1, 2, 0, 1, 0,  0, 0, 0, 0, 2,  0, 0, 1, 0);

        // ---------------- invalid encodings: must not write or jump ----------------
        check("bad op",  6'b111111, 6'd0,      5'd0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
        check("bad fn",  RTYPE,     6'b111111, 5'd0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
        check("bad rt",  REGIMM,    6'd0,      5'd2, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);

        // ---------------- summary ----------------
        if (errors == 0)
            $display("ALL CONTROLLER TESTS PASSED");
        else
            $display("%0d CONTROLLER TEST(S) FAILED", errors);

        $finish;
    end

endmodule