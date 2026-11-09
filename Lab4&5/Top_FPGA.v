`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// ECE369A - Computer Organization (Lab 5 FPGA Top-Level Wrapper)
// Group 17
// Percent Effort: [Member 1]: XX%, [Member 2]: XX%, [Member 3]: XX%
//
// Module - Top_FPGA.v
// Description - Connects ClkDiv, Top_Datapath, and Two4DigitDisplay to run the
//               5-stage pipelined MIPS processor on the Nexys A7-100T FPGA.
//               Top-level port names match Two4DigitDisplay.xdc exactly.
//
// Display Mapping on the Nexys A7 8-Digit 7-Segment Display:
//   - Left 4 digits  (NumberB = PC[15:0])        : Current WB Program Counter
//   - Right 4 digits (NumberA = WriteData[15:0]) : Register File WriteData
////////////////////////////////////////////////////////////////////////////////

module Top_FPGA(
    input Clk,              // 100 MHz board clock (Pin E3)
    input Reset,            // Center pushbutton BTNC (Pin N17)
    output [6:0] out7,      // 7-segment cathodes CA..CG
    output [7:0] en_out     // 7-segment anodes AN7..AN0
);

    wire ClkOut;
    (* mark_debug = "true" *) wire [31:0] PC;
    (* mark_debug = "true" *) wire [31:0] WriteData;

    // -------------------------------------------------------------------------
    // 1. Clock Divider (100 MHz -> ~1 Hz slow clock for the datapath)
    // Note: Rst on ClkDiv is tied to 1'b0 so ClkOut keeps ticking while you
    // press the physical Reset button (BTNC). Because Top_Datapath and its
    // pipeline registers use synchronous reset on posedge ClkOut, ClkOut must
    // keep toggling for Reset to clear the datapath!
    // -------------------------------------------------------------------------
    ClkDiv ClockDivider (
        .Clk(Clk),
        .Rst(1'b0),
        .ClkOut(ClkOut)
    );

    // -------------------------------------------------------------------------
    // 2. 5-Stage Pipelined MIPS Datapath (clocked by slow ClkOut)
    // -------------------------------------------------------------------------
    Top_Datapath Datapath (
        .Clk(ClkOut),
        .Rst(Reset),
        .PC(PC),
        .WriteData(WriteData)
    );

    // -------------------------------------------------------------------------
    // 3. Two 4-Digit 7-Segment Display (clocked by fast 100 MHz Clk)
    //    - NumberB (left 4 digits, AN7..AN4)  = PC[15:0]
    //    - NumberA (right 4 digits, AN3..AN0) = WriteData[15:0]
    // -------------------------------------------------------------------------
    Two4DigitDisplay Display (
        .Clk(Clk),
        .NumberA(WriteData[15:0]),
        .NumberB(PC[15:0]),
        .out7(out7),
        .en_out(en_out)
    );

endmodule