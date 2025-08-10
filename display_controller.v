`timescale 1ns/1ps
//////////////////////////////////////////////////////////////////////////////////
// Pure-Verilog-2001 display_controller  (single always-block, no MDRV-1)
//////////////////////////////////////////////////////////////////////////////////
module display_controller (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [2:0]  game_state,
    input  wire [6:0]  display_x,
    input  wire [6:0]  display_y,
    input  wire [1:0]  cell_state,
    input  wire        uart_ready,
    input  wire        uart_start,
    output reg  [7:0]  uart_data
);
    // ---------- ASCII constants ----------
    parameter [7:0] CR = 8'h0D;
    parameter [7:0] LF = 8'h0A;
    parameter [7:0] EMPTY_CH = 8'h7E;  // "~"
    parameter [7:0] SHIP_CH  = "S";
    parameter [7:0] HIT_CH   = "X";
    parameter [7:0] MISS_CH  = "O";

    // ---------- FSM encoding ----------
    parameter [1:0] S_IDLE = 2'd0,
                    S_LOAD = 2'd1,
                    S_SEND = 2'd2;
    reg [1:0] state;

    // ---------- message RAM ----------
    reg [7:0] msg [0:127];
    reg [6:0] msg_len;   // bytes valid
    reg [6:0] index;     // byte pointer

    // ---------- utility: decimal ASCII digit ----------
    function [7:0] ascii_digit;
        input [3:0] val;
        begin
            ascii_digit = 8'h30 + val;   // '0' + val
        end
    endfunction

    // ---------- single always-block ----------
    integer k;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state     <= S_IDLE;
            uart_data <= 8'h00;
            msg_len   <= 0;
            index     <= 0;
        end else begin
            case (state)
                //------------------------------------------------------
                // 0. wait for uart_start
                //------------------------------------------------------
                S_IDLE: begin
                    if (uart_start) begin
                        //--------------------------------------------------
                        // build message
                        //--------------------------------------------------
                        case (game_state)
                            //------------------------------------------------
                            3'd0: begin // INIT
                                msg_len = 24;
                                // "Welcome to Battleship!\r\n"
                                msg[0]  = "W"; msg[1]  = "e"; msg[2]  = "l";
                                msg[3]  = "c"; msg[4]  = "o"; msg[5]  = "m";
                                msg[6]  = "e"; msg[7]  = " "; msg[8]  = "t";
                                msg[9]  = "o"; msg[10] = " "; msg[11] = "B";
                                msg[12] = "a"; msg[13] = "t"; msg[14] = "t";
                                msg[15] = "l"; msg[16] = "e"; msg[17] = "s";
                                msg[18] = "h"; msg[19] = "i"; msg[20] = "p";
                                msg[21] = "!"; msg[22] = CR;  msg[23] = LF;
                            end
                            //------------------------------------------------
                            3'd1, 3'd2: begin // PLAYERx_SETUP
                                msg_len = 32;
                                // "Player X place ship at (d,d):\r\n"
                                msg[0]  = "P"; msg[1]  = "l"; msg[2]  = "a";
                                msg[3]  = "y"; msg[4]  = "e"; msg[5]  = "r";
                                msg[6]  = " ";
                                msg[7]  = (game_state==3'd1) ? "1" : "2";
                                msg[8]  = " "; msg[9]  = "p"; msg[10] = "l";
                                msg[11] = "a"; msg[12] = "c"; msg[13] = "e";
                                msg[14] = " "; msg[15] = "s"; msg[16] = "h";
                                msg[17] = "i"; msg[18] = "p"; msg[19] = " ";
                                msg[20] = "a"; msg[21] = "t"; msg[22] = " ";
                                msg[23] = "(";
                                msg[24] = ascii_digit(display_x[3:0]);
                                msg[25] = ",";
                                msg[26] = ascii_digit(display_y[3:0]);
                                msg[27] = ")";
                                msg[28] = ":"; msg[29] = " ";
                                msg[30] = CR;  msg[31] = LF;
                            end
                            //------------------------------------------------
                            3'd3, 3'd4: begin // PLAYERx_TURN
                                msg_len = 40;
                                // "Player X fired at (d,d): Y\r\n"
                                msg[0]  = "P"; msg[1]  = "l"; msg[2]  = "a";
                                msg[3]  = "y"; msg[4]  = "e"; msg[5]  = "r";
                                msg[6]  = " ";
                                msg[7]  = (game_state==3'd3) ? "1" : "2";
                                msg[8]  = " "; msg[9]  = "f"; msg[10] = "i";
                                msg[11] = "r"; msg[12] = "e"; msg[13] = "d";
                                msg[14] = " "; msg[15] = "a"; msg[16] = "t";
                                msg[17] = " "; msg[18] = "(";
                                msg[19] = ascii_digit(display_x[3:0]);
                                msg[20] = ",";
                                msg[21] = ascii_digit(display_y[3:0]);
                                msg[22] = ")"; msg[23] = ":"; msg[24] = " ";
                                case (cell_state)
                                    2'b00: msg[25] = EMPTY_CH;
                                    2'b01: msg[25] = SHIP_CH;
                                    2'b10: msg[25] = HIT_CH;
                                    2'b11: msg[25] = MISS_CH;
                                endcase
                                msg[26] = CR; msg[27] = LF;
                            end
                            //------------------------------------------------
                            3'd5: begin // GAME_OVER
                                msg_len = 32;
                                // "Game Over! Player X wins!\r\n"
                                msg[0]  = "G"; msg[1]  = "a"; msg[2]  = "m";
                                msg[3]  = "e"; msg[4]  = " "; msg[5]  = "O";
                                msg[6]  = "v"; msg[7]  = "e"; msg[8]  = "r";
                                msg[9]  = "!"; msg[10] = " "; msg[11] = "P";
                                msg[12] = "l"; msg[13] = "a"; msg[14] = "y";
                                msg[15] = "e"; msg[16] = "r"; msg[17] = " ";
                                msg[18] = (cell_state[0]) ? "1" : "2";
                                msg[19] = " "; msg[20] = "w"; msg[21] = "i";
                                msg[22] = "n"; msg[23] = "s"; msg[24] = "!";
                                msg[25] = CR; msg[26] = LF;
                            end
                            default: begin
                                msg_len = 2; msg[0] = CR; msg[1] = LF;
                            end
                        endcase
                        //--------------------------------------------------
                        index <= 0;
                        state <= S_SEND;
                    end
                end

                //------------------------------------------------------
                // 1. send bytes while UART is ready
                //------------------------------------------------------
                S_SEND: begin
                    if (uart_ready) begin
                        uart_data <= msg[index];
                        if (index == msg_len-1)
                            state <= S_IDLE;
                        else
                            index <= index + 1'b1;
                    end
                end

                default: state <= S_IDLE;
            endcase
        end
    end
endmodule
