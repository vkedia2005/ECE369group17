`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// ECE369A - Computer Organization (Lab 7 FPGA Top-Level Wrapper)
// Group 17
// Percent Effort: Vasu Kedia 33.3%, Noah Kramer 33.3%, Luke Mccullough 33.3%
//
// Module - Top_FPGA.v
// Description - Runs vbsme on the pipelined datapath (with hazard detection)
//               on the Nexys A7-100T and shows the (row, col) of the block
//               with the current minimum SAD.
//
// Display (hexadecimal):
//   - Left 4 digits  (NumberB) = $v0[15:0] : row of the current minimum SAD
//   - Right 4 digits (NumberA) = $v1[15:0] : col of the current minimum SAD
// Starts at (0, 0) and changes every time a block with a smaller SAD is found.
////////////////////////////////////////////////////////////////////////////////

module Top_FPGA(
    input Clk,              // 100 MHz board clock (Pin E3)
    input Reset,            // Center pushbutton BTNC (Pin N17)
    output [6:0] out7,      // 7-segment cathodes CA..CG
    output [7:0] en_out     // 7-segment anodes AN7..AN0
);

    wire ClkOut;
    wire [31:0] PC;
    wire [31:0] WriteData;
    wire [31:0] V0;
    wire [31:0] V1;

    // -------------------------------------------------------------------------
    // 1. Clock Divider (100 MHz -> ~5 kHz with DivVal = 10000)
    //    Rst tied to 0 so ClkOut keeps running while Reset is held; the
    //    datapath's pipeline registers reset on a ClkOut edge.
    // -------------------------------------------------------------------------
    ClkDiv ClockDivider (
        .Clk(Clk),
        .Rst(1'b0),
        .ClkOut(ClkOut)
    );

    // -------------------------------------------------------------------------
    // 2. 5-Stage Pipelined MIPS Datapath with hazard detection
    // -------------------------------------------------------------------------
    Top_Datapath Datapath (
        .Clk(ClkOut),
        .Rst(Reset),
        .PC(PC),
        .WriteData(WriteData),
        .V0(V0),
        .V1(V1)
    );

    // -------------------------------------------------------------------------
    // 3. Display: left = row ($v0), right = col ($v1)
    // -------------------------------------------------------------------------
    Two4DigitDisplay Display (
        .Clk(Clk),
        .NumberA(V1[15:0]),
        .NumberB(V0[15:0]),
        .out7(out7),
        .en_out(en_out)
    );

endmodule