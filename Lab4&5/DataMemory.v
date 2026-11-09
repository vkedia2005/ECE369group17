`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// ECE369 - Computer Architecture
//
// Module - DataMemory.v
// Description - 1K x 32-bit data memory with word, halfword and byte access.
//
// INPUTS:-
// Address:   32-bit byte address. Address[11:2] selects the word,
//            Address[1:0] selects the byte/half inside the word.
// WriteData: 32-bit data to store (only low 16 bits used for sh, low 8 for sb).
// Clk:       Clock. Writes happen on the rising edge.
// MemWrite:  1 = store.
// MemRead:   1 = load (otherwise ReadData = 0).
// MemSize:   00 = word (lw/sw), 01 = half (lh/sh), 10 = byte (lb/sb).
//
// OUTPUTS:-
// ReadData:  32-bit load result. Byte/half loads are sign-extended.
//
// Byte order: little-endian (byte at Address[1:0]=00 is bits [7:0]).
// Accesses are assumed aligned (lh/sh at even addresses, lw/sw at multiples of 4).
////////////////////////////////////////////////////////////////////////////////

module DataMemory(Address, WriteData, Clk, MemWrite, MemRead, MemSize, ReadData);

    input  [31:0] Address;
    input  [31:0] WriteData;
    input         Clk;
    input         MemWrite;
    input         MemRead;
    input  [1:0]  MemSize;

    output reg [31:0] ReadData;

    // size encoding
    localparam SIZE_WORD = 2'b00;
    localparam SIZE_HALF = 2'b01;
    localparam SIZE_BYTE = 2'b10;

    // 1K words of 32 bits
    reg [31:0] memory [0:1023];

    // Zero everything, then load contents from file
    integer i;
    initial begin
        for (i = 0; i < 1024; i = i + 1)
            memory[i] = 32'd0;
        $readmemh("data_memory.mem", memory);
    end

    // ---------------- WRITE (synchronous) ----------------
    always @(posedge Clk) begin
        if (MemWrite) begin
            case (MemSize)
                SIZE_WORD: memory[Address[11:2]] <= WriteData;

                SIZE_HALF: begin
                    if (Address[1])
                        memory[Address[11:2]][31:16] <= WriteData[15:0];
                    else
                        memory[Address[11:2]][15:0]  <= WriteData[15:0];
                end

                SIZE_BYTE: begin
                    case (Address[1:0])
                        2'b00: memory[Address[11:2]][7:0]   <= WriteData[7:0];
                        2'b01: memory[Address[11:2]][15:8]  <= WriteData[7:0];
                        2'b10: memory[Address[11:2]][23:16] <= WriteData[7:0];
                        2'b11: memory[Address[11:2]][31:24] <= WriteData[7:0];
                    endcase
                end

                default: ; // no write for undefined size
            endcase
        end
    end

    // ---------------- READ (combinational) ----------------
    reg [31:0] word;
    reg [15:0] half;
    reg [7:0]  byte_val;

    always @(*) begin
        // defaults so no latches are inferred
        word     = memory[Address[11:2]];
        half     = 16'd0;
        byte_val = 8'd0;
        ReadData = 32'd0;

        if (MemRead) begin
            case (MemSize)
                SIZE_WORD: ReadData = word;

                SIZE_HALF: begin
                    half     = Address[1] ? word[31:16] : word[15:0];
                    ReadData = {{16{half[15]}}, half};       // sign-extend
                end

                SIZE_BYTE: begin
                    case (Address[1:0])
                        2'b00: byte_val = word[7:0];
                        2'b01: byte_val = word[15:8];
                        2'b10: byte_val = word[23:16];
                        2'b11: byte_val = word[31:24];
                    endcase
                    ReadData = {{24{byte_val[7]}}, byte_val}; // sign-extend
                end

                default: ReadData = 32'd0;
            endcase
        end
    end

endmodule