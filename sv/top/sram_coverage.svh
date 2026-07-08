`ifndef SRAM_COVERAGE_SVH
`define SRAM_COVERAGE_SVH

// functional coverage for the sram controller
// op, address, data patterns, read after write hazards, ecc paths, read latency
class sram_coverage #(
    type T = sram_packet
) extends uvm_subscriber #(T);
  `uvm_component_param_utils(sram_coverage#(T))

  // sampled fields
  int                    cov_op;
  logic [ADDR_WIDTH-1:0] cov_addr;
  logic [DATA_WIDTH-1:0] cov_data;
  int                    cov_raw;
  logic [           2:0] cov_lat;
  int                    cov_ecc;  // 0 clean, 1 single corrected, 2 double detected
  int                    cov_pos;

  covergroup cg;
    option.per_instance = 1;

    cp_op: coverpoint cov_op {bins rd = {0}; bins wr = {1};}

    cp_addr: coverpoint cov_addr {
      bins a_min = {0};
      bins a_lo = {[1 : 1023]};
      bins a_b1 = {[1024 : 2047]};
      bins a_b2 = {[2048 : 3071]};
      bins a_b3 = {[3072 : 4095]};
      bins a_hi = {[4096 : 6143]};
      bins a_top = {[6144 : 8190]};
      bins a_max = {8191};
    }

    cp_data: coverpoint cov_data {
      bins d_zero = {32'h0000_0000};
      bins d_ones = {32'hFFFF_FFFF};
      bins d_aa = {32'hAAAA_AAAA};
      bins d_55 = {32'h5555_5555};
      bins d_f0 = {32'hF0F0_F0F0};
      bins d_0f = {32'h0F0F_0F0F};
      bins d_walk = {32'h0000_0001, 32'h8000_0000, 32'h0001_0000};
      bins d_misc = {[32'h1 : 32'hFFFF_FFFE]};
    }

    // read after write hazard distance in cycles
    cp_raw: coverpoint cov_raw iff (cov_raw >= 0) {
      bins g_b2b = {0};
      bins g_1 = {1};
      bins g_2 = {2};
      bins g_3 = {3};
      bins g_4 = {4};
      bins g_near = {[5 : 15]};
      bins g_far = {[16 : 1000000]};
    }

    cp_ecc: coverpoint cov_ecc {bins clean = {0}; bins single = {1}; bins double = {2};}

    // affected bit position groups over the 39 bit codeword
    cp_ecc_pos: coverpoint cov_pos iff (cov_ecc != 0) {
      bins p0 = {[0 : 4]};
      bins p1 = {[5 : 9]};
      bins p2 = {[10 : 14]};
      bins p3 = {[15 : 19]};
      bins p4 = {[20 : 24]};
      bins p5 = {[25 : 29]};
      bins p6 = {[30 : 34]};
      bins p7 = {[35 : 38]};
    }

    cp_lat: coverpoint cov_lat {bins l1 = {1}; bins l2 = {2}; bins l3 = {3}; bins l4 = {4};}

    x_op_addr: cross cp_op, cp_addr;
    x_op_data: cross cp_op, cp_data;
    x_op_lat: cross cp_op, cp_lat;
    x_raw_addr: cross cp_raw, cp_addr;
    x_raw_lat: cross cp_raw, cp_lat;
    x_addr_lat: cross cp_addr, cp_lat;
    x_ecc_lat: cross cp_ecc, cp_lat;
  endgroup

  function new(string name, uvm_component parent);
    super.new(name, parent);
    cg = new();
  endfunction

  function int onehot_pos(input logic [ECC_CW-1:0] mask);
    for (int i = 0; i < ECC_CW; i++) if (mask[i]) return i;
    return 0;
  endfunction

  virtual function void write(T t);
    cov_op   = int'(t.op);
    cov_addr = t.addr;
    cov_data = (t.op == sram_packet::WRITE) ? t.din : t.dout;
    cov_raw  = t.raw_gap;
    cov_lat  = t.read_latency;
    cov_ecc  = t.ecc_double ? 2 : (t.ecc_single ? 1 : 0);
    cov_pos  = onehot_pos(t.err_mask);
    cg.sample();
  endfunction

  function void report_phase(uvm_phase phase);
    `uvm_info("COV", $sformatf("functional coverage %.2f%%", cg.get_coverage()), UVM_LOW)
    `uvm_info("COV", $sformatf(
              {
                "per point coverage\n",
                "  cp_op %.1f  cp_addr %.1f  cp_data %.1f  cp_raw %.1f\n",
                "  cp_ecc %.1f  cp_ecc_pos %.1f  cp_lat %.1f\n",
                "  x_op_addr %.1f  x_op_data %.1f  x_op_lat %.1f\n",
                "  x_raw_addr %.1f  x_raw_lat %.1f  x_addr_lat %.1f  x_ecc_lat %.1f"
              },
              cg.cp_op.get_coverage(),
              cg.cp_addr.get_coverage(),
              cg.cp_data.get_coverage(),
              cg.cp_raw.get_coverage(),
              cg.cp_ecc.get_coverage(),
              cg.cp_ecc_pos.get_coverage(),
              cg.cp_lat.get_coverage(),
              cg.x_op_addr.get_coverage(),
              cg.x_op_data.get_coverage(),
              cg.x_op_lat.get_coverage(),
              cg.x_raw_addr.get_coverage(),
              cg.x_raw_lat.get_coverage(),
              cg.x_addr_lat.get_coverage(),
              cg.x_ecc_lat.get_coverage()
              ), UVM_LOW)
  endfunction
endclass

`endif
