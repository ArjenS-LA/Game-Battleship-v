`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/05/2025 03:24:30 AM
// Design Name: 
// Module Name: scoreboard
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


module scoreboard(
    input clk,
    input [1:0] p1_score,
    input [1:0] p2_score,
    output reg [6:0] seg,
    output reg [3:0] an
    );
    
    wire mux_clk;
    
    clock_dividers clkdv(.clk(clk), .mux_clk(mux_clk));
    
    reg [3:0] anode;
    
    always @ (posedge mux_clk) begin
        if (anode == 3)
            anode <= 0;
        else if(anode == 0)
            anode <= 3;
    end
    
    reg[1:0] selectDigit;
    reg[3:0] selectAnode;
    
    always @(*) begin
        if(anode == 0) begin
            selectDigit = p2_score;
            an = 4'b1110;
        end else if(anode == 3) begin
            selectDigit = p1_score;
            an = 4'b0111;
        end
        
        case(selectDigit)
           2'b00: seg = 7'b1000000; //0
           2'b01: seg = 7'b1111001; //1
           2'b10: seg = 7'b0100100; //2
           2'b11: seg  =7'b0110000; //3
           default: seg = 7'b1000000; //0
        endcase
    end    
    
endmodule
