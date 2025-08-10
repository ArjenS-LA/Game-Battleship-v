`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/05/2025 12:47:50 AM
// Design Name: 
// Module Name: display
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

// DECODER 4x16

module display(
    input clk,
    input [3:0] row,
    output [3:0] col,
    output reg [15:0] value,
    output wire [3:0] key
    );
    
    keyFromSwitches k(.clk(clk), .row(row), .col(col), .key(key));
    
    always @(posedge clk) begin
        case(key)
             4'b0000: value <= 16'b0000000000000001;
             4'b0001: value <= 16'b0000000000000010;
             4'b0010: value <= 16'b0000000000000100;
             4'b0011: value <= 16'b0000000000001000;
             4'b0100: value <= 16'b0000000000010000;
             4'b0101: value <= 16'b0000000000100000;
             4'b0110: value <= 16'b0000000001000000;
             4'b0111: value <= 16'b0000000010000000;
             4'b1000: value <= 16'b0000000100000000;
             4'b1001: value <= 16'b0000001000000000;
             4'b1010: value <= 16'b0000010000000000;
             4'b1011: value <= 16'b0000100000000000;
             4'b1100: value <= 16'b0001000000000000;
             4'b1101: value <= 16'b0010000000000000;
             4'b1110: value <= 16'b0100000000000000;
             4'b1111: value <= 16'b1000000000000000;
        endcase
    end
    
endmodule
