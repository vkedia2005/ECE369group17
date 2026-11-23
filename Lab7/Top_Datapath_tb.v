`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// ECE369 - Computer Architecture
//
// Module - Top_Datapath_tb.v
// Description - Top-level testbench for the 5-stage pipelined datapath with
//   hazard detection (Lab 6).
//   - Generates the clock and a reset pulse.
//   - Prints PC and WriteData (signed decimal) whenever a new instruction
//     reaches WB.
//   - If CHECK = 1, checks every result of lab6_test.s (the program
//     stores everything it loads, so data_memory.mem contents don't matter):
//       * wrong WriteData at any PC                    -> FAIL line
//       * an instruction that should run never shows up -> MISSING line
//     Set CHECK = 0 when running any other program.
//
// Works for behavioral and post-implementation (post-routing) simulation,
// since it only uses the top-level ports.
////////////////////////////////////////////////////////////////////////////////

module Top_Datapath_tb();

    // ---------------- settings ----------------
    parameter CLK_PERIOD = 100;   // slow on purpose so post-routing timing is easy to meet
    parameter NUM_CYCLES = 230;   // two full passes of lab6_test.s (one pass ends at cycle ~110)
    parameter CHECK      = 1;     // 1 = check against lab6_test.s

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

    // ---------------- expected WriteData for lab6_test.s ----------------
    // Every PC not listed should write 0. The 'addi $t9, $zero, 99' lines
    // after taken branches/jumps and at FAIL are listed as 0 on purpose:
    // if one ever runs it shows 99 and FAILs.
    function [31:0] expected(input [31:0] pc);
        case (pc)
            32'd0:   expected = 32'h00000005; // addi $t0, $zero, 5
            32'd4:   expected = 32'hfffffff9; // addi $t1, $t0, -12
            32'd8:   expected = 32'hfffffffe; // add  $t2, $t0, $t1
            32'd12:  expected = 32'h00000007; // sub  $t3, $t0, $t2
            32'd16:  expected = 32'hffffffcf; // mul  $t4, $t3, $t1
            32'd20:  expected = 32'h00000007; // and  $t5, $t4, $t3
            32'd24:  expected = 32'hffffffff; // or   $t6, $t5, $t1
            32'd28:  expected = 32'h00000030; // xor  $t7, $t6, $t4
            32'd32:  expected = 32'h00000001; // nor  $s1, $t7, $t2
            32'd36:  expected = 32'h00000001; // slt  $s2, $t4, $t1
            32'd40:  expected = 32'h00000000; // slt  $s3, $t1, $t4
            32'd44:  expected = 32'h00000300; // sll  $s4, $t7, 4
            32'd48:  expected = 32'h0000000f; // srl  $s5, $t1, 28
            32'd52:  expected = 32'h00000001; // slti $s6, $t1, -6
            32'd56:  expected = 32'h0000ff09; // andi $s7, $t1, 65295
            32'd60:  expected = 32'h00008007; // ori  $t8, $t3, 32768
            32'd64:  expected = 32'h000080f8; // xori $t9, $t8, 255
            32'd68:  expected = 32'h00000040; // addi $s0, $zero, 64
            32'd72:  expected = 32'h00000000; // sw   $t4, 0($s0)
            32'd76:  expected = 32'h00000000; // sw   $t9, 4($s0)
            32'd80:  expected = 32'hffffffcf; // lw   $a0, 0($s0)
            32'd84:  expected = 32'hffffff9e; // add  $a1, $a0, $a0
            32'd88:  expected = 32'h00000000; // sh   $a1, 8($s0)
            32'd92:  expected = 32'h00000000; // sb   $s1, 10($s0)
            32'd96:  expected = 32'hffffff9e; // lh   $a2, 8($s0)
            32'd100: expected = 32'h00000001; // lb   $a3, 10($s0)
            32'd104: expected = 32'hfffffff8; // lb   $v0, 4($s0)
            32'd108: expected = 32'hffff80f8; // lh   $v1, 4($s0)
            32'd112: expected = 32'h0001ff9e; // lw   $t0, 8($s0)
            32'd116: expected = 32'hfffffffd; // addi $t1, $zero, -3
            32'd120: expected = 32'h00000000; // bltz $t1, L1
            32'd128: expected = 32'h00000000; // bgez $t1, FAIL
            32'd132: expected = 32'h00000000; // bgtz $t1, FAIL
            32'd136: expected = 32'h00000000; // blez $t1, L2
            32'd144: expected = 32'h00000004; // addi $t2, $zero, 4
            32'd148: expected = 32'h00000000; // bgtz $t2, L3
            32'd156: expected = 32'h00000000; // blez $t2, FAIL
            32'd160: expected = 32'h00000000; // bltz $t2, FAIL
            32'd164: expected = 32'h00000000; // bgez $t2, L4
            32'd172: expected = 32'h00000000; // bgez $zero, L5
            32'd180: expected = 32'hffffffcf; // lw   $t3, 0($s0)
            32'd184: expected = 32'h00000000; // beq  $t3, $t4, L6
            32'd192: expected = 32'h00000000; // bne  $t3, $t4, FAIL
            32'd196: expected = 32'h00000000; // beq  $t3, $zero, FAIL
            32'd200: expected = 32'h00000000; // bne  $t3, $zero, L7
            32'd208: expected = 32'h00000000; // j    FWD
            32'd216: expected = 32'h00000065; // addi $s6, $s6, 100
            32'd220: expected = 32'h00000000; // j    AFTER
            32'd228: expected = 32'h00000010; // addi $s5, $s5, 1
            32'd232: expected = 32'h00000000; // bne  $s5, $zero, BACK
            32'd240: expected = 32'h000000f4; // jal  FUNC
            32'd244: expected = 32'h00000017; // addi $s7, $v0, 3
            32'd248: expected = 32'h00000000; // j    END
            32'd256: expected = 32'h00000014; // addi $v0, $zero, 20
            32'd260: expected = 32'h00000000; // jr   $ra
            32'd268: expected = 32'h00000118; // addi $ra, $zero, 280
            32'd272: expected = 32'h00000000; // jr   $ra
            32'd280: expected = 32'h00000000; // j    main
            default: expected = 32'd0;
        endcase
    endfunction

    // PCs of the instructions that must reach WB (every instruction that runs)
    localparam NUM_MUST = 58;
    reg [31:0] mustSee [0:NUM_MUST-1];
    initial begin
        mustSee[0] = 0; mustSee[1] = 4; mustSee[2] = 8; mustSee[3] = 12;
        mustSee[4] = 16; mustSee[5] = 20; mustSee[6] = 24; mustSee[7] = 28;
        mustSee[8] = 32; mustSee[9] = 36; mustSee[10] = 40; mustSee[11] = 44;
        mustSee[12] = 48; mustSee[13] = 52; mustSee[14] = 56; mustSee[15] = 60;
        mustSee[16] = 64; mustSee[17] = 68; mustSee[18] = 72; mustSee[19] = 76;
        mustSee[20] = 80; mustSee[21] = 84; mustSee[22] = 88; mustSee[23] = 92;
        mustSee[24] = 96; mustSee[25] = 100; mustSee[26] = 104; mustSee[27] = 108;
        mustSee[28] = 112; mustSee[29] = 116; mustSee[30] = 120; mustSee[31] = 128;
        mustSee[32] = 132; mustSee[33] = 136; mustSee[34] = 144; mustSee[35] = 148;
        mustSee[36] = 156; mustSee[37] = 160; mustSee[38] = 164; mustSee[39] = 172;
        mustSee[40] = 180; mustSee[41] = 184; mustSee[42] = 192; mustSee[43] = 196;
        mustSee[44] = 200; mustSee[45] = 208; mustSee[46] = 216; mustSee[47] = 220;
        mustSee[48] = 228; mustSee[49] = 232; mustSee[50] = 240; mustSee[51] = 244;
        mustSee[52] = 248; mustSee[53] = 256; mustSee[54] = 260; mustSee[55] = 268;
        mustSee[56] = 272; mustSee[57] = 280;
    end

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
            for (i = 0; i < NUM_MUST; i = i + 1)
                if (!seen[mustSee[i][11:2]]) begin
                    $display("MISSING  PC %0d never reached WB", mustSee[i]);
                    errors = errors + 1;
                end
            if (errors == 0) $display("ALL LAB 6 TEST CHECKS PASSED");
            else             $display("%0d LAB 6 TEST CHECK(S) FAILED", errors);
        end
        $finish;
    end

    // ---------------- monitor ----------------
    // Sample mid-cycle (falling edge) so outputs have settled after the
    // rising edge. Print when a new instruction reaches WB (PC or value
    // changes). PC = 0 with WriteData = 0 is skipped: that is the empty
    // pipeline after reset, a stall bubble, or a flushed instruction.
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