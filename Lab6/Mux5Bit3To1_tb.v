`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// ECE369 - Computer Architecture
//
// Module - Mux5Bit3To1_tb.v
// Description - Tests all four select values of Mux5Bit3To1.
////////////////////////////////////////////////////////////////////////////////

module Mux5Bit3To1_tb();

    reg  [4:0] inA, inB, inC;
    reg  [1:0] sel;
    wire [4:0] out;

    integer errors = 0;

    Mux5Bit3To1 u0(.out(out), .inA(inA), .inB(inB), .inC(inC), .sel(sel));

    task check(input [1:0] s, input [4:0] expected);
        begin
            sel = s;
            #10;
            if (out === expected)
                $display("PASS  sel=%b -> %0d", sel, out);
            else begin
                $display("FAIL  sel=%b -> %0d (expected %0d)", sel, out, expected);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        inA = 5'd9;      // rt  ($t1)
        inB = 5'd11;     // rd  ($t3)
        inC = 5'd31;     // $ra
        sel = 2'b00;
        #10;

        check(2'b00, 5'd9);    // I-type: write rt
        check(2'b01, 5'd11);   // R-type: write rd
        check(2'b10, 5'd31);   // jal:    write $31
        check(2'b11, 5'd9);    // unused: falls back to rt

        if (errors == 0) $display("ALL MUX5BIT3TO1 TESTS PASSED");
        else             $display("%0d MUX5BIT3TO1 TEST(S) FAILED", errors);
        $finish;
    end

endmodule
