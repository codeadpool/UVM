`ifndef SRAM_MONITOR_SVH
`define SRAM_MONITOR_SVH

class sram_monitor extends uvm_monitor;
  `uvm_component_utils(sram_monitor)

  virtual sram_if base_vif;
  virtual sram_if.MONITOR vif;
  sram_agent_cfg cfg;

  uvm_analysis_port #(sram_packet) mon_ap;

  function new(string name, uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual sram_if)::get(this, "", "vif", base_vif))
      `uvm_fatal(get_type_name(), "no virtual interface")
    vif = base_vif.MONITOR;
    if (!uvm_config_db#(sram_agent_cfg)::get(this, "", "agent_cfg", cfg))
      `uvm_fatal(get_type_name(), "no agent config")
    mon_ap = new("mon_ap", this);
  endfunction

  task run_phase(uvm_phase phase);
    collect_transactions();
  endtask

  task collect_transactions();
    sram_packet trans;
    forever begin
      @(vif.monitor_cb iff vif.rstn === 1'b1 && vif.monitor_cb.ce_n === 1'b0);

      trans              = sram_packet::type_id::create("trans");
      trans.addr         = vif.monitor_cb.addr;
      trans.read_latency = vif.monitor_cb.read_latency;
      trans.op           = (vif.monitor_cb.we_n === 1'b0) ? trans.WRITE : trans.READ;

      if (trans.op == trans.WRITE) begin
        trans.din  = vif.monitor_cb.din;
        trans.we_n = 1'b0;
      end else begin
        trans.we_n = 1'b1;
        // wait out the pipeline then sample the response
        repeat (trans.read_latency) @(vif.monitor_cb);
        trans.dout       = vif.monitor_cb.dout;
        trans.ecc_single = vif.monitor_cb.ecc_single;
        trans.ecc_double = vif.monitor_cb.ecc_double;
      end

      trans.trans_time = $time;
      mon_ap.write(trans);
    end
  endtask
endclass : sram_monitor

`endif
