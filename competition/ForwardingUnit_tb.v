`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// ECE369A - Computer Organization (Lab 8 competition)
// Group 17
//
// Module - ForwardingUnit_tb.v
// Description - Checks every forwarding case: no hazard, EX/MEM, MEM/WB,
//               priority when both match, $zero, RegWrite = 0, and both
//               operands at once. Prints PASS/FAIL and a summary.
////////////////////////////////////////////////////////////////////////////////

module ForwardingUnit_tb();

    reg  [4:0] EX_Rs, EX_Rt, MEM_WriteReg, WB_WriteReg;
    reg        MEM_RegWrite, WB_RegWrite;
    wire [1:0] ForwardA, ForwardB;

    integer errors = 0;

    ForwardingUnit #(.ENABLE_FORWARDING(1)) u0(
        .EX_Rs(EX_Rs), .EX_Rt(EX_Rt),
        .MEM_RegWrite(MEM_RegWrite), .MEM_WriteReg(MEM_WriteReg),
        .WB_RegWrite(WB_RegWrite),   .WB_WriteReg(WB_WriteReg),
        .ForwardA(ForwardA), .ForwardB(ForwardB)
    );

    task check(input [4:0] rs, input [4:0] rt,
               input mrw, input [4:0] mreg, input wrw, input [4:0] wreg,
               input [1:0] expA, input [1:0] expB, input [8*40-1:0] label);
        begin
            EX_Rs = rs; EX_Rt = rt;
            MEM_RegWrite = mrw; MEM_WriteReg = mreg;
            WB_RegWrite  = wrw; WB_WriteReg  = wreg;
            #10;
            if (ForwardA === expA && ForwardB === expB)
                $display("PASS  %0s | A=%b B=%b", label, ForwardA, ForwardB);
            else begin
                $display("FAIL  %0s | A=%b B=%b (expected A=%b B=%b)",
                         label, ForwardA, ForwardB, expA, expB);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        //     rs  rt   MEM:rw reg  WB:rw reg   expA   expB
        check(8,  9,   0, 0,       0, 0,       2'b00, 2'b00, "no later writes");
        check(8,  9,   1, 10,      1, 11,      2'b00, 2'b00, "writes to other regs");
        check(8,  9,   1, 8,       0, 0,       2'b10, 2'b00, "rs from EX/MEM");
        check(8,  9,   1, 9,       0, 0,       2'b00, 2'b10, "rt from EX/MEM");
        check(8,  9,   0, 0,       1, 8,       2'b01, 2'b00, "rs from MEM/WB");
        check(8,  9,   0, 0,       1, 9,       2'b00, 2'b01, "rt from MEM/WB");
        check(8,  9,   1, 8,       1, 8,       2'b10, 2'b00, "both write rs: EX/MEM wins");
        check(8,  8,   1, 8,       0, 0,       2'b10, 2'b10, "rs == rt, both forwarded");
        check(8,  9,   1, 8,       1, 9,       2'b10, 2'b01, "rs from MEM, rt from WB");
        check(0,  0,   1, 0,       1, 0,       2'b00, 2'b00, "$zero never forwarded");
        check(8,  9,   0, 8,       0, 9,       2'b00, 2'b00, "RegWrite = 0: no forward");

        if (errors == 0) $display("ALL FORWARDING UNIT TESTS PASSED");
        else             $display("%0d FORWARDING UNIT TEST(S) FAILED", errors);
        $finish;
    end

endmodule
