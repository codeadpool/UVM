# SRAM UVC Project

## Project Overview

The SRAM UVC (Universal Verification Component) project provides a comprehensive verification environment to test and validate the functionality of a custom SRAM (Static Random Access Memory) with timing models. Leveraging the UVM (Universal Verification Methodology) framework, this project aims to deliver a standardized and reusable environment for SRAM verification.

The project encompasses:
- A custom interface
- UVM agents
- A UVM environment for simulating and verifying the SRAM model’s behavior
- A testbench to integrate the UVC with the DUT (Device Under Test)

## Verification Summary

- **DUT**: parameterized single-port SRAM behavioral model (`dut/sram_behavioral_model.sv`),
  8192 x 32 (32KB), SECDED ECC, runtime-configurable read latency, and `specify`-block
  timing delays taken from the 7nm 0.7V/25°C corner of `docs/asap7_srambank_excerpt.lib`
  (setup ~48ps, hold ~6.4ps, clk→dataout ~134ps). This enables timing-aware RTL
  simulation before a gate-level netlist is available.
- **Stimulus**: constrained-random plus directed sequences for RAW hazards, ECC
  single-bit correction and double-bit detection across codeword positions, and
  read-latency sweeps.
- **Coverage**: a covergroup over op, address regions, data patterns, RAW-hazard gaps,
  ECC paths (clean / single-bit-corrected / double-bit-detected), and read latency
  (1-4), with the key crosses. The directed + random sequences close the model to
  100%. Overall and per-point numbers print in `report_phase`.  See `docs/coverage_plan.md`.

## File Structure
```
docs/
  coverage_plan.md            coverage model + timing notes
  asap7_srambank_excerpt.lib  ASAP7 7nm Liberty characterization
  openram-sram-uarch.png      microarchitecture diagram
dut/
  sram_ecc_pkg.sv             SECDED (39,32) encode/decode
  sram_behavioral_model.sv    single-port 32KB model, ECC, latency, timing
  sram_cell_6t.sv             6T cell (physical reference)
  sram_cpp_model.cpp          C++ reference model
tb/
  sram_if.sv                  SRAM interface + BFM tasks
  tb_top.sv                   top module, clock/reset, DUT + UVC
sv/
  agents/                     packet, config, driver, monitor, agent
  pkg/                        agent / seqs / env / tests packages
  top/                        coverage, scoreboard, env
tests/
  seq_lib/sram_seq_lib.svh    pattern, RAW, ECC, latency, random seqs
  src/sram_test_lib.svh       base + regression + focused tests
sim/
  filelist.f                  compile order
  Makefile                    VCS build/run
```
