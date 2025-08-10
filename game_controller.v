module game_controller(
    input wire clk,
    input wire rst_n,
    input wire [3:0] key_value,
    input wire key_valid,
    output reg [2:0] game_state,
    output reg [6:0] display_x,
    output reg [6:0] display_y,
    output reg [1:0] cell_state,
    output reg uart_start
);

    // Parameters
    parameter BOARD_SIZE = 8;
    parameter SHIPS_PER_PLAYER = 5;
    
    // Cell states
    localparam EMPTY = 2'b00;
    localparam SHIP = 2'b01;
    localparam HIT = 2'b10;
    localparam MISS = 2'b11;

    // Game states (matching top module)
    localparam INIT = 3'd0;
    localparam PLAYER1_SETUP = 3'd1;
    localparam PLAYER2_SETUP = 3'd2;
    localparam PLAYER1_TURN = 3'd3;
    localparam PLAYER2_TURN = 3'd4;
    localparam GAME_OVER = 3'd5;

    // Board storage - two 8x8 boards, 2 bits per cell
    reg [1:0] player1_board [0:BOARD_SIZE-1][0:BOARD_SIZE-1];
    reg [1:0] player2_board [0:BOARD_SIZE-1][0:BOARD_SIZE-1];
    
    // Game variables
    reg [3:0] ships_placed;
    reg [3:0] ships_remaining_p1;
    reg [3:0] ships_remaining_p2;
    reg [2:0] cursor_x;
    reg [2:0] cursor_y;
    reg input_state;  // 0 for x coordinate, 1 for y coordinate

    integer i;
    integer j;
    // Input handling
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            game_state <= INIT;
            ships_placed <= 0;
            ships_remaining_p1 <= SHIPS_PER_PLAYER;
            ships_remaining_p2 <= SHIPS_PER_PLAYER;
            cursor_x <= 0;
            cursor_y <= 0;
            input_state <= 0;
            uart_start <= 0;
            
            // Clear boards
            for (i = 0; i < BOARD_SIZE; i = i + 1) begin
                for (j = 0; j < BOARD_SIZE; j = j + 1) begin
                    player1_board[i][j] <= EMPTY;
                    player2_board[i][j] <= EMPTY;
                end
            end
        end else begin
            uart_start <= 0;  // Default state
            
            if (key_valid) begin
                case (game_state)
                    INIT: begin
                        game_state <= PLAYER1_SETUP;
                        uart_start <= 1;
                    end

                    PLAYER1_SETUP, PLAYER2_SETUP: begin
                        if (key_value < 8) begin  // Valid coordinate
                            if (!input_state) begin  // X coordinate
                                cursor_x <= key_value[2:0];
                                input_state <= 1;
                            end else begin  // Y coordinate
                                cursor_y <= key_value[2:0];
                                input_state <= 0;
                                
                                // Place ship
                                if (game_state == PLAYER1_SETUP) begin
                                    if (player1_board[cursor_x][key_value[2:0]] == EMPTY) begin
                                        player1_board[cursor_x][key_value[2:0]] <= SHIP;
                                        ships_placed <= ships_placed + 1;
                                        uart_start <= 1;
                                    end
                                end else begin
                                    if (player2_board[cursor_x][key_value[2:0]] == EMPTY) begin
                                        player2_board[cursor_x][key_value[2:0]] <= SHIP;
                                        ships_placed <= ships_placed + 1;
                                        uart_start <= 1;
                                    end
                                end
                                
                                // Check if all ships placed
                                if (ships_placed == SHIPS_PER_PLAYER - 1) begin
                                    ships_placed <= 0;
                                    game_state <= (game_state == PLAYER1_SETUP) ? PLAYER2_SETUP : PLAYER1_TURN;
                                end
                            end
                        end
                    end

                    PLAYER1_TURN, PLAYER2_TURN: begin
                        if (key_value < 8) begin
                            if (!input_state) begin
                                cursor_x <= key_value[2:0];
                                input_state <= 1;
                            end else begin
                                cursor_y <= key_value[2:0];
                                input_state <= 0;
                                
                                // Process shot
                                if (game_state == PLAYER1_TURN) begin
                                    if (player2_board[cursor_x][key_value[2:0]] == SHIP) begin
                                        player2_board[cursor_x][key_value[2:0]] <= HIT;
                                        ships_remaining_p2 <= ships_remaining_p2 - 1;
                                    end else if (player2_board[cursor_x][key_value[2:0]] == EMPTY) begin
                                        player2_board[cursor_x][key_value[2:0]] <= MISS;
                                    end
                                end else begin
                                    if (player1_board[cursor_x][key_value[2:0]] == SHIP) begin
                                        player1_board[cursor_x][key_value[2:0]] <= HIT;
                                        ships_remaining_p1 <= ships_remaining_p1 - 1;
                                    end else if (player1_board[cursor_x][key_value[2:0]] == EMPTY) begin
                                        player1_board[cursor_x][key_value[2:0]] <= MISS;
                                    end
                                end
                                
                                uart_start <= 1;
                                
                                // Check for game over
                                if (ships_remaining_p1 == 0 || ships_remaining_p2 == 0) begin
                                    game_state <= GAME_OVER;
                                end else begin
                                    game_state <= (game_state == PLAYER1_TURN) ? PLAYER2_TURN : PLAYER1_TURN;
                                end
                            end
                        end
                    end

                    GAME_OVER: begin
                        if (key_valid) begin  // Any key to restart
                            game_state <= INIT;
                            uart_start <= 1;
                        end
                    end
                endcase
            end
        end
    end

    // Output current cell state for display
    always @(*) begin
        display_x = {4'b0, cursor_x};
        display_y = {4'b0, cursor_y};
        
        case (game_state)
            PLAYER1_SETUP: cell_state = player1_board[cursor_x][cursor_y];
            PLAYER2_SETUP: cell_state = player2_board[cursor_x][cursor_y];
            PLAYER1_TURN: cell_state = player2_board[cursor_x][cursor_y];
            PLAYER2_TURN: cell_state = player1_board[cursor_x][cursor_y];
            default: cell_state = EMPTY;
        endcase
    end

endmodule 