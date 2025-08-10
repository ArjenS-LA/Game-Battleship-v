`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/05/2025 01:15:48 AM
// Design Name: 
// Module Name: battleship_top
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


module battleship_top(
    input clk,
    input confirm,
    input btnReset,
    input [3:0] row,
    output [3:0] col,
    output [15:0] led,
    output [6:0] seg,
    output [3:0] an,
    output uart_tx
    );
    
    //UART SETUP
    // ---------- declarations ----------    
    reg [2:0] tx_stage = 3'd0;
    reg [7:0] tx_byte;
    reg       tx_start;
    wire      tx_busy;
    
    uart_tx #(.BAUD_DIV(868)) UTX (
        .clk   (clk),
        .start (tx_start),
        .data  (tx_byte),
        .tx    (uart_tx),
        .busy  (tx_busy)
    );
   
    reg [15:0] p1_board = 16'b0000000000000000;
    reg [15:0] p2_board = 16'b0000000000000000;
    
    // PLACEMENT MODE VARS
    reg [1:0] p1_ships = 2'b00;
    reg [1:0] p2_ships = 2'b00;
    
    scoreboard scoreboard(
        .clk(clk),
        .p1_score(p1_ships),
        .p2_score(p2_ships),
        .seg(seg),
        .an(an)
    );
    
    // GAME MODE VARS 
    reg [15:0] p1_guesses = 16'b0000000000000000;
    reg [15:0] p2_guesses = 16'b0000000000000000;
    
    reg player = 1'b0;
    reg [1:0] mode = 2'b00;
    reg winner = 1'b0;
    
    wire [3:0] sw;
        
    wire [15:0] select_led;
    display d(.clk(clk), .row(row), .col(col), .value(select_led), .key(sw));
    
    //reg  prev_confirm = 1'b0;   // remembers what BTN_C looked like on the *previous* clock
    //wire confirm_pulse = confirm & ~prev_confirm;  // HIGH for exactly one clk tick when a 0→1 edge occurs
    
    reg [16:0] c_debounce = 0;     // 100 MHz →  6.5 ms when full
    reg confirm_pulse = 0;   // clean, single-cycle pulse
    
    reg player_snap;         // 0 = P1, 1 = P2
    reg [3:0] square_snap;         // 0-15

    
    always @(posedge clk) begin
        //prev_confirm <= confirm;
        tx_start <= 1'b0; 

        if (confirm == 1'b0)
            c_debounce <= 17'd0;                    // button released
        else if (c_debounce != 17'h1_FFFF)
            c_debounce <= c_debounce + 1'b1;        // count while held
    
        //---------------- clean "press" one-shot ----------  
        // generate ONE pulse when the counter reaches the top
        confirm_pulse <= (c_debounce == 17'h1_FFFE);
        
        if (confirm_pulse) begin
            player_snap  <= player; // value *before* game FSM updates
            square_snap  <= sw;
        end
        
        case (tx_stage)
            3'd0: begin                                 // idle
                if (confirm_pulse && !tx_busy) begin
                    tx_byte  <= "P";                    // byte 0
                    tx_start <= 1'b1;
                    tx_stage <= 3'd1;
                end
            end
    
            3'd1: if (!tx_busy && !tx_start) begin                   // byte 1
                    tx_byte  <= player_snap ? "2" : "1";
                    tx_start <= 1'b1;
                    tx_stage <= 3'd2;
                  end
    
            3'd2: if (!tx_busy && !tx_start) begin                   // byte 2 (colon)
                    tx_byte  <= ":";
                    tx_start <= 1'b1;
                    tx_stage <= 3'd3;
                  end
    
            3'd3: if (!tx_busy && !tx_start) begin                   // byte 3 (hex nibble)
                    tx_byte  <= (square_snap < 10) ? ("0"+square_snap)
                                                   : ("A"+square_snap-4'd10);
                    tx_start <= 1'b1;
                    tx_stage <= 3'd4;
                  end
    
            3'd4: if (!tx_busy && !tx_start) begin                   // byte 4 (CR)
                    tx_byte  <= 8'd13;
                    tx_start <= 1'b1;
                    tx_stage <= 3'd5;
                  end
    
            3'd5: if (!tx_busy && !tx_start) begin                   // byte 5 (LF)
                    tx_byte  <= 8'd10;
                    tx_start <= 1'b1;
                    tx_stage <= 3'd0;                   // back to idle
                  end
        endcase
        
                
        /*if (confirm_pulse && !tx_busy) begin
            // ASCII digit for the square (0-15). 0-9 = '0'+n, 10-15 = 'A'+(n-10)
            if (sw < 10)
                tx_byte  <= "0" + sw[3:0];
            else
                tx_byte  <= "A" + (sw[3:0] - 4'd10);
            tx_start <= 1'b1;          // one-cycle pulse
        end*/
        
        if (confirm_pulse) begin
            if (mode == 0) begin // PLACEMENT MODE
                if (!player) begin
                    /* ---- Player 1's turn ---- */
                    if(btnReset) begin // RESTART PLACEMENT 
                        p1_board <= 0;
                        p1_ships <= 0;
                    end
                    if (!p1_board[sw] && p1_ships < 3) begin
                        p1_board[sw] <= 1'b1;
                        p1_ships <= p1_ships + 1'b1;
                        if (p1_ships == 2)          // just placed 3rd ship
                            player <= 1'b1;         // hand control to P2
                    end
                end else begin
                    /* ---- Player 2's turn ---- */
                    if(btnReset) begin // RESTART PLACEMENT
                        p2_board <= 0;
                        p2_ships <= 0;
                        
                    end
                    if (!p2_board[sw] && p2_ships < 3) begin
                        p2_board[sw] <= 1'b1;
                        p2_ships <= p2_ships + 1'b1;
                        if (p2_ships == 2) begin          // just placed 3rd ship
                            player <= 1'b0;         // game mode
                            mode <= 2'b01;
                        end
                    end
                end
            end else if (mode == 1) begin // GAME MODE
                if (!player) begin
                    // Player 1's turn
                    if(!p1_guesses[sw]) begin
                        if (p2_board[sw]) begin //P1 hit
                            p1_guesses[sw] <= 1'b1;     
                            player <= 1'b1;
                            p2_ships <= p2_ships - 1;
                            if (p2_ships == 1) begin
                                mode <= 2'b10; //GAME OVER
                                winner <= 1'b0;
                            end
                        end else begin
                            player <= 1'b1;
                        end
                    end
                end else begin
                    /* ---- Player 2's turn ---- */
                    if(!p2_guesses[sw]) begin
                        if (p1_board[sw]) begin //P2 hit
                            p2_guesses[sw] <= 1'b1;     
                            player <= 1'b0; 
                            p1_ships <= p1_ships - 1;
                            if (p1_ships == 1) begin
                                mode <= 2'b10; //GAME OVER
                                winner <= 1'b1;
                            end          
                        end else begin
                            player <= 1'b0;
                        end
                    end
                end
            end else if (mode == 2) begin // WIN STATE
                if (btnReset) begin // RESET GAME
                    p1_board <= 0;
                    p2_board <= 0;
                    p1_guesses <= 0;
                    p2_guesses <= 0;
                    p1_ships <= 0;
                    p2_ships <= 0;
                    mode <= 0;
                    player <= 1'b0;
                end
            end
        end
    end

    /* ---------- d) LED driver ---------- */
    reg [15:0] led_r;
    always @(*) begin
        if (mode == 0 && !player && p1_ships < 3)          // Player 1 still placing
            led_r = p1_board | select_led;    // show his ships + cursor
        else if (mode == 0 && player && p2_ships < 3)      // Player 2 still placing
            led_r = p2_board | select_led;
        else if (mode == 1 && !player)      // Player 1 firing
            led_r = p1_guesses | select_led; 
        else if (mode == 1 && player)     // Player 2  firing
            led_r = p2_guesses | select_led;
        else if (mode == 2 && !winner) // Player 1 Wins                                        
            led_r = 16'b1111111111111111; 
        else if (mode == 2 && winner) // Player 2 Wins
            led_r = 16'b1111111111111111;    
    end

    assign led = led_r;
endmodule
