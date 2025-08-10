// 8-N-1 transmitter, parameterised for 100 MHz clk @ 115 200 baud
module uart_tx #(
    parameter CLK_HZ   = 100_000_000,
    parameter BAUD     = 115_200,
    parameter BAUD_DIV = CLK_HZ / BAUD            // 868 for 100 MHz
) (
    input  wire clk,
    input  wire start,        // one-cycle pulse -> send tx_byte
    input  wire [7:0] data,   // ASCII or raw byte
    output reg  tx = 1'b1,    // UART line (idle high)
    output reg  busy = 1'b0   // HIGH while shifting
);

    reg [12:0] ctr   = 0;     // counts clk cycles 0..BAUD_DIV-1
    reg [9:0]  shift = 10'h3FF; // {stop(1),data[7:0],start(0)}

    always @(posedge clk) begin
        if (!busy) begin
            if (start) begin
                busy  <= 1'b1;
                shift <= {1'b1, data, 1'b0};   // load frame
                ctr   <= BAUD_DIV - 1;
            end
            tx <= 1'b1;                        // idle
        end else begin
            if (ctr == 0) begin                // next bit time?
                tx    <= shift[0];             // send LSB
                shift <= {1'b1, shift[9:1]};   // shift in 1's (stop)
                ctr   <= BAUD_DIV - 1;
                if (shift == 10'h3FF)          // all bits sent?
                    busy <= 1'b0;
            end else
                ctr <= ctr - 1;
        end
    end
endmodule
