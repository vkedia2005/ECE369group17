`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// ECE369 - Computer Architecture
//
// Module - Top_Datapath_tb.v
// Description - Top-level testbench for the 5-stage pipelined datapath.
//   - Generates the clock and a reset pulse.
//   - Prints PC and WriteData (signed decimal) whenever a new instruction
//     reaches WB.
//   - If CHECK = 1, checks every result of lab4_full_test.s:
//       * wrong WriteData at any PC           -> FAIL line
//       * an instruction that should run never shows up -> MISSING line
//     Set CHECK = 0 when running any other program.
//
// Works for behavioral and post-implementation (post-routing) simulation,
// since it only uses the top-level ports.
////////////////////////////////////////////////////////////////////////////////

module Top_Datapath_tb();

    // ---------------- settings ----------------
    parameter CLK_PERIOD = 100;   // nlow on purpose so post-routing timing is easy to meet.
    parameter NUM_CYCLES = 420;   // one full pass of lab4_full_test.s plus margin
    parameter CHECK      = 1;     // 1 = check against lab4_full_test.s

    reg         Clk;
    reg         Rst;
    wire [31:0] PC;
    wire [31:0] WriteData;

    integer cycle  = 0;
    integer errors = 0;
    integer i;
    reg [31:0] lastPC;
    reg [31:0] lastWD;
    reg        seen [0:1023];     // which instruction addresses reached WB

    Top_Datapath u0(
        .Clk(Clk),
        .Rst(Rst),
        .PC(PC),
        .WriteData(WriteData)
    );

    // ---------------- clock ----------------
    initial begin
        Clk = 1'b0;
        forever #(CLK_PERIOD/2) Clk = ~Clk;
    end

    // ---------------- expected WriteData for lab4_full_test.s ----------------
    // Any PC not listed (nops, stores, branches, j, jr) should write 0.
    // The 'addi $t9, $zero, 99' lines skipped by taken branches are listed as 0:
    // if one runs, it shows 99 and fails.
    function [31:0] expected(input [31:0] pc);
        case (pc)
            32'd0: expected = 32'h0000000a;
            32'd24: expected = 32'hfffffffd;
            32'd48: expected = 32'h00000007;
            32'd72: expected = 32'h0000000d;
            32'd96: expected = 32'hffffffe2;
            32'd120: expected = 32'h0000000c;
            32'd144: expected = 32'h0000000a;
            32'd168: expected = 32'h00000008;
            32'd192: expected = 32'h0000000e;
            32'd216: expected = 32'h00000006;
            32'd240: expected = 32'hfffffff1;
            32'd264: expected = 32'h00000004;
            32'd288: expected = 32'h0000000f;
            32'd312: expected = 32'h00000009;
            32'd336: expected = 32'h00009c40;
            32'd360: expected = 32'h00000030;
            32'd384: expected = 32'h00000003;
            32'd408: expected = 32'h00000001;
            32'd456: expected = 32'h00000001;
            32'd528: expected = 32'hfffffffd;
            32'd552: expected = 32'h000000c8;
            32'd600: expected = 32'hffffffc8;
            32'd624: expected = 32'h00000011;
            32'd672: expected = 32'h000011c8;
            32'd696: expected = 32'hfffff830;
            32'd744: expected = 32'hfffff830;
            32'd792: expected = 32'h000af830;
            32'd840: expected = 32'h00000000;
            32'd888: expected = 32'h00000001;
            32'd936: expected = 32'h00000000;
            32'd984: expected = 32'h00000002;
            32'd1032: expected = 32'h00000000;
            32'd1080: expected = 32'h00000000;
            32'd1128: expected = 32'h00000003;
            32'd1176: expected = 32'h00000000;
            32'd1224: expected = 32'h00000004;
            32'd1272: expected = 32'h00000000;
            32'd1320: expected = 32'h00000000;
            32'd1368: expected = 32'h00000005;
            32'd1416: expected = 32'h00000000;
            32'd1464: expected = 32'h00000006;
            32'd1488: expected = 32'h000005d4;
            32'd1512: expected = 32'h0000004d;
            32'd1560: expected = 32'h00000037;
            default: expected = 32'd0;
        endcase
    endfunction

    // ---------------- reset, run, summary ----------------
    initial begin
        for (i = 0; i < 1024; i = i + 1) seen[i] = 1'b0;
        Rst    = 1'b1;
        lastPC = 32'hFFFFFFFF;          // so the first line always prints
        lastWD = 32'hFFFFFFFF;

        repeat (3) @(posedge Clk);      // hold reset for 3 cycles
        #1 Rst = 1'b0;

        $display("cycle |   PC | WriteData");
        $display("------+------+-----------");

        repeat (NUM_CYCLES) @(posedge Clk);

        $display("------+------+-----------");
        if (CHECK) begin
        if (!seen[0]) begin $display("MISSING  PC %0d never reached WB", 0); errors = errors + 1; end
        if (!seen[6]) begin $display("MISSING  PC %0d never reached WB", 24); errors = errors + 1; end
        if (!seen[12]) begin $display("MISSING  PC %0d never reached WB", 48); errors = errors + 1; end
        if (!seen[18]) begin $display("MISSING  PC %0d never reached WB", 72); errors = errors + 1; end
        if (!seen[24]) begin $display("MISSING  PC %0d never reached WB", 96); errors = errors + 1; end
        if (!seen[30]) begin $display("MISSING  PC %0d never reached WB", 120); errors = errors + 1; end
        if (!seen[36]) begin $display("MISSING  PC %0d never reached WB", 144); errors = errors + 1; end
        if (!seen[42]) begin $display("MISSING  PC %0d never reached WB", 168); errors = errors + 1; end
        if (!seen[48]) begin $display("MISSING  PC %0d never reached WB", 192); errors = errors + 1; end
        if (!seen[54]) begin $display("MISSING  PC %0d never reached WB", 216); errors = errors + 1; end
        if (!seen[60]) begin $display("MISSING  PC %0d never reached WB", 240); errors = errors + 1; end
        if (!seen[66]) begin $display("MISSING  PC %0d never reached WB", 264); errors = errors + 1; end
        if (!seen[72]) begin $display("MISSING  PC %0d never reached WB", 288); errors = errors + 1; end
        if (!seen[78]) begin $display("MISSING  PC %0d never reached WB", 312); errors = errors + 1; end
        if (!seen[84]) begin $display("MISSING  PC %0d never reached WB", 336); errors = errors + 1; end
        if (!seen[90]) begin $display("MISSING  PC %0d never reached WB", 360); errors = errors + 1; end
        if (!seen[96]) begin $display("MISSING  PC %0d never reached WB", 384); errors = errors + 1; end
        if (!seen[102]) begin $display("MISSING  PC %0d never reached WB", 408); errors = errors + 1; end
        if (!seen[114]) begin $display("MISSING  PC %0d never reached WB", 456); errors = errors + 1; end
        if (!seen[132]) begin $display("MISSING  PC %0d never reached WB", 528); errors = errors + 1; end
        if (!seen[138]) begin $display("MISSING  PC %0d never reached WB", 552); errors = errors + 1; end
        if (!seen[150]) begin $display("MISSING  PC %0d never reached WB", 600); errors = errors + 1; end
        if (!seen[156]) begin $display("MISSING  PC %0d never reached WB", 624); errors = errors + 1; end
        if (!seen[168]) begin $display("MISSING  PC %0d never reached WB", 672); errors = errors + 1; end
        if (!seen[174]) begin $display("MISSING  PC %0d never reached WB", 696); errors = errors + 1; end
        if (!seen[186]) begin $display("MISSING  PC %0d never reached WB", 744); errors = errors + 1; end
        if (!seen[198]) begin $display("MISSING  PC %0d never reached WB", 792); errors = errors + 1; end
        if (!seen[222]) begin $display("MISSING  PC %0d never reached WB", 888); errors = errors + 1; end
        if (!seen[246]) begin $display("MISSING  PC %0d never reached WB", 984); errors = errors + 1; end
        if (!seen[282]) begin $display("MISSING  PC %0d never reached WB", 1128); errors = errors + 1; end
        if (!seen[306]) begin $display("MISSING  PC %0d never reached WB", 1224); errors = errors + 1; end
        if (!seen[342]) begin $display("MISSING  PC %0d never reached WB", 1368); errors = errors + 1; end
        if (!seen[366]) begin $display("MISSING  PC %0d never reached WB", 1464); errors = errors + 1; end
        if (!seen[372]) begin $display("MISSING  PC %0d never reached WB", 1488); errors = errors + 1; end
        if (!seen[378]) begin $display("MISSING  PC %0d never reached WB", 1512); errors = errors + 1; end
        if (!seen[390]) begin $display("MISSING  PC %0d never reached WB", 1560); errors = errors + 1; end
            if (errors == 0) $display("ALL FULL TEST CHECKS PASSED");
            else             $display("%0d FULL TEST CHECK(S) FAILED", errors);
        end
        $finish;
    end

    // ---------------- monitor ----------------
    // Sample mid-cycle (falling edge) so outputs have settled after the
    // rising edge. Print when a new instruction reaches WB (PC or value
    // changes). PC = 0 with WriteData = 0 is the empty pipeline after reset,
    // so it is skipped; the first instruction (PC 0) writes 10.
    always @(negedge Clk) begin
        if (!Rst) begin
            cycle = cycle + 1;
            if ((PC !== lastPC || WriteData !== lastWD) &&
                !(PC == 32'd0 && WriteData == 32'd0)) begin
                seen[PC[11:2]] = 1'b1;
                if (CHECK && WriteData !== expected(PC)) begin
                    $display("%5d | %4d | %0d   <-- FAIL, expected %0d",
                             cycle, PC, $signed(WriteData), $signed(expected(PC)));
                    errors = errors + 1;
                end else begin
                    $display("%5d | %4d | %0d", cycle, PC, $signed(WriteData));
                end
            end
            lastPC = PC;
            lastWD = WriteData;
        end
    end

endmodule