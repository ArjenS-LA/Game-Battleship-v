\# Battleship FPGA — Keypad Decoder Testbench

\## Overview

This project is part of the \*\*Battleship FPGA\*\* game implementation.\
It contains the \*\*`decoder`\*\* module, which scans a 4×4 keypad, determines which key is pressed, and outputs its corresponding 4-bit binary code.

The included \*\*testbench\*\* (`tb_decoder.v`) simulates keypad presses and displays results in the console in the format:

\```
[time] P1(\<row\>:\<col\>) → dec\_out = \<hex\>
\```

Example output:

\```
[500000 ns] P1(1:0) → dec\_out = 7
[1200000 ns] P1(2:0) → dec\_out = 4
[1900000 ns] P1(3:0) → dec\_out = 1
\```

---

\## File Structure

\```
src/
 ├── decoder.v           \# Keypad scanning and decoding logic
 ├── clock_dividers.v    \# Clock divider for timing control
 ├── display.v           \# Seven-segment display driver
 ├── scoreboard.v        \# Game scoreboard logic
 ├── uart_tx.v           \# UART transmitter for game logs
 └── battleship_top.v    \# Top-level Battleship FPGA module

sim/
 └── tb_decoder.v        \# Verilog testbench for decoder modulea
\```

---

\## How It Works

\### Decoder Module

- \*\*Inputs\*\*
  - \`clk\`: System clock (100 MHz)
  - \`row[3:0]\`: Keypad row lines (active-low)
- \*\*Outputs\*\*
  - \`col[3:0]\`: Column drive lines (active-low, scanned one at a time)
  - \`dec_out[3:0]\`: Binary code representing the pressed key

The decoder cycles through all 4 columns using a \`col_select\` counter and sets \`col\` accordingly.\
If a row is active (\`0\`) when \`scan_timer == LAG\`, it updates \`dec_out\` with the appropriate value.

---

\### Testbench

The testbench:

1. Generates a 100 MHz clock.
2. Uses the \`press_key\` task to simulate key presses by driving \`row\` low.
3. Waits long enough for the scan cycle to register the press.
4. Prints a log message showing:
   - Player ID (\`P1\`)
   - Row and column indices
   - The decoded value (\`dec_out\`)

---

\## Simulation

\### Using Vivado

1. Open Vivado and create a project with \`decoder.v\` and \`tb_decoder.v\`.
2. Set \`tb_decoder\` as the top simulation source.
3. Run simulation and view:
   - \*\*Waveform\*\* to see \`col\`, \`row\`, and \`dec_out\` transitions.
   - \*\*Console\*\* for formatted \`P1(row:col)\` messages.

---

\## Example Console Output

\```
Starting decoder test...
[100000 ns] P1(0:0) → dec_out = 0
[200000 ns] P1(1:0) → dec_out = 4
[300000 ns] P1(2:1) → dec_out = 5
[400000 ns] P1(3:3) → dec_out = D
[Testbench] Finished all test presses.
\```

---

\## Next Steps

- Integrate \`decoder\` with the Battleship FPGA top-level.
- Use keypad inputs for shot coordinates.
- Expand the testbench to automatically verify expected outputs.
