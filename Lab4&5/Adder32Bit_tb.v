`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// ECE369 - Computer Architecture
//
// Module - Adder32Bit_tb.v
// Description - Tests Adder32Bit, including branch-target style additions.
////////////////////////////////////////////////////////////////////////////////

module Adder32Bit_tb();

    reg  [31:0] A, B;
    wire [31:0] Sum;

    integer errors = 0;

    Adder32Bit u0(.A(A), .B(B), .Sum(Sum));

    task check(input [31:0] a, input [31:0] b, input [31:0] expected,
               input [8*28-1:0] label);
        begin
            A = a;
            B = b;
            #10;
            if (Sum === expected)
                $display("PASS  %0s | %h + %h = %h", label, a, b, Sum);
            else begin
                $display("FAIL  %0s | %h + %h = %h (expected %h)", label, a, b, Sum, expected);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        A = 0; B = 0;
        #10;

        check(32'd0,   32'd4,        32'd4,   "PC+4 from 0");
        check(32'd236, 32'd4,        32'd240, "PC+4 from 236");
        // branch forward 3 instructions: offset 3 << 2 = 12
        check(32'd100, 32'd12,       32'd112, "branch forward");
        // branch back 5 instructions: offset -5 << 2 = -20 = FFFFFFEC
        check(32'd100, 32'hFFFFFFEC, 32'd80,  "branch backward");
        check(32'hFFFFFFFF, 32'd1,   32'd0,   "wraps around");

        if (errors == 0) $display("ALL ADDER32BIT TESTS PASSED");
        else             $display("%0d ADDER32BIT TEST(S) FAILED", errors);
        $finish;
    end

endmodule
