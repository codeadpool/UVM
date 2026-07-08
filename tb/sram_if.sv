`ifndef SRAM_INTERFACE_SVH
`define SRAM_INTERFACE_SVH

interface sram_if #(
    parameter int ADDR_WIDTH = 13,
    parameter int DATA_WIDTH = 32,
    parameter int ECC_CW     = 39
) (
    input logic clk,
    input logic rstn
);

  // to dut
  logic [ADDR_WIDTH-1:0] addr;
  logic [DATA_WIDTH-1:0] din;
  logic                  we_n;
  logic                  ce_n;
  logic [           2:0] read_latency;

  // fault injection
  logic                  inj_en;
  logic [ADDR_WIDTH-1:0] inj_addr;
  logic [    ECC_CW-1:0] inj_mask;

  // from dut
  logic [DATA_WIDTH-1:0] dout;
  logic                  rvalid;
  logic                  ecc_single;
  logic                  ecc_double;

  clocking driver_cb @(posedge clk);
    default input #1step output #2ns;
    output addr, din, we_n, ce_n, read_latency, inj_en, inj_addr, inj_mask;
    input dout, rvalid, ecc_single, ecc_double;
  endclocking

  clocking monitor_cb @(posedge clk);
    input addr, din, we_n, ce_n, read_latency;
    input dout, rvalid, ecc_single, ecc_double;
  endclocking

  modport DRIVER(clocking driver_cb,
      input clk,
      input rstn,
      import drive_reset_task, drive_write_task, drive_read_task, inject_fault
  );

  modport MONITOR(clocking monitor_cb, input clk, input rstn);

  task automatic drive_reset_task();
    wait (rstn == 1'b0);
    addr         <= '0;
    din          <= '0;
    we_n         <= 1'b1;
    ce_n         <= 1'b1;
    read_latency <= 3'd2;
    inj_en       <= 1'b0;
    inj_mask     <= '0;
    wait (rstn == 1'b1);
    @(driver_cb);
  endtask

  task automatic drive_write_task(input logic [ADDR_WIDTH-1:0] address,
                                  input logic [DATA_WIDTH-1:0] data);
    driver_cb.ce_n <= 1'b0;
    driver_cb.we_n <= 1'b0;
    driver_cb.addr <= address;
    driver_cb.din  <= data;
    @(driver_cb);
    driver_cb.we_n <= 1'b1;
    driver_cb.ce_n <= 1'b1;
  endtask

  task automatic drive_read_task(input logic [ADDR_WIDTH-1:0] address, input logic [2:0] latency,
                                 output logic [DATA_WIDTH-1:0] data, output logic se,
                                 output logic de);
    driver_cb.ce_n         <= 1'b0;
    driver_cb.we_n         <= 1'b1;
    driver_cb.addr         <= address;
    driver_cb.read_latency <= latency;
    @(driver_cb);
    driver_cb.ce_n <= 1'b1;
    // sample when the pipeline flags the response valid, self aligns to latency
    repeat (latency + 2) begin
      @(driver_cb);
      if (driver_cb.rvalid === 1'b1) break;
    end
    data = driver_cb.dout;
    se   = driver_cb.ecc_single;
    de   = driver_cb.ecc_double;
  endtask

  // corrupt a stored codeword so the next read exercises ecc
  task automatic inject_fault(input logic [ADDR_WIDTH-1:0] address, input logic [ECC_CW-1:0] mask);
    driver_cb.inj_addr <= address;
    driver_cb.inj_mask <= mask;
    driver_cb.inj_en   <= 1'b1;
    @(driver_cb);
    driver_cb.inj_en <= 1'b0;
  endtask

endinterface

`endif
