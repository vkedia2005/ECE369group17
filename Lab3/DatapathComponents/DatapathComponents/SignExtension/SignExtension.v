`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////
// ECE369 - Computer Architecture
// 
// Module - SignExtension.v
// Description - Sign extension module.
////////////////////////////////////////////////////////////////////////////////
module SignExtension(
    input  [15:0] in,
    input         ExtOp,
    output [31:0] out
);

    // If ExtOp is 1, replicate sign bit in[15]. If ExtOp is 0, pad with 16 zeros.
    assign out = (ExtOp == 1'b1) ? { {16{in[15]}}, in } : { 16'd0, in };

endmodule
