`ifndef SRAM_ENV_SVH
`define SRAM_ENV_SVH

class sram_env extends uvm_env;

  sram_agent      agent;
  sram_coverage   cov;
  sram_scoreboard scb;
  sram_agent_cfg  agent_cfg;

  `uvm_component_utils(sram_env)

  function new(string name = "sram_env", uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(sram_agent_cfg)::get(this, "", "agent_cfg", agent_cfg))
      agent_cfg = sram_agent_cfg::type_id::create("agent_cfg");

    agent = sram_agent::type_id::create("agent", this);
    cov   = sram_coverage#(sram_packet)::type_id::create("cov", this);
    scb   = sram_scoreboard::type_id::create("scb", this);

    uvm_config_db#(sram_agent_cfg)::set(this, "scb", "agent_cfg", agent_cfg);
  endfunction : build_phase

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    agent.m_drv.drv_ap.connect(scb.drv_imp);
    agent.m_mon.mon_ap.connect(scb.mon_imp);
    // coverage samples the driver side so it sees the seq annotations
    agent.m_drv.drv_ap.connect(cov.analysis_export);
  endfunction : connect_phase
endclass

`endif
