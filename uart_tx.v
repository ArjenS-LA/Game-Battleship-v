module uart_tx(
    input wire clk,              // System clock
    input wire rst_n,           // Active low reset
    input wire [7:0] data_in,   // Data to transmit
    input wire start_tx,        // Start transmission
    output reg tx,              // UART TX line
    output reg tx_ready         // Transmitter ready for next byte
);

    // Parameters
    parameter CLK_FREQ = 100_000_000;  // 50MHz system clock
    parameter BAUD_RATE = 9600;       // UART baud rate
    parameter CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;

    // State definitions
    reg [2:0] state;
    localparam IDLE = 3'd0;
    localparam START_BIT = 3'd1;
    localparam DATA_BITS = 3'd2;
    localparam STOP_BIT = 3'd3;

    // Internal signals
    reg [15:0] clk_count;
    reg [2:0] bit_index;
    reg [7:0] data_reg;

    // UART TX logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            tx <= 1'b1;         // Idle high
            tx_ready <= 1'b1;
            clk_count <= 0;
            bit_index <= 0;
        end else begin
            case (state)
                IDLE: begin
                    tx <= 1'b1;         // Idle high
                    tx_ready <= 1'b1;
                    clk_count <= 0;
                    bit_index <= 0;

                    if (start_tx) begin
                        state <= START_BIT;
                        data_reg <= data_in;
                        tx_ready <= 1'b0;
                    end
                end

                START_BIT: begin
                    tx <= 1'b0;  // Start bit is low

                    if (clk_count < CLKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1;
                    end else begin
                        state <= DATA_BITS;
                        clk_count <= 0;
                    end
                end

                DATA_BITS: begin
                    tx <= data_reg[bit_index];  // LSB first

                    if (clk_count < CLKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1;
                    end else begin
                        clk_count <= 0;
                        
                        if (bit_index < 7) begin
                            bit_index <= bit_index + 1;
                        end else begin
                            state <= STOP_BIT;
                        end
                    end
                end

                STOP_BIT: begin
                    tx <= 1'b1;  // Stop bit is high

                    if (clk_count < CLKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1;
                    end else begin
                        state <= IDLE;
                    end
                end

                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule 