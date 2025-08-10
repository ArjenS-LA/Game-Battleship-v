# Battleship FPGA — Keypad Decoder Testbench

## Overview

This project is part of the **Battleship FPGA** game implementation.
It contains the **`decoder`** module, which scans a 4×4 keypad, determines which key is pressed, and outputs its corresponding 4-bit binary code which is translated
into the 16-LEDs on the Basys 3 Board.

Example output:

```
[500000 ns] P1(1:0) → dec_out = 7
[1200000 ns] P1(2:0) → dec_out = 4
[1900000 ns] P1(3:0) → dec_out = 1
```

---

## File Structure

```
src/
 ├── decoder.v           # Keypad scanning and decoding logic
 ├── clock_dividers.v    # Clock divider for timing control
 ├── display.v           # Seven-segment display driver
 ├── scoreboard.v        # Game scoreboard logic
 ├── uart_tx.v           # UART transmitter for game logs
 |── battleship_top.v    # Top-level Battleship FPGA module
 └── keyFromSwitches.v   # Translates decoder into key for top modules

constrs/
 └── constraints.xdc        # Constraint file
```

---

## How It Works

### Decoder Module

- **Inputs**
  - `clk`: System clock (100 MHz)
  - `row[3:0]`: Keypad row lines (active-low)
- **Outputs**
  - `col[3:0]`: Column drive lines (active-low, scanned one at a time)
  - `dec_out[3:0]`: Binary code representing the pressed key

The decoder cycles through all 4 columns using a `col_select` counter and sets `col` accordingly.
If a row is active (`0`) when `scan_timer == LAG`, it updates `dec_out` with the appropriate value.

---

---

## Next Steps

- Integrate `decoder` with the Battleship FPGA top-level.
- Use keypad inputs for shot coordinates.
- Expand the testbench to automatically verify expected outputs.
