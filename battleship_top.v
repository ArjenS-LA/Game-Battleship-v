`timescale 1ns/1ps
//////////////////////////////////////////////////////////////////////////////////
// Top-level wrapper for the UART-driven Battleship demo
//////////////////////////////////////////////////////////////////////////////////
module battleship_top (
    input  wire        clk,          // 50 MHz on-board clock
    input  wire        btnC,        // BTN - active-low reset
    input  wire [3:0]  row,          // keypad rows (JB7-JB10)
    output wire [3:0]  col,          // keypad cols (JB1-JB4)
    output wire        uart_tx,       // USB-UART TX (A18)
    output wire [15:0] led
);
    //--- internal interconnects ---
    wire [3:0] key_value;
    wire       key_valid;

    wire [2:0] game_state;
    wire [6:0] disp_x, disp_y;
    wire [1:0] cell_state;
    wire [7:0] uart_data;
    wire       uart_ready, uart_start;
    
    wire rst_n = ~btnC;

    //--- keypad scan & decode ---
    keypad_controller u_keypad (
        .clk      (clk),
        .rst_n    (rst_n),
        .row      (row),
        .col      (col),
        .key_value(key_value),
        .key_valid(key_valid),
        .led(led)
    );

    //--- game rule engine ---
    game_controller u_game (
        .clk          (clk),
        .rst_n        (rst_n),
        .key_value    (key_value),
        .key_valid    (key_valid),
        .game_state   (game_state),
        .display_x    (disp_x),
        .display_y    (disp_y),
        .cell_state   (cell_state),
        .uart_start   (uart_start)
    );

    //--- UART message formatter (refactored) ---
    display_controller u_disp (
        .clk        (clk),
        .rst_n      (rst_n),
        .game_state (game_state),
        .display_x  (disp_x),
        .display_y  (disp_y),
        .cell_state (cell_state),
        .uart_ready (uart_ready),
        .uart_start (uart_start),
        .uart_data  (uart_data)
    );

    //--- UART transmitter (9600 baud @ 50 MHz) ---
    uart_tx #(.CLK_FREQ(50_000_000), .BAUD_RATE(9600)) u_uart (
        .clk      (clk),
        .rst_n    (rst_n),
        .data_in  (uart_data),
        .start_tx (uart_start),
        .tx       (uart_tx),
        .tx_ready (uart_ready)
    );
endmodule
