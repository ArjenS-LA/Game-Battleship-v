`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
module clock_dividers(
    input wire clk,
    output reg mux_clk = 0
);

    // The Basys3 clock is 100MHz (i.e. 100 mil clock cycles per second).
    // In order to blink the led at 1Hz, we toggle it every 50 mil cycles.
    reg [31:0] counter = 0;

    always @(posedge clk) begin
  
        if (counter == 100000) begin
            counter <= 0;
            mux_clk <= ~mux_clk;
        end else begin
            counter <= counter + 1;
        end
    end
endmodule
