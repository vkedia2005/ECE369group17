`timescale 1ns / 1ps

module DataMemory_tb(); 

    reg     [31:0]  Address;
    reg     [31:0]  WriteData;
    reg             Clk;
    reg             MemWrite;
    reg             MemRead;

    wire [31:0] ReadData;

    DataMemory u0(
        .Address(Address), 
        .WriteData(WriteData), 
        .Clk(Clk), 
        .MemWrite(MemWrite), 
        .MemRead(MemRead), 
        .ReadData(ReadData)
    ); 

	initial begin
		Clk <= 1'b0;
		forever #10 Clk <= ~Clk;
	end

	initial begin
	
        // Initialize inputs
        Address = 32'd0;
        WriteData = 32'd0;
        MemWrite = 1'b0;
        MemRead = 1'b0;

        #25; // Wait past the first couple of clock edges

        // --- TEST 1: Write Data to Word-Aligned Addresses ---
        MemWrite = 1'b1; // Enable writing
        
        Address = 32'd0; // Word 0 (Bytes 0-3)
        WriteData = 32'hAAAA_1111;
        #20;
        
        Address = 32'd4; // Word 1 (Bytes 4-7)
        WriteData = 32'hBBBB_2222;
        #20;
        
        Address = 32'd8; // Word 2 (Bytes 8-11)
        WriteData = 32'hCCCC_3333;
        #20;
        
        // --- TEST 2: Read Data Back ---
        MemWrite = 1'b0; // Turn off write enable
        MemRead = 1'b1;  // Turn on read enable
        
        Address = 32'd0;
        #10; // Read is asynchronous, so we don't need to wait a full clock cycle
        $display("Time: %0t | Read Addr 0: %h (Expect AAAA1111)", $time, ReadData);
        
        Address = 32'd4;
        #10;
        $display("Time: %0t | Read Addr 4: %h (Expect BBBB2222)", $time, ReadData);
        
        Address = 32'd8;
        #10;
        $display("Time: %0t | Read Addr 8: %h (Expect CCCC3333)", $time, ReadData);
        
        // --- TEST 3: Disable MemRead ---
        MemRead = 1'b0;
        #10;
        $display("Time: %0t | Read Addr 8 with MemRead=0: %h (Expect 00000000)", $time, ReadData);
        
        $finish;
	
	end

endmodule

