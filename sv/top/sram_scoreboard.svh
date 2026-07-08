`ifndef SRAM_SCOREBOARD_SVH
`define SRAM_SCOREBOARD_SVH

`uvm_analysis_imp_decl(_drv)
`uvm_analysis_imp_decl(_mon)

class sram_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(sram_scoreboard)

  uvm_analysis_imp_drv #(sram_packet, sram_scoreboard) drv_imp;
  uvm_analysis_imp_mon #(sram_packet, sram_scoreboard) mon_imp;

  sram_agent_cfg cfg;

  logic [DATA_WIDTH-1:0] shadow_mem[logic [ADDR_WIDTH-1:0]];

  int unsigned total_writes = 0;
  int unsigned total_reads = 0;
  int unsigned mismatches = 0;
  int unsigned ecc_corrected = 0;
  int unsigned ecc_detected = 0;
  int txn_id = 0;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    drv_imp = new("drv_imp", this);
    mon_imp = new("mon_imp", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(sram_agent_cfg)::get(this, "", "agent_cfg", cfg))
      `uvm_fatal("CFG", "no agent config")
  endfunction

  // driver stream is in order and carries the dut response the driver captured,
  // so predict and check here, no cross stream races
  virtual function void write_drv(sram_packet pkt);
    txn_id++;
    if (pkt.op == sram_packet::WRITE) begin
      shadow_mem[pkt.addr] = pkt.din;
      total_writes++;
      return;
    end

    begin
      logic [DATA_WIDTH-1:0] base, corrected;
      logic [ECC_CW-1:0] cw;
      logic se, de;

      base = shadow_mem.exists(pkt.addr) ? shadow_mem[pkt.addr] : '0;
      // rebuild the stored codeword, apply the same fault the driver injected
      cw   = ({sram_ecc_pkg::ecc_encode(base), base}) ^ pkt.err_mask;
      sram_ecc_pkg::ecc_decode(cw[DATA_WIDTH-1:0], cw[ECC_CW-1:DATA_WIDTH], corrected, se, de);
      total_reads++;
      if (se) ecc_corrected++;
      if (de) ecc_detected++;

      if (!de && pkt.dout !== corrected) begin
        mismatches++;
        `uvm_error("SB", $sformatf("read[%0d] data mismatch addr 0x%0h exp 0x%0h act 0x%0h",
                                   txn_id, pkt.addr, corrected, pkt.dout))
      end
      if (pkt.ecc_single !== se || pkt.ecc_double !== de) begin
        mismatches++;
        `uvm_error("SB", $sformatf("read[%0d] ecc flag mismatch exp se%0b de%0b act se%0b de%0b",
                                   txn_id, se, de, pkt.ecc_single, pkt.ecc_double))
      end
    end
  endfunction

  // passive protocol check on the monitored bus
  virtual function void write_mon(sram_packet pkt);
    if ($isunknown(pkt.we_n)) begin
      mismatches++;
      `uvm_error("SB", "x on we_n observed")
    end
  endfunction

  function void report_phase(uvm_phase phase);
    string r;
    r = $sformatf(
        {
          "\nsram scoreboard report",
          "\n  writes %0d reads %0d",
          "\n  ecc single bit corrections %0d",
          "\n  ecc double bit detections %0d",
          "\n  mismatches %0d\n"
        },
        total_writes,
        total_reads,
        ecc_corrected,
        ecc_detected,
        mismatches
    );
    if (mismatches > 0) `uvm_error("SB", "failures detected")
    else `uvm_info("SB", "all reads verified", UVM_LOW)
    `uvm_info("SB", r, UVM_LOW)
  endfunction
endclass : sram_scoreboard

`endif
