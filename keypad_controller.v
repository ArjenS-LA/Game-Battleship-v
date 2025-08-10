`timescale 1ns/1ps
module keypad_controller (
    input  wire        clk,      // 100 MHz
    input  wire        rst_n,    // BTN, active-low
    input  wire [3:0]  row,      // JB7-JB10 (pulled up)
    output reg  [3:0]  col,      // JB1-JB4 (tri-state)
    output reg  [3:0]  key_value,
    output reg         key_valid,
    output reg  [15:0] led
);
    // 1 ms full scan @ 100 MHz → 25 000 cycles per column slice
    parameter SCAN_INTERVAL = 100_000;   // 1 ms / 4 = 250 µs

    // FSM states
    localparam IDLE=2'd0, SCAN=2'd1, DEBOUNCE=2'd2, OUTPUT=2'd3;
    reg [1:0] state;

    reg [16:0] scan_counter;      // enough for 0-100 000
    reg [3:0]  debounce_row;
    reg [1:0]  col_count;         // 0-1-2-3

    // ---------- active-low decode table ----------
    wire [3:0] decoded_key = 
       (col_count==2'd0) ? (~row[0]?4'h1 : ~row[1]?4'h4 : ~row[2]?4'h7 : ~row[3]?4'hA : 4'hF) :
       (col_count==2'd1) ? (~row[0]?4'h2 : ~row[1]?4'h5 : ~row[2]?4'h8 : ~row[3]?4'h0 : 4'hF) :
       (col_count==2'd2) ? (~row[0]?4'h3 : ~row[1]?4'h6 : ~row[2]?4'h9 : ~row[3]?4'hB : 4'hF) :
                           (~row[0]?4'hC : ~row[1]?4'hD : ~row[2]?4'hE : ~row[3]?4'hF : 4'hF);

    // ---------- sequential logic ----------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state        <= IDLE;
            scan_counter <= 0;
            col          <= 4'bzzzz;   // all Hi-Z
            col_count    <= 0;
            key_valid    <= 1'b0;
            key_value    <= 4'hF;
            led          <= 16'h1111;
        end
        else begin
            // ----------- defaults every cycle -----------
            key_valid <= 1'b0;     // de-assert unless set
            led       <= led;      // hold previous value
            col       <= 4'bzzzz;  // default Hi-Z

            // toggle LED0 once per accepted key
            if (key_valid)
                led[0] <= ~led[0];

            case (state)
                // ----------------------------------------
                IDLE: begin
                    if (scan_counter == SCAN_INTERVAL-1) begin
                        scan_counter <= 0;
                        state        <= SCAN;
                        col_count    <= 0;
                        col[0]       <= 1'b0;   // drive first column low
                    end else
                        scan_counter <= scan_counter + 1'b1;
                end

                // ----------------------------------------
                SCAN: begin
                    if (row != 4'b1111) begin     // some key low
                        debounce_row <= row;
                        state        <= DEBOUNCE;
                    end
                    else if (col_count == 2'd3) begin
                        state     <= IDLE;
                        col_count <= 0;
                    end
                    else begin
                        // advance to next column
                        col_count <= col_count + 1'b1;
                        col[col_count+1] <= 1'b0;  // next column low (wrap handled by width)
                    end
                end

                // ----------------------------------------
                DEBOUNCE: begin
                    if (row == debounce_row) begin
                        key_value <= decoded_key;
                        key_valid <= 1'b1;        // one-clock pulse
                        state     <= OUTPUT;
                    end
                    else
                        state <= SCAN;            // bounce detected
                end

                // ----------------------------------------
                OUTPUT: begin
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule
