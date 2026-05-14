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

---

## Limitations

1. **No parity bit support** — The UART frame is fixed at 8N1 (8 data bits, no parity, 1 stop bit). There is no option to enable even/odd parity.
2. **No configurable stop bits** — Only a single stop bit is generated; 1.5 or 2 stop-bit configurations are not supported.
3. **No framing or overrun error detection** — The receiver does not check for valid stop bits or flag errors if data arrives before the previous byte is read.
4. **No oversampling** — The receiver samples each bit once per baud period. Real UART receivers typically use 16× oversampling and sample near the center of each bit for noise immunity.
5. **Baud clock coupling** — The testbench synchronizes using internal baud clocks extracted from the DUT (`dut.uart_tx_inst.baud_sample_clock`), which creates a dependency on DUT internals rather than using a protocol-independent approach.
6. **Simplified baud rate for simulation** — The 19200/9600 ratio (clocks-per-baud = 2) works for functional verification but does not reflect real-world ratios (e.g., 50 MHz / 9600 = 5208 clocks per baud).
7. **No functional coverage** — The testbench checks correctness but does not collect SystemVerilog covergroups or cover properties to measure verification completeness.
8. **No assertions** — There are no SVA (SystemVerilog Assertions) for protocol-level checks like start-bit timing, stop-bit validation, or idle-line behavior.

---

## How This Can Be Improved

1. **Add parity and configurable stop bits** — Make the frame format parameterizable (data bits, parity mode, stop bits) in both RTL and testbench.
2. **Implement 16× oversampling in the receiver** — Sample the input at 16× the baud rate and use a majority-vote or center-sample strategy for robust bit detection.
3. **Add framing and overrun error flags** — Detect invalid stop bits and flag when new data arrives before the previous byte is consumed.
4. **Decouple testbench from DUT internals** — Replace the internal baud clock extraction with a protocol-independent monitor that detects start bits and samples at the correct rate on its own.
5. **Add SVA assertions** — Write protocol-level assertions for start-bit timing, bit duration, stop-bit presence, idle-line behavior, and back-to-back frame spacing.
6. **Add functional coverage** — Create covergroups for payload values (corner cases like 0x00, 0xFF, alternating patterns), operation sequences (consecutive reads, consecutive writes, alternating), and edge conditions.
7. **Integrate with UVM** — Migrate the class-based environment to a full UVM testbench with sequences, sequencer, agents, and a register model for better scalability and reuse.
8. **Test at realistic clock ratios** — Verify with real-world clock-to-baud ratios (e.g., 50 MHz / 115200) on a local simulator to catch timing-related bugs that the simplified ratio might miss.
9. **Add FIFO buffering** — Implement TX and RX FIFOs so the UART can queue multiple bytes and support burst communication.
10. **Loopback testing** — Connect `tx_serial_out` to `rx_serial_in` internally to verify end-to-end UART data integrity in a single self-checking test.
