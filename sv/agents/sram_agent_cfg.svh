`ifndef SRAM_AGENT_CFG_SV
`define SRAM_AGENT_CFG_SV

class sram_agent_cfg extends uvm_object;
  `uvm_object_utils(sram_agent_cfg)

  //============================================
  //  USELESS SIGNALS, REMOVE LATER
  //============================================

  // Agent mode and queue configuration
  uvm_active_passive_enum is_active              = UVM_ACTIVE;
  int unsigned            drv_fifo_depth         = 2;
  int unsigned            mon_fifo_depth         = 2;

  // Driver behavior control
  bit                     drive_idle_state       = 1;
  bit                     allow_backpressure     = 0;
  int unsigned            max_retries            = 3;

  // Scoreboard configuration
  bit                     scoreboard_enable      = 1;
  bit                     allow_x                = 0;  // Allow X in expected data
  bit                     use_last_written       = 1;  // Use last written data for prediction
  bit                     strict_protocol        = 1;  // Enable strict protocol checking
  bit                     verbose                = 1;  // Enable detailed scoreboard logging

  // Coverage configuration
  bit                     en_coverage            = 1;
  bit                     functional_coverage    = 1;
  bit                     protocol_coverage      = 1;
  bit                     data_coverage          = 1;

  // Debug and error handling
  bit                     debug_mode             = 0;
  bit                     ignore_protocol_errors = 0;
  bit                     continue_on_error      = 0;

  // Timing and performance
  time                    clock_period           = 10ns;
  int unsigned            pipeline_depth         = 1;

  function new(string name = "sram_agent_cfg");
    super.new(name);
  endfunction

  virtual function string convert2string();
    return $sformatf(
        {
          "SRAM Agent Configuration:\n",
          "-------------------------\n",
          "Active Mode:         %s\n",
          "Driver FIFO Depth:   %0d\n",
          "Monitor FIFO Depth:  %0d\n",
          "Scoreboard Enabled:  %b\n",
          "Allow X:             %b\n",
          "Use Last Written:    %b\n",
          "Strict Protocol:     %b\n",
          "Coverage Enabled:    %b\n",
          "Pipeline Depth:      %0d\n",
          "Clock Period:        %0t\n"
        },
        is_active.name(),
        drv_fifo_depth,
        mon_fifo_depth,
        scoreboard_enable,
        allow_x,
        use_last_written,
        strict_protocol,
        en_coverage,
        pipeline_depth,
        clock_period
    );
  endfunction

  virtual function void do_copy(uvm_object rhs);
    sram_agent_cfg rhs_;
    if (!$cast(rhs_, rhs)) begin
      `uvm_error("CFG/COPY", "Type mismatch in configuration copy")
      return;
    end
    super.do_copy(rhs);
    is_active              = rhs_.is_active;
    drv_fifo_depth         = rhs_.drv_fifo_depth;
    mon_fifo_depth         = rhs_.mon_fifo_depth;
    drive_idle_state       = rhs_.drive_idle_state;
    scoreboard_enable      = rhs_.scoreboard_enable;
    allow_x                = rhs_.allow_x;
    use_last_written       = rhs_.use_last_written;
    strict_protocol        = rhs_.strict_protocol;
    en_coverage            = rhs_.en_coverage;
    functional_coverage    = rhs_.functional_coverage;
    protocol_coverage      = rhs_.protocol_coverage;
    data_coverage          = rhs_.data_coverage;
    debug_mode             = rhs_.debug_mode;
    ignore_protocol_errors = rhs_.ignore_protocol_errors;
    continue_on_error      = rhs_.continue_on_error;
    clock_period           = rhs_.clock_period;
    pipeline_depth         = rhs_.pipeline_depth;
  endfunction
endclass : sram_agent_cfg

`endif
