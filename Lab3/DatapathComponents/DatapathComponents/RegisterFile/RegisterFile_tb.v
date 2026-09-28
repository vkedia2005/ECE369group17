`timescale 1ns / 1ps

module RegisterFile_tb();

	reg [4:0] ReadRegister1;
	reg [4:0] ReadRegister2;
	reg	[4:0] WriteRegister;
	reg [31:0] WriteData;
	reg RegWrite;
	reg Clk;

	wire [31:0] ReadData1;
	wire [31:0] ReadData2;


	RegisterFile u0(
		.ReadRegister1(ReadRegister1), 
		.ReadRegister2(ReadRegister2), 
		.WriteRegister(WriteRegister), 
		.WriteData(WriteData), 
		.RegWrite(RegWrite), 
		.Clk(Clk), 
		.ReadData1(ReadData1), 
		.ReadData2(ReadData2)
	);

	initial begin
		Clk <= 1'b0;
		forever #10 Clk <= ~Clk;
	end

    // Declare a loop variable
    integer i;

	initial begin
	
        // Initialize all inputs to 0
        ReadRegister1 = 5'd0;
        ReadRegister2 = 5'd0;
        WriteRegister = 5'd0;
        WriteData = 32'd0;
        RegWrite = 1'b0;
        
        #25; // Wait past the first clock edge
        
        // --- TEST 1: Verify Register 0 is hardwired to 0 ---
        RegWrite = 1'b1;
        WriteRegister = 5'd0;
        WriteData = 32'hDEADBEEF; // Arbitrary test data
        #20;
        
        // --- TEST 2: Write values to registers 8 through 25 ---
        for (i = 8; i <= 25; i = i + 1) begin
            WriteRegister = i;
            // Generate a unique hex value based on the register number (e.g., Reg 8 = 08080808)
            WriteData = i * 32'h01010101; 
            #20; // Wait one clock period per write
        end
        
        // Turn off write enable before starting reads
        RegWrite = 1'b0; 
        #20;
        
        // --- TEST 3: Read values 2-by-2 ---
        for (i = 8; i <= 24; i = i + 2) begin
            ReadRegister1 = i;
            ReadRegister2 = i + 1;
            #20; // Wait for falling edge read
            $display("Time: %0t | Reg[%0d] = %h | Reg[%0d] = %h", $time, i, ReadData1, i+1, ReadData2);
        end
        
        // Read Register 0 again to ensure the earlier write didn't stick
        ReadRegister1 = 5'd0;
        #20;
        $display("Time: %0t | Reg[0] = %h (Should be 00000000)", $time, ReadData1);

        $finish; // End simulation cleanly
	
	end

endmodule