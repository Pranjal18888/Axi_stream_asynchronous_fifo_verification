# Axi_stream_asynchronous_fifo_verification

AXI4-Stream Verification Project
This project implements and verifies an asynchronous FIFO (dual clock domain, CDC-safe, with Gray-code synchronizers) for the AXI4-Stream protocol. 

Verification was first done using a plain SystemVerilog testbench (driver, monitor, scoreboard, and coverage all written manually using tasks/classes), and the same environment was then migrated to the industry-standard UVM (Universal Verification Methodology), where the sequence, driver, monitor, agent, scoreboard, functional coverage, and SVA assertions were organized into a proper UVM class hierarchy. 

The verification includes constrained-random stimulus (packet-based, with TLAST), random backpressure testing, in-order data-integrity scoreboarding, and functional coverage (data range, TLAST hits, wait-state scenarios), ensuring the design is thoroughly tested under real-world-like conditions.
