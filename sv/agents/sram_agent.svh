`ifndef SRAM_AGENT_SV
`define SRAM_AGENT_SV

class sram_agent extends uvm_agent;
  `uvm_component_utils(sram_agent)

  virtual sram_if              vif;
  sram_agent_cfg               m_cfg;

  sram_monitor                 m_mon;
  sram_driver                  m_drv;
  uvm_sequencer #(sram_packet) m_seqr;

  function new(string name = "sram_agent", uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(sram_agent_cfg)::get(this, "", "agent_cfg", m_cfg))
      m_cfg = sram_agent_cfg::type_id::create("m_cfg");

    if (!uvm_config_db#(virtual sram_if)::get(this, "", "vif", vif))
      `uvm_fatal(get_type_name(), "Couldn't retrieve virtual interface")


    m_mon = sram_monitor::type_id::create("m_mon", this);
    uvm_config_db#(virtual sram_if)::set(this, "m_mon", "vif", vif);

    if (m_cfg.is_active == UVM_ACTIVE) begin
      m_seqr = uvm_sequencer#(sram_packet)::type_id::create("m_seqr", this);
      m_drv  = sram_driver::type_id::create("m_drv", this);

      uvm_config_db#(virtual sram_if)::set(this, "m_drv", "vif", vif);
      uvm_config_db#(sram_agent_cfg)::set(this, "m_drv", "agent_cfg", m_cfg);
      uvm_config_db#(sram_agent_cfg)::set(this, "m_mon", "agent_cfg", m_cfg);
    end
  endfunction : build_phase

  virtual function void connect_phase(uvm_phase phase);
    if (m_cfg.is_active == UVM_ACTIVE) m_drv.seq_item_port.connect(m_seqr.seq_item_export);
  endfunction : connect_phase
endclass

`endif
