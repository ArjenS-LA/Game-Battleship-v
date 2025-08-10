`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/05/2025 12:38:05 AM
// Design Name: 
// Module Name: keyFromSwitches
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


// NUMPAD LOGIC GO HERE

module keyFromSwitches(
    input clk,
    input [3:0] row,
    output [3:0] col,
    output wire [3:0] key
    );
        
    decoder d(.clk(clk), .row(row), .col(col), .dec_out(key));
    
    /*always @(posedge clk) begin
        key <= sw;
    end*/
endmodule
