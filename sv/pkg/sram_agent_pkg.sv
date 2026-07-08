package sram_agent_pkg;

  parameter int ADDR_WIDTH = 13;  // 8192 words
  parameter int DATA_WIDTH = 32;
  parameter int ECC_CW = 39;

  import uvm_pkg::*;
  import sram_ecc_pkg::*;
  `include "uvm_macros.svh"

  `include "sram_packet.svh"
  `include "sram_agent_cfg.svh"
  `include "sram_driver.svh"
  `include "sram_monitor.svh"
  `include "sram_agent.svh"
endpackage
