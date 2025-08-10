# Battleship FPGA - Keypad Decoder Testbench
## Overview
This project is part of the **Battleship FPGA** game implementation.It contains the **decoder** module, which scans a 4x4 keypad, determines which key is pressed, and outputs its corresponding 4-bit binary code.
The included **testbench**  simulates keypad presses and displays results in the console in the format:
[time] P1(<row>:<col>) -> dec_out = <hex>Example output:
[500000 ns] P1(1:0) -> dec_out = 7
[1200000 ns] P1(2:0) -> dec_out = 4
[1900000 ns] P1(3:0) -> dec_out = 1## File Structure
src/
 ├── decoder.v           # Keypad scanning and decoding logic
 ├── clock_dividers.v    # Clock divider for timing control
 ├── display.v           # Seven-segment display driver
 ├── scoreboard.v        # Game scoreboard logic
 ├── uart_tx.v           # UART transmitter for game logs
 └── battleship_top.v    # Top-level Battleship FPGA module

sim/
 └── tb_decoder.v        # Verilog testbench for decoder module## How It Works
**Decoder Module**
Inputs:
`clk`: System clock 
`row[3:0]`: Keypad row lines 
Outputs:
`col[3:0]`: Column drive lines 
`dec_out[3:0]`: Binary code for the pressed key
The decoder cycles through 4 columns using a `col_select` counter, setting `col` accordingly. If a row is active  when `scan_timer == LAG`, it updates `dec_out` with the correct value.
## Testbench
Generates a 100 MHz clock.
Simulates key presses by driving `row` low.
Waits for the scan cycle to detect the press.
Prints messages showing:
- Player ID 
- Row/column indices
- Decoded key value
## Simulation in Vivado
Open Vivado and add `decoder.v` and `tb_decoder.v`.
Set `tb_decoder` as the top simulation source.
Run simulation and check:
- Waveform for `col`, `row`, and `dec_out`.
- Console for formatted `P1(row:col)` messages.
## Example Console Output
Starting decoder test...
[100000 ns] P1(0:0) -> dec_out = 0
[200000 ns] P1(1:0) -> dec_out = 4
[300000 ns] P1(2:1) -> dec_out = 5
[400000 ns] P1(3:3) -> dec_out = D
[Testbench] Finished all test presses.## Next Steps
- Integrate with the Battleship FPGA top-level.
- Use keypad inputs for shot coordinates.
- Add automated verification for expected outputs.
