`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// ECE369 - Computer Architecture
//
// Module - ALU32Bit_tb.v
// Description - Tests every operation of ALU32Bit.v, including signed cases
//               and the Zero flag. Prints PASS/FAIL per check and a summary.
////////////////////////////////////////////////////////////////////////////////

module ALU32Bit_tb();

    reg  [4:0]  ALUControl;     // 5 bits, matches ALU32Bit.v
    reg  [31:0] A, B;

    wire [31:0] ALUResult;
    wire [63:0] ALUResult64;
    wire        Zero;

    // operation encodings (must match ALU32Bit.v)
    localparam OP_ADD  = 5'd0;
    localparam OP_SUB  = 5'd1;
    localparam OP_MUL  = 5'd2;
    localparam OP_AND  = 5'd3;
    localparam OP_OR   = 5'd4;
    localparam OP_XOR  = 5'd5;
    localparam OP_NOR  = 5'd6;
    localparam OP_SLL  = 5'd7;
    localparam OP_SRL  = 5'd8;
    localparam OP_SLT  = 5'd9;
    localparam OP_BGEZ = 5'd10;
    localparam OP_BGTZ = 5'd11;
    localparam OP_BLEZ = 5'd12;
    localparam OP_BLTZ = 5'd13;

    integer errors = 0;

    ALU32Bit u0(
        .ALUControl(ALUControl),
        .A(A),
        .B(B),
        .ALUResult(ALUResult),
        .ALUResult64(ALUResult64),
        .Zero(Zero)
    );

    // Apply inputs, wait, then check ALUResult and the Zero flag.
    task check(input [4:0] ctrl, input [31:0] a, input [31:0] b,
               input [31:0] expected, input [8*28-1:0] label);
        begin
            ALUControl = ctrl;
            A = a;
            B = b;
            #10;
            if (ALUResult === expected && Zero === (expected == 32'd0))
                $display("PASS  %0s | A=%h B=%h -> %h Zero=%b",
                         label, a, b, ALUResult, Zero);
            else begin
                $display("FAIL  %0s | A=%h B=%h -> %h Zero=%b (expected %h Zero=%b)",
                         label, a, b, ALUResult, Zero, expected, (expected == 32'd0));
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        ALUControl = 5'd0;
        A = 32'd0;
        B = 32'd0;
        #10;

        // ---------------- ADD ----------------
        check(OP_ADD, 32'd5,        32'd3,        32'd8,        "add 5+3");
        check(OP_ADD, 32'hFFFFFFFF, 32'd1,        32'd0,        "add -1+1 (Zero)");
        check(OP_ADD, 32'hFFFFFFFE, 32'hFFFFFFFD, 32'hFFFFFFFB, "add -2+-3");
        check(OP_ADD, 32'h7FFFFFFF, 32'd1,        32'h80000000, "add overflow wraps");

        // ---------------- SUB ----------------
        check(OP_SUB, 32'd10,       32'd3,        32'd7,        "sub 10-3");
        check(OP_SUB, 32'd3,        32'd10,       32'hFFFFFFF9, "sub 3-10 = -7");
        check(OP_SUB, 32'd5,        32'd5,        32'd0,        "sub 5-5 (Zero, beq)");

        // ---------------- MUL ----------------
        check(OP_MUL, 32'd6,        32'd7,        32'd42,       "mul 6*7");
        check(OP_MUL, 32'hFFFFFFFD, 32'd4,        32'hFFFFFFF4, "mul -3*4 = -12");
        check(OP_MUL, 32'd0,        32'd1234,     32'd0,        "mul by 0 (Zero)");
        // low 32 bits of 0x10000 * 0x10000 are 0; full product is 0x1_00000000
        check(OP_MUL, 32'h00010000, 32'h00010000, 32'd0,        "mul low word");
        if (ALUResult64 === 64'h0000_0001_0000_0000)
            $display("PASS  mul 64-bit product | %h", ALUResult64);
        else begin
            $display("FAIL  mul 64-bit product | %h (expected 0000000100000000)", ALUResult64);
            errors = errors + 1;
        end

        // ---------------- AND / OR / XOR / NOR ----------------
        check(OP_AND, 32'hF0F0F0F0, 32'hFF00FF00, 32'hF000F000, "and");
        check(OP_AND, 32'hF0F0F0F0, 32'h0F0F0F0F, 32'd0,        "and (Zero)");
        check(OP_OR,  32'hF0F0F0F0, 32'h0F0F0F0F, 32'hFFFFFFFF, "or");
        check(OP_XOR, 32'hFF00FF00, 32'hF0F0F0F0, 32'h0FF00FF0, "xor");
        check(OP_XOR, 32'h12345678, 32'h12345678, 32'd0,        "xor same (Zero)");
        check(OP_NOR, 32'd0,        32'd0,        32'hFFFFFFFF, "nor 0,0");
        check(OP_NOR, 32'hF0F0F0F0, 32'h0F0F0F0F, 32'd0,        "nor (Zero)");

        // ---------------- SLL / SRL (shift amount = B[4:0]) ----------------
        check(OP_SLL, 32'd1,        32'd4,        32'd16,       "sll 1<<4");
        check(OP_SLL, 32'd4,        32'd3,        32'd32,       "sll 4<<3");
        check(OP_SLL, 32'd1,        32'd31,       32'h80000000, "sll 1<<31");
        check(OP_SLL, 32'd1,        32'd33,       32'd2,        "sll uses B[4:0] only");
        check(OP_SRL, 32'd64,       32'd2,        32'd16,       "srl 64>>2");
        check(OP_SRL, 32'h80000000, 32'd31,       32'd1,        "srl logical (no sign)");
        check(OP_SRL, 32'hFFFFFFFF, 32'd4,        32'h0FFFFFFF, "srl fills with 0s");

        // ---------------- SLT (signed) ----------------
        check(OP_SLT, 32'd3,        32'd5,        32'd1,        "slt 3<5");
        check(OP_SLT, 32'd5,        32'd3,        32'd0,        "slt 5<3");
        check(OP_SLT, 32'd4,        32'd4,        32'd0,        "slt 4<4");
        check(OP_SLT, 32'hFFFFFFFF, 32'd1,        32'd1,        "slt -1<1 (signed)");
        check(OP_SLT, 32'd1,        32'hFFFFFFFF, 32'd0,        "slt 1<-1 (signed)");

        // ---------------- branch compares (result 1 = take branch) ----------------
        check(OP_BGEZ, 32'd0,        32'd0, 32'd1, "bgez 0");
        check(OP_BGEZ, 32'd5,        32'd0, 32'd1, "bgez 5");
        check(OP_BGEZ, 32'hFFFFFFFF, 32'd0, 32'd0, "bgez -1");

        check(OP_BGTZ, 32'd0,        32'd0, 32'd0, "bgtz 0");
        check(OP_BGTZ, 32'd5,        32'd0, 32'd1, "bgtz 5");
        check(OP_BGTZ, 32'hFFFFFFFF, 32'd0, 32'd0, "bgtz -1");

        check(OP_BLEZ, 32'd0,        32'd0, 32'd1, "blez 0");
        check(OP_BLEZ, 32'hFFFFFFFF, 32'd0, 32'd1, "blez -1");
        check(OP_BLEZ, 32'd5,        32'd0, 32'd0, "blez 5");

        check(OP_BLTZ, 32'hFFFFFFFF, 32'd0, 32'd1, "bltz -1");
        check(OP_BLTZ, 32'h80000000, 32'd0, 32'd1, "bltz most negative");
        check(OP_BLTZ, 32'd0,        32'd0, 32'd0, "bltz 0");
        check(OP_BLTZ, 32'd5,        32'd0, 32'd0, "bltz 5");

        // ---------------- unused code -> 0 ----------------
        check(5'd31, 32'd123, 32'd456, 32'd0, "undefined op -> 0");

        // ---------------- summary ----------------
        if (errors == 0)
            $display("ALL ALU TESTS PASSED");
        else
            $display("%0d ALU TEST(S) FAILED", errors);

        $finish;
    end

endmodule