# UART Verification Project

This repository contains a simple UART design and a SystemVerilog testbench built to verify basic transmit and receive behavior.

The project was originally written in a compact style and then reorganized into separate RTL and testbench files with clearer signal names so the code is easier to read and maintain.

## Project Structure

```text
uart/
├── rtl/
│   ├── uart_top.sv
│   ├── uart_tx.sv
│   └── uart_rx.sv
├── tb/
│   ├── uart_if.sv
│   ├── uart_transaction.sv
│   ├── uart_generator.sv
│   ├── uart_driver.sv
│   ├── uart_monitor.sv
│   ├── uart_scoreboard.sv
│   ├── uart_environment.sv
│   └── uart_tb.sv
└── README.md
```

## Design Overview

The RTL contains three modules:

- `uart_top`: top-level wrapper that instantiates the transmitter and receiver
- `uart_tx`: UART transmitter
- `uart_rx`: UART receiver

### `uart_tx`

The transmitter:

- accepts an 8-bit parallel input byte
- begins transmission when `tx_start` is asserted
- generates a start bit
- shifts out 8 data bits
- raises `tx_done` when transmission completes

### `uart_rx`

The receiver:

- watches the serial input line `rx_serial_in`
- detects the start of a frame
- samples 8 bits
- reconstructs the received byte on `rx_parallel_data`
- raises `rx_done` when reception completes

## Testbench Overview

The testbench is class-based and uses a small verification environment.

### Main TB Components

- `uart_transaction`: describes one UART operation
- `uart_generator`: creates randomized transactions
- `uart_driver`: drives DUT inputs through the interface
- `uart_monitor`: observes DUT activity
- `uart_scoreboard`: compares expected and observed data
- `uart_environment`: connects and runs all components
- `uart_tb`: simulation top module

### Verification Flow

1. The generator creates a transaction.
2. The driver applies stimulus to the DUT.
3. The monitor observes DUT outputs.
4. The scoreboard compares expected and observed values.
5. The environment coordinates reset, execution, and end of simulation.

## Interface Signals

The shared interface `uart_if` contains:

- `clock`
- `reset`
- `rx_serial_in`
- `tx_parallel_data`
- `tx_start`
- `tx_serial_out`
- `rx_parallel_data`
- `tx_done`
- `rx_done`
- `tx_baud_clock`
- `rx_baud_clock`

The baud clock signals are exposed for testbench coordination.

## Current Scope

This project is intended as a learning and verification-oriented UART example. It demonstrates:

- modular RTL organization
- class-based SystemVerilog verification
- mailbox/event-based communication

## Known Limitations

This is a simple UART model and verification environment. Current limitations include:

- no parity support
- no configurable stop bits
- no framing error detection
- no oversampling in the receiver
- testbench uses internal DUT baud clocks for synchronization
- verification is functional and educational rather than protocol-exhaustive

## Future Improvements

Possible next steps:

- add parity and framing support
- improve RX sampling to sample near the center of each bit
- replace internal clock dependence in the TB with a more protocol-independent monitor
- add assertions and functional coverage
- add directed corner-case tests in addition to randomized traffic
