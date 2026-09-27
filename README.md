# FPGA Lunar Lander Minigame

A SystemVerilog implementation of a Lunar Lander minigame targeting an FPGA dev board. The game runs a real-time physics loop entirely in **Binary-Coded Decimal (BCD)** arithmetic — no binary-to-decimal conversion anywhere in the datapath — and streams live telemetry to a bank of 7-segment displays.

## Gameplay & Controls

The objective is to manage limited fuel and thrust to set a spacecraft down on the lunar surface without crashing.

- **Thrust Control:** Pressing a numeric key (0–9) latches that value as the active thrust level, which counteracts a constant gravity of `16'h5` applied every game tick.
- **Display Toggles:** Four dedicated keys cycle the 7-segment readout between Altitude (`ALT`), Velocity (`VEL`), Fuel (`GAS`), and Thrust (`THR`). The selected mode persists until another toggle is pressed.
- **Win / Loss Conditions:** The game resolves when altitude reaches `0`. A descent velocity faster than the safe threshold (`16'h9970` in 10's-complement BCD, i.e. −30) crashes the ship and lights the red LED; anything within limits is a successful landing and lights green.
- **Game Over State:** On landing or crash, the write-enable (`wen`) into the state registers is deasserted, freezing altitude, velocity, and fuel at their final values so the result stays on screen.
- **Fuel Exhaustion:** Once the fuel reserve hits zero the applied thrust is forced to `0` regardless of key input, leaving the ship in free fall.

## Hardware Interfaces

- **Inputs:** A 100 Hz clock (`hz100`), an asynchronous `reset`, and a 20-bit pushbutton/keypad array (`pb` at the top level, `in` inside the game).
- **Outputs:** Eight 7-segment displays (`ss0`–`ss7`) for numeric telemetry and three-letter status labels, plus discrete red and green LEDs for end-game status.

## System Architecture

The design is split into a synchronization layer, a state/physics core, a BCD arithmetic library, and a display controller.

| File | Contents |
| --- | --- |
| `top.sv` | Board-level wrapper. Maps `pb[19:0]`, `hz100`, `reset`, the 7-segment bus, and the status LEDs into the game, and carries the supporting combinational library (`keysync`, `clock_psc`, `ssdec`, `fa`/`fa4`, and the BCD adder chain). |
| `lunarlander.sv` | Integrated game top level — instantiates the clock prescaler, key synchronizer, ALU, control FSM, memory, and display, and contains self-contained copies of every submodule so the file elaborates standalone. |
| `ll_memory.sv` | Sequential state storage. |
| `ll_alu.sv` | Physics / next-state computation. |
| `ll_control.sv` | Landing-detection state machine. |
| `ll_display.sv` | 7-segment multiplexing and formatting. |
| `bcd_arithmetic.sv` | Standalone BCD adder/subtractor library. |

### Top-Level & Synchronization

`clock_psc` divides the 100 Hz input down to the game tick using a programmable limit (`lim = 24`, giving a ~2 Hz physics update), while `keysync` collapses the 20-bit button array into a 5-bit encoded key value and generates a clean, debounced `keyclk` strobe through a two-stage flip-flop synchronizer. Keys with the high bit clear are decoded as thrust values; keys with the high bit set are decoded into the one-hot display-select signal `disp_ctrl`.

### Memory & State (`ll_memory.sv`)

A register bank holding the current BCD altitude, velocity, fuel, and thrust. Reset loads the starting parameters — altitude `16'h4500`, fuel `16'h800`, thrust `16'h5`, velocity `16'h0` — and updates are gated by the control module's `wen` signal.

### Game Physics (`ll_alu.sv`)

Computes the next state each tick: gravity is subtracted from velocity, the active thrust is added back, the resulting velocity is accumulated into altitude, and the thrust cost is deducted from the fuel reserve. Bounding logic clamps altitude and fuel at zero so neither can roll over into a negative (9-leading) BCD value, and thrust is zeroed once fuel is depleted.

### Landing Control (`ll_control.sv`)

Looks one step ahead by summing altitude and velocity to detect ground contact before it happens, then classifies the outcome as a landing or a crash based on the descent rate. The result is latched, so once `land` or `crash` asserts the module holds that state and drops `wen`.

### BCD Arithmetic Pipeline (`bcd_arithmetic.sv`)

Rather than binary math, the physics engine is built on a hierarchy of hand-built adders: full adders (`fa`) into a 4-bit ripple-carry adder (`fa4`), into a single-digit BCD adder with +6 decimal correction (`bcdadd1`), into a 4-digit adder (`bcdadd4`), and finally a 16-bit adder/subtractor (`bcdaddsub4`) that performs subtraction via 9's-complement generation (`bcd9comp1`) plus an injected carry-in. Negative quantities are represented in 10's-complement BCD, which is why velocity comparisons key off the leading `9` nibble.

### Display Controller (`ll_display.sv`)

Selects the displayed quantity from the latched view mode, and if the value is negative, runs it back through the BCD subtractor to recover its magnitude before decoding. `ssdec` converts each BCD nibble to a 7-segment pattern, leading digits are blanked for readability, a minus sign is rendered on the high digit for negative velocity, and the upper three displays spell out the active label (`ALT`, `VEL`, `GAS`, `THR`) using hand-encoded segment patterns.

## Notes

The per-module files are the standalone versions of each block; `lunarlander.sv` bundles them together as a single elaborable design. Compile either `lunarlander.sv` on its own or the collection of individual modules — not both at once, since the module names overlap.
