`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// ECE369 - Computer Architecture
//
// Module - DataMemory_tb.v
// Description - Tests word, halfword and byte loads/stores in DataMemory.v
//               Prints PASS/FAIL for every check and a summary at the end.
//
// Clock period = 20 ns (rising edges at 10, 30, 50, ...).
// Inputs only change at times ending in 5 (25, 35, 45, ...), never on a clock
// edge, so each 20 ns store window contains exactly one rising edge.
////////////////////////////////////////////////////////////////////////////////

module DataMemory_tb();

    reg  [31:0] Address;
    reg  [31:0] WriteData;
    reg         Clk;
    reg         MemWrite;
    reg         MemRead;
    reg  [1:0]  MemSize;

    wire [31:0] ReadData;

    // size encodings (must match DataMemory.v)
    localparam WORD = 2'b00;
    localparam HALF = 2'b01;
    localparam BYTE = 2'b10;

    integer errors = 0;

    DataMemory u0(
        .Address(Address),
        .WriteData(WriteData),
        .Clk(Clk),
        .MemWrite(MemWrite),
        .MemRead(MemRead),
        .MemSize(MemSize),
        .ReadData(ReadData)
    );

    initial begin
        Clk <= 1'b0;
        forever #10 Clk <= ~Clk;
    end

    // ---- helper tasks ----

    // store: one clock period with MemWrite high
    task store(input [1:0] size, input [31:0] addr, input [31:0] data);
        begin
            MemRead   = 1'b0;
            MemWrite  = 1'b1;
            MemSize   = size;
            Address   = addr;
            WriteData = data;
            #20;
            MemWrite  = 1'b0;
        end
    endtask

    // load and compare against expected value (read is combinational)
    task load_check(input [1:0] size, input [31:0] addr, input [31:0] expected,
                    input [8*40-1:0] label);
        begin
            MemWrite = 1'b0;
            MemRead  = 1'b1;
            MemSize  = size;
            Address  = addr;
            #10;
            if (ReadData === expected)
                $display("PASS  %0s | addr %0d -> %h", label, addr, ReadData);
            else begin
                $display("FAIL  %0s | addr %0d -> %h (expected %h)",
                         label, addr, ReadData, expected);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        // Initialize inputs
        Address   = 32'd0;
        WriteData = 32'd0;
        MemWrite  = 1'b0;
        MemRead   = 1'b0;
        MemSize   = WORD;

        #25; // Wait past the first clock edge

        // ---------------- TEST 1: word stores / loads ----------------
        store(WORD, 32'd0, 32'hAAAA_1111);
        store(WORD, 32'd4, 32'hBBBB_2222);
        store(WORD, 32'd8, 32'hCCCC_3333);

        load_check(WORD, 32'd0, 32'hAAAA_1111, "lw word 0");
        load_check(WORD, 32'd4, 32'hBBBB_2222, "lw word 1");
        load_check(WORD, 32'd8, 32'hCCCC_3333, "lw word 2");

        // ---------------- TEST 2: sb into all 4 byte positions ----------------
        store(WORD, 32'd16, 32'h0000_0000);
        store(BYTE, 32'd16, 32'h0000_0001);   // byte 0 -> [7:0]
        store(BYTE, 32'd17, 32'h0000_0002);   // byte 1 -> [15:8]
        store(BYTE, 32'd18, 32'h0000_0003);   // byte 2 -> [23:16]
        store(BYTE, 32'd19, 32'h0000_0004);   // byte 3 -> [31:24]
        load_check(WORD, 32'd16, 32'h0403_0201, "sb each byte, lw");

        // ---------------- TEST 3: sb leaves neighbors alone ----------------
        store(WORD, 32'd12, 32'h1122_3344);
        store(BYTE, 32'd13, 32'hDEAD_BEAA);   // only low byte (AA) is stored
        load_check(WORD, 32'd12, 32'h1122_AA44, "sb keeps other bytes");

        // ---------------- TEST 4: sh into both halves ----------------
        store(WORD, 32'd20, 32'hFFFF_FFFF);
        store(HALF, 32'd20, 32'h0000_1234);   // lower half
        load_check(WORD, 32'd20, 32'hFFFF_1234, "sh lower half");
        store(HALF, 32'd22, 32'hFFFF_ABCD);   // upper half, only low 16 bits stored
        load_check(WORD, 32'd20, 32'hABCD_1234, "sh upper half");

        // ---------------- TEST 5: lb (sign extension) ----------------
        load_check(BYTE, 32'd17, 32'h0000_0002, "lb positive byte");
        load_check(BYTE, 32'd19, 32'h0000_0004, "lb byte 3");
        load_check(BYTE, 32'd13, 32'hFFFF_FFAA, "lb negative byte");
        load_check(BYTE, 32'd12, 32'h0000_0044, "lb byte 0");

        // ---------------- TEST 6: lh (sign extension) ----------------
        load_check(HALF, 32'd20, 32'h0000_1234, "lh positive half");
        load_check(HALF, 32'd22, 32'hFFFF_ABCD, "lh negative half");

        // ---------------- TEST 7: MemRead = 0 ----------------
        MemRead = 1'b0;
        Address = 32'd8;
        #10;
        if (ReadData === 32'd0)
            $display("PASS  MemRead=0 outputs 0");
        else begin
            $display("FAIL  MemRead=0 -> %h (expected 00000000)", ReadData);
            errors = errors + 1;
        end

        // ---------------- TEST 8: MemWrite = 0 does not write ----------------
        MemWrite  = 1'b0;
        MemSize   = WORD;
        Address   = 32'd0;
        WriteData = 32'h9999_9999;
        #20;
        load_check(WORD, 32'd0, 32'hAAAA_1111, "no write when MemWrite=0");

        // ---------------- summary ----------------
        if (errors == 0)
            $display("ALL DATA MEMORY TESTS PASSED");
        else
            $display("%0d TEST(S) FAILED", errors);

        $finish;
    end

endmodule