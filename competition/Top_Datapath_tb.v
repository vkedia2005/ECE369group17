`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// ECE369A - Computer Organization
// Group 17
// Percent Effort: Vasu Kedia 33.3%, Noah Kramer 33.3%, Luke Mccullough 33.3%
//
// Module - Top_Datapath_tb.v
// Description - Lab 8 (competition) testbench for the 64x64 frame / 4x4 window
//   test case. Reports exactly what individual_group_results.xlsx asks for:
//
//     * Post-imp. simulation END TIME (ns): when the program enters its
//       infinite loop (exit: j exit)
//     * Simulation clock period = 2 * CLK_DELAY
//     * Simulation cycles = end time / simulation clock period
//     * Minimum SAD ($t7) and its coordinates ($v0 = row, $v1 = col)
//
//   It also prints every change of (row, col, SAD), which is the "flow of the
//   coordinates" the TAs check, and counts stall bubbles and branch/jump
//   flushes so each optimization's effect can be measured.
//
//   The infinite loop is found automatically: it is the first time the same
//   instruction (same nonzero PC) reaches WB twice within 3 cycles, which only
//   happens for a one-instruction loop like "exit: j exit". END TIME is the
//   moment that instruction FIRST reached WB, so no code changes are needed
//   when vbsme.s changes.
//
// Works for behavioral and post-implementation simulation (top-level ports only).
////////////////////////////////////////////////////////////////////////////////

module Top_Datapath_tb();

    // ---------------- settings ----------------
    parameter CLK_DELAY  = 5;            // ns. Simulation clock period = 2 * CLK_DELAY = 10 ns
    parameter MAX_CYCLES = 20000000;     // safety limit
    parameter EXP_CHECK  = 0;            // 1 = compare with EXP_ROW / EXP_COL / EXP_SAD below
    parameter EXP_ROW    = 0;            // fill in once the competition answer is known
    parameter EXP_COL    = 0;
    parameter EXP_SAD    = 0;

    reg         Clk;
    reg         Rst;
    wire [31:0] PC;
    wire [31:0] WriteData;
    wire [31:0] V0;
    wire [31:0] V1;
    wire [31:0] SAD;
    wire        Stall;
    wire        Flush;

    integer cycle   = 0;       // cycles since reset was released
    integer stalls  = 0;       // bubbles inserted by the hazard unit
    integer flushes = 0;       // instructions flushed by taken branches/jumps
    integer updates = 0;       // times a new minimum was found

    reg [31:0] lastV0, lastV1, lastSAD;
    reg [31:0] lastNonzeroPC;
    integer    lastNonzeroCycle;
    real       lastNonzeroTime;
    real       startTime;
    real       endTime;
    real       simPeriod;

    Top_Datapath u0(
        .Clk(Clk),
        .Rst(Rst),
        .PC(PC),
        .WriteData(WriteData),
        .V0(V0),
        .V1(V1),
        .SAD(SAD),
        .Stall(Stall),
        .Flush(Flush)
    );

    // ---------------- clock: Clk = ~Clk every CLK_DELAY ns ----------------
    initial begin
        Clk = 1'b0;
        forever #(CLK_DELAY) Clk = ~Clk;
    end

    // ---------------- reset ----------------
    initial begin
        simPeriod        = 2.0 * CLK_DELAY;
        lastV0           = 32'hFFFFFFFF;
        lastV1           = 32'hFFFFFFFF;
        lastSAD          = 32'hFFFFFFFF;
        lastNonzeroPC    = 32'hFFFFFFFF;
        lastNonzeroCycle = -10;
        lastNonzeroTime  = 0.0;
        startTime        = 0.0;

        Rst = 1'b1;
        repeat (3) @(posedge Clk);
        #1 Rst = 1'b0;
        $display("Running vbsme (64x64 frame, 4x4 window)...");
        $display("    time (ns) |    cycle | (row, col) | min SAD");
    end

    // ---------------- monitor (sampled mid-cycle) ----------------
    always @(negedge Clk) begin
        if (!Rst) begin
            cycle = cycle + 1;
            if (Stall === 1'b1) stalls  = stalls  + 1;
            if (Flush === 1'b1) flushes = flushes + 1;

            // flow of the current minimum: print every change
            if (V0 !== lastV0 || V1 !== lastV1 || SAD !== lastSAD) begin
                $display("%13.1f | %8d | (%0d, %0d) | %0d", $realtime, cycle, V0, V1, SAD);
                lastV0  = V0;
                lastV1  = V1;
                lastSAD = SAD;
                updates = updates + 1;
            end

            // infinite-loop detection (exit: j exit)
            if (PC != 32'd0) begin
                if (PC == lastNonzeroPC && (cycle - lastNonzeroCycle) <= 3) begin
                    endTime = lastNonzeroTime;     // first time the exit jump reached WB
                    report_and_finish(PC);
                end
                lastNonzeroPC    = PC;
                lastNonzeroCycle = cycle;
                lastNonzeroTime  = $realtime;
            end

            if (cycle >= MAX_CYCLES) begin
                $display("TIMEOUT after %0d cycles: program never reached its infinite loop (PC = %0d)",
                         cycle, PC);
                $finish;
            end
        end
    end

    // ---------------- final report ----------------
    task report_and_finish(input [31:0] exitPC);
        real cycles;
        begin
            cycles = endTime / simPeriod;
            $display("");
            $display("==================== COMPETITION RESULTS ====================");
            $display(" Infinite loop at PC         : %0d", exitPC);
            $display(" Final (row, col)            : (%0d, %0d)", V0, V1);
            $display(" Final minimum SAD           : %0d", SAD);
            $display(" Post-imp. sim END TIME (ns) : %0.1f", endTime);
            $display(" Simulation clock period (ns): %0.1f   (2 x CLK_DELAY)", simPeriod);
            $display(" Simulation cycles           : %0.1f   (end time / clock period)", cycles);
            $display(" Stall bubbles inserted      : %0d", stalls);
            $display(" Branch/jump flushes         : %0d", flushes);
            $display(" Minimum updates             : %0d", updates);
            if (EXP_CHECK) begin
                if (V0 == EXP_ROW && V1 == EXP_COL && SAD == EXP_SAD)
                    $display(" RESULT: PASS (matches expected row, col, SAD)");
                else
                    $display(" RESULT: FAIL (expected (%0d, %0d) with SAD %0d)",
                             EXP_ROW, EXP_COL, EXP_SAD);
            end
            $display("=============================================================");
            $finish;
        end
    endtask

endmodule
