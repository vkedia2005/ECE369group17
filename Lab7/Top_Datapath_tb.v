`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// ECE369A - Computer Organization
// Group 17
// Percent Effort: Vasu Kedia 33.3%, Noah Kramer 33.3%, Luke Mccullough 33.3%
//
// Module - Top_Datapath_tb.v
// Description - Lab 7 testbench: runs vbsme.s (5 test cases) on the pipelined
//   datapath with hazard detection.
//   - Prints ($v0, $v1) every time it changes (a new minimum SAD was found).
//   - When vbsme returns ('doneAll: jr $s7' reaches WB), records the answer.
//   - Stops when the program reaches 'end_program: j end_program'.
//   - If CHECK = 1, compares the 5 answers with the expected results.
//
// Works for behavioral and post-implementation simulation (top-level ports only).
// The full run is about 3.8 million clock cycles: use "run all".
////////////////////////////////////////////////////////////////////////////////

module Top_Datapath_tb();

    // ---------------- settings ----------------
    parameter CLK_PERIOD  = 100;          // ns
    parameter MAX_CYCLES  = 6000000;      // safety limit (normal run ~3.83 M)
    parameter CHECK       = 1;            // 1 = check against the 5 template test cases
    parameter DONEALL_PC  = 32'd316;      // address of 'doneAll: jr $s7'  (line 80 of instruction_memory.mem)
    parameter END_PC      = 32'd100;      // address of 'end_program: j end_program' (line 26)
    parameter NUM_TESTS   = 5;

    reg         Clk;
    reg         Rst;
    wire [31:0] PC;
    wire [31:0] WriteData;
    wire [31:0] V0;
    wire [31:0] V1;

    integer cycle  = 0;
    integer test   = 0;
    integer errors = 0;
    reg [31:0] lastPC;
    reg [31:0] lastV0, lastV1;

    reg [31:0] expRow [0:NUM_TESTS-1];
    reg [31:0] expCol [0:NUM_TESTS-1];

    Top_Datapath u0(
        .Clk(Clk),
        .Rst(Rst),
        .PC(PC),
        .WriteData(WriteData),
        .V0(V0),
        .V1(V1)
    );

    // ---------------- clock ----------------
    initial begin
        Clk = 1'b0;
        forever #(CLK_PERIOD/2) Clk = ~Clk;
    end

    // ---------------- reset and expected values ----------------
    initial begin
        expRow[0] = 3;  expCol[0] = 2;    // test 1: 16x16 frame, 8x4 window
        expRow[1] = 16; expCol[1] = 0;    // test 2: 32x32 frame, 8x16 window
        expRow[2] = 12; expCol[2] = 0;    // test 3: 16x16 frame, 4x8 window
        expRow[3] = 8;  expCol[3] = 3;    // test 4: 16x16 frame, 8x8 window
        expRow[4] = 5;  expCol[4] = 16;   // test 5: 32x32 frame, 4x4 window

        Rst    = 1'b1;
        lastPC = 32'hFFFFFFFF;
        lastV0 = 32'hFFFFFFFF;
        lastV1 = 32'hFFFFFFFF;
        repeat (3) @(posedge Clk);
        #1 Rst = 1'b0;
        $display("Running vbsme (about 3.8 million cycles)...");
    end

    // ---------------- monitor (sample mid-cycle) ----------------
    always @(negedge Clk) begin
        if (!Rst) begin
            cycle = cycle + 1;

            // new minimum found -> display would change
            if (V0 !== lastV0 || V1 !== lastV1) begin
                $display("cycle %8d | display (row, col) = (%0d, %0d)", cycle, V0, V1);
                lastV0 = V0;
                lastV1 = V1;
            end

            // vbsme returned: record this test's answer
            if (PC == DONEALL_PC && lastPC != DONEALL_PC) begin
                if (CHECK && test < NUM_TESTS) begin
                    if (V0 === expRow[test] && V1 === expCol[test])
                        $display(">>> TEST %0d PASS: (%0d, %0d)", test+1, V0, V1);
                    else begin
                        $display(">>> TEST %0d FAIL: got (%0d, %0d), expected (%0d, %0d)",
                                 test+1, V0, V1, expRow[test], expCol[test]);
                        errors = errors + 1;
                    end
                end else
                    $display(">>> vbsme call %0d returned (%0d, %0d)", test+1, V0, V1);
                test = test + 1;
            end

            // program finished
            if (PC == END_PC && lastPC != END_PC) begin
                $display("Reached end_program at cycle %0d", cycle);
                if (CHECK) begin
                    if (test != NUM_TESTS) begin
                        $display("Only %0d of %0d tests completed", test, NUM_TESTS);
                        errors = errors + 1;
                    end
                    if (errors == 0) $display("ALL %0d VBSME TESTS PASSED", NUM_TESTS);
                    else             $display("%0d VBSME CHECK(S) FAILED", errors);
                end
                $finish;
            end

            if (cycle >= MAX_CYCLES) begin
                $display("TIMEOUT after %0d cycles (PC = %0d, %0d tests done)", cycle, PC, test);
                $finish;
            end

            lastPC = PC;
        end
    end

endmodule
