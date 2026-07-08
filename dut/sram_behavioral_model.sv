`ifndef SRAM_BEHAVIORAL_MODEL_SV
`define SRAM_BEHAVIORAL_MODEL_SV

`timescale 1ns / 1ps

// single port 32kB sram behavioral model
// 8192 x 32 with secded ecc, runtime read latency and liberty derived delays
// timing nominals taken from srambank_128x256_6t.lib pvt 0.7v 25c
module sram_behavioral_model
  import sram_ecc_pkg::*;
#(
    parameter int  DATA_WIDTH  = 32,
    parameter int  ADDR_WIDTH  = 13,     // 8192 words
    parameter int  MAX_LATENCY = 4,
    // liberty nominal corner, ns
    parameter real TSETUP      = 0.048,
    parameter real THOLD       = 0.006,
    parameter real TCK2Q       = 0.134,
    parameter real TMPW        = 0.004
) (
    input logic                  clk,
    input logic                  rstn,
    input logic                  ce_n,         // chip enable, active low
    input logic                  we_n,         // write enable, active low
    input logic [ADDR_WIDTH-1:0] addr,
    input logic [DATA_WIDTH-1:0] din,
    input logic [           2:0] read_latency, // 1..MAX_LATENCY

    // fault injection, flips bits in a stored codeword
    input logic                  inj_en,
    input logic [ADDR_WIDTH-1:0] inj_addr,
    input logic [    ECC_CW-1:0] inj_mask,

    output logic [DATA_WIDTH-1:0] dout,
    output logic                  rvalid,
    output logic                  ecc_single,
    output logic                  ecc_double
);

  localparam int DEPTH = 2 ** ADDR_WIDTH;

  // storage holds the full 39 bit codeword per word
  logic [    ECC_CW-1:0] mem      [    0:DEPTH-1];

  // read pipeline, one slot per latency stage
  logic [DATA_WIDTH-1:0] pipe_data[1:MAX_LATENCY];
  logic                  pipe_vld [1:MAX_LATENCY];
  logic                  pipe_se  [1:MAX_LATENCY];
  logic                  pipe_de  [1:MAX_LATENCY];

  logic [DATA_WIDTH-1:0] rd_data;
  logic rd_se, rd_de;

  always_comb begin
    logic [ECC_CW-1:0] cw;
    cw = mem[addr];
    ecc_decode(cw[DATA_WIDTH-1:0], cw[ECC_CW-1:DATA_WIDTH], rd_data, rd_se, rd_de);
  end

  // write path plus backdoor fault injection, one process owns mem
  // preload clean on reset, codeword for data 0 is all zero so unwritten reads decode clean
  always_ff @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      for (int i = 0; i < DEPTH; i++) mem[i] <= '0;
    end else begin
      if (!ce_n && !we_n) mem[addr] <= {ecc_encode(din), din};
      if (inj_en) mem[inj_addr] <= mem[inj_addr] ^ inj_mask;
    end
  end

  // shift the read result through the pipeline every enabled cycle
  always_ff @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      for (int s = 1; s <= MAX_LATENCY; s++) begin
        pipe_vld[s]  <= 1'b0;
        pipe_data[s] <= '0;
        pipe_se[s]   <= 1'b0;
        pipe_de[s]   <= 1'b0;
      end
    end else begin
      pipe_data[1] <= rd_data;
      pipe_vld[1]  <= (!ce_n && we_n);
      pipe_se[1]   <= rd_se && (!ce_n && we_n);
      pipe_de[1]   <= rd_de && (!ce_n && we_n);
      for (int s = 2; s <= MAX_LATENCY; s++) begin
        pipe_data[s] <= pipe_data[s-1];
        pipe_vld[s]  <= pipe_vld[s-1];
        pipe_se[s]   <= pipe_se[s-1];
        pipe_de[s]   <= pipe_de[s-1];
      end
    end
  end

  logic [2:0] lat;
  assign lat = (read_latency < 1) ? 3'd1 :
               (read_latency > MAX_LATENCY) ? MAX_LATENCY[2:0] : read_latency;

  assign #(TCK2Q) dout = pipe_data[lat];
  assign #(TCK2Q) rvalid = pipe_vld[lat];
  assign #(TCK2Q) ecc_single = pipe_se[lat];
  assign #(TCK2Q) ecc_double = pipe_de[lat];

  specify
    specparam tSU = 0.048;
    specparam tHD = 0.006;
    specparam tPW = 0.004;
    $setup(addr, posedge clk, tSU);
    $hold(posedge clk, addr, tHD);
    $setup(din, posedge clk, tSU);
    $hold(posedge clk, din, tHD);
    $setup(we_n, posedge clk, tSU);
    $hold(posedge clk, we_n, tHD);
    $width(posedge clk, tPW);
  endspecify

endmodule

`endif
