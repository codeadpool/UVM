`ifndef SRAM_DRIVER_SVH
`define SRAM_DRIVER_SVH

class sram_driver extends uvm_driver #(sram_packet);
  `uvm_component_utils(sram_driver)

  virtual sram_if base_vif;
  virtual sram_if.DRIVER vif;
  sram_agent_cfg cfg;

  uvm_analysis_port #(sram_packet) drv_ap;

  function new(string name, uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual sram_if)::get(this, "", "vif", base_vif))
      `uvm_fatal(get_type_name(), "no virtual interface")
    vif = base_vif.DRIVER;
    if (!uvm_config_db#(sram_agent_cfg)::get(this, "", "agent_cfg", cfg))
      `uvm_fatal("CFG", "no agent config")
    drv_ap = new("drv_ap", this);
  endfunction

  task run_phase(uvm_phase phase);
    fork
      reset_handler();
      process_sequencer();
    join
  endtask

  task reset_handler();
    forever begin
      @(negedge vif.rstn);
      `uvm_info(get_type_name(), "reset asserted", UVM_MEDIUM)
      vif.drive_reset_task();
      @(posedge vif.rstn);
    end
  endtask

  task process_sequencer();
    wait (vif.rstn === 1'b1);
    forever begin
      seq_item_port.get_next_item(req);
      drive_transfer(req);
      drv_ap.write(req);
      seq_item_port.item_done();
    end
  endtask

  task drive_transfer(sram_packet trans);
    logic [DATA_WIDTH-1:0] rd_data;
    case (trans.op)
      trans.WRITE: begin
        vif.drive_write_task(trans.addr, trans.din);
      end
      trans.READ: begin
        logic se, de;
        // corrupt the stored word first when the sequence asked for ecc
        if (trans.err_mask != '0) vif.inject_fault(trans.addr, trans.err_mask);
        vif.drive_read_task(trans.addr, trans.read_latency, rd_data, se, de);
        trans.dout       = rd_data;
        trans.ecc_single = se;
        trans.ecc_double = de;
        // xor the same mask back so faults never accumulate across reads
        if (trans.err_mask != '0) vif.inject_fault(trans.addr, trans.err_mask);
      end
      default: `uvm_error("DRV", "invalid op")
    endcase
    trans.trans_time = $time;
  endtask
endclass : sram_driver

`endif
