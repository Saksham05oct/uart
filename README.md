# UART Verification using SystemVerilog

A complete UART (Universal Asynchronous Receiver-Transmitter) design and class-based verification environment written in SystemVerilog. The project was simulated on **EDA Playground** using **Synopsys VCS** and verified with **500 randomized transactions**, all of which passed with data matched.

---

## What the Code Does

### Design (`uart_design.sv`)

The design implements a full UART communication module with three components:

- **`uart_if`** — A SystemVerilog interface that bundles all signals (clock, reset, serial I/O, parallel data, done flags, and baud clocks) into a single reusable port, keeping the DUT and testbench connections clean.

- **`uart_tx`** — The transmitter module. It generates its own baud-rate clock from the system clock using a counter-based divider. When `tx_start` is asserted, it latches the 8-bit input data, sends a start bit (logic 0), shifts out all 8 data bits LSB-first on `tx_serial_out`, then sends a stop bit (logic 1) and asserts `tx_done`. A simple two-state FSM (`TX_IDLE` → `TX_SHIFT_DATA`) controls the entire flow.

- **`uart_rx`** — The receiver module. It also generates its own baud-rate clock. It waits in `RX_IDLE` until it detects a start bit (logic 0) on `rx_serial_in`, then transitions to `RX_CAPTURE_DATA` where it samples 8 incoming bits into a shift register. After capturing all 8 bits, it asserts `rx_done` and presents the reconstructed byte on `rx_parallel_data`.

- **`uart_top`** — A top-level wrapper that instantiates `uart_tx` and `uart_rx` with parameterized clock frequency and baud rate, exposing a unified port list.

Both TX and RX use parameterized `CLOCK_FREQUENCY_HZ` and `BAUD_RATE` values. For simulation, these are set to 19200 Hz and 9600 baud respectively (clocks-per-baud = 2) to keep simulation time manageable.

### Testbench (`uart_testbench.sv`)

The testbench uses a **class-based layered verification architecture** inspired by UVM methodology:

- **`uart_transaction`** — A transaction class with `randc` operation type (WRITE or READ) and `rand` payload. Includes a `copy()` method for passing transactions through mailboxes without aliasing.

- **`uart_generator`** — Creates randomized transactions and sends them to the driver via a mailbox. Uses event-based handshaking to wait for both the driver and scoreboard to finish before generating the next transaction. Configurable `transaction_count` (set to 500).

- **`uart_driver`** — Drives stimulus onto the DUT through the virtual interface. For TX operations, it asserts `tx_start` with the payload and waits for `tx_done`. For RX operations, it drives random serial bit patterns on `rx_serial_in` and waits for `rx_done`. Performs a reset sequence at the start using the system clock (since baud clocks are frozen during reset).

- **`uart_monitor`** — Passively observes DUT outputs. For TX, it watches `tx_serial_out` and reconstructs the transmitted byte bit-by-bit. For RX, it waits for `rx_done` and reads `rx_parallel_data`. Sends observed payloads to the scoreboard via mailbox.

- **`uart_scoreboard`** — Compares expected data (from driver) against observed data (from monitor). Prints `DATA MATCHED` or `DATA MISMATCHED` for each transaction, both to the console and to a log file.

- **`uart_environment`** — Wires together all components (generator, driver, monitor, scoreboard) with mailboxes and event handles. Orchestrates the simulation in three phases: `pre_test` (reset), `test` (fork all tasks), and `post_test` (wait for completion).

- **Top module (`tb`)** — Instantiates the DUT and interface, generates the 50 MHz clock (20 ns period), opens `output.log` for file-based logging, sets a 100 ms safety timeout, and kicks off the environment.

### Output Log (`output_log.txt`)

Contains the complete simulation transcript — 500 transactions showing generator, driver, monitor, and scoreboard activity with timestamps. Every single transaction shows `DATA MATCHED`, confirming full functional correctness of both TX and RX paths.

---

## Tool Used

| Component | Tool |
|---|---|
| **Simulation Platform** | [EDA Playground](https://www.edaplayground.com/) |
| **Simulator** | Synopsys VCS (SystemVerilog) |
| **Language** | SystemVerilog (IEEE 1800) |
| **Waveform Dump** | VCD format (`dump.vcd`) |

EDA Playground was chosen because it provides free access to industry-standard simulators like Synopsys VCS directly in the browser — no local installation or license required.

---

## What Was Achieved

- **Full UART RTL** — Parameterized transmitter and receiver with baud-rate generation, start/stop bit framing, and FSM-based control.
- **Class-based verification environment** — Modular testbench with separate generator, driver, monitor, and scoreboard, communicating via SystemVerilog mailboxes and events.
- **500 randomized transactions** — A mix of TX (write) and RX (read) operations with random 8-bit payloads, all completing with `DATA MATCHED`.
- **100% pass rate** — Zero data mismatches across the entire simulation run.
- **File-based logging** — All verification activity is captured in `output_log.txt` with simulation timestamps for post-run analysis.
- **Simulation-friendly tuning** — Clock-to-baud ratio reduced to 2 (19200 Hz / 9600 baud) to avoid EDA Playground timeouts while keeping the design functionally equivalent.


