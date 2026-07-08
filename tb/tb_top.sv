`ifndef TB_TOP_SV
`define TB_TOP_SV

`timescale 1ns / 1ps

`include "uvm_macros.svh"

module tb_top;
  import uvm_pkg::*;
  import sram_tests_pkg::*;

  localparam int CLOCK_PERIOD = 10;
  localparam int ADDR_WIDTH = 13;
  localparam int DATA_WIDTH = 32;
  localparam int ECC_CW = 39;

  bit clk;
  bit rstn;

  initial begin
    clk = 0;
    forever #(CLOCK_PERIOD / 2) clk = ~clk;
  end

  initial begin
    rstn = 0;
    #(CLOCK_PERIOD * 5);
    rstn = 1;
  end

  sram_if #(
      .ADDR_WIDTH(ADDR_WIDTH),
      .DATA_WIDTH(DATA_WIDTH),
      .ECC_CW(ECC_CW)
  ) intf (
      clk,
      rstn
  );

  sram_behavioral_model #(
      .DATA_WIDTH(DATA_WIDTH),
      .ADDR_WIDTH(ADDR_WIDTH)
  ) DUT (
      .clk         (intf.clk),
      .rstn        (intf.rstn),
      .ce_n        (intf.ce_n),
      .we_n        (intf.we_n),
      .addr        (intf.addr),
      .din         (intf.din),
      .read_latency(intf.read_latency),
      .inj_en      (intf.inj_en),
      .inj_addr    (intf.inj_addr),
      .inj_mask    (intf.inj_mask),
      .dout        (intf.dout),
      .rvalid      (intf.rvalid),
      .ecc_single  (intf.ecc_single),
      .ecc_double  (intf.ecc_double)
  );

  initial begin
    uvm_config_db#(virtual sram_if)::set(null, "*", "vif", intf);
    run_test("sram_regression_test");
  end
endmodule

`endif
