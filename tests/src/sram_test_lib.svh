//==============================================
// base test
//==============================================
class sram_base_test extends uvm_test;
  `uvm_component_utils(sram_base_test)
  sram_env env;

  function new(string name = "sram_base_test", uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = sram_env::type_id::create("env", this);
  endfunction

  function void end_of_elaboration_phase(uvm_phase phase);
    uvm_root::get().print_topology();
  endfunction
endclass


//==============================================
// full regression, closes the functional coverage model
//==============================================
class sram_regression_test extends sram_base_test;
  `uvm_component_utils(sram_regression_test)

  function new(string name = "sram_regression_test", uvm_component parent);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    sram_pattern_seq    pat;
    sram_raw_hazard_seq raw;
    sram_ecc_seq        ecc;
    sram_ecc_double_seq ecc2;
    sram_latency_seq    lat;
    sram_random_seq     rnd;

    phase.raise_objection(this);

    pat  = sram_pattern_seq::type_id::create("pat");
    raw  = sram_raw_hazard_seq::type_id::create("raw");
    ecc  = sram_ecc_seq::type_id::create("ecc");
    ecc2 = sram_ecc_double_seq::type_id::create("ecc2");
    lat  = sram_latency_seq::type_id::create("lat");
    rnd  = sram_random_seq::type_id::create("rnd");

    pat.start(env.agent.m_seqr);
    raw.start(env.agent.m_seqr);
    ecc.start(env.agent.m_seqr);
    ecc2.start(env.agent.m_seqr);
    lat.start(env.agent.m_seqr);
    rnd.start(env.agent.m_seqr);

    phase.get_objection().set_drain_time(this, 200ns);
    phase.drop_objection(this);
  endtask
endclass


//==============================================
// focused tests
//==============================================
class sram_rand_seq_test extends sram_base_test;
  `uvm_component_utils(sram_rand_seq_test)
  function new(string name = "sram_rand_seq_test", uvm_component parent);
    super.new(name, parent);
  endfunction
  task run_phase(uvm_phase phase);
    sram_random_seq seq = sram_random_seq::type_id::create("seq");
    phase.raise_objection(this);
    seq.start(env.agent.m_seqr);
    phase.get_objection().set_drain_time(this, 200ns);
    phase.drop_objection(this);
  endtask
endclass


class sram_raw_hazard_test extends sram_base_test;
  `uvm_component_utils(sram_raw_hazard_test)
  function new(string name = "sram_raw_hazard_test", uvm_component parent);
    super.new(name, parent);
  endfunction
  task run_phase(uvm_phase phase);
    sram_raw_hazard_seq seq = sram_raw_hazard_seq::type_id::create("seq");
    phase.raise_objection(this);
    seq.start(env.agent.m_seqr);
    phase.get_objection().set_drain_time(this, 200ns);
    phase.drop_objection(this);
  endtask
endclass


class sram_ecc_test extends sram_base_test;
  `uvm_component_utils(sram_ecc_test)
  function new(string name = "sram_ecc_test", uvm_component parent);
    super.new(name, parent);
  endfunction
  task run_phase(uvm_phase phase);
    sram_ecc_seq seq = sram_ecc_seq::type_id::create("seq");
    phase.raise_objection(this);
    seq.start(env.agent.m_seqr);
    phase.get_objection().set_drain_time(this, 200ns);
    phase.drop_objection(this);
  endtask
endclass


class sram_ecc_double_test extends sram_base_test;
  `uvm_component_utils(sram_ecc_double_test)
  function new(string name = "sram_ecc_double_test", uvm_component parent);
    super.new(name, parent);
  endfunction
  task run_phase(uvm_phase phase);
    sram_ecc_double_seq seq = sram_ecc_double_seq::type_id::create("seq");
    phase.raise_objection(this);
    seq.start(env.agent.m_seqr);
    phase.get_objection().set_drain_time(this, 200ns);
    phase.drop_objection(this);
  endtask
endclass


class sram_latency_test extends sram_base_test;
  `uvm_component_utils(sram_latency_test)
  function new(string name = "sram_latency_test", uvm_component parent);
    super.new(name, parent);
  endfunction
  task run_phase(uvm_phase phase);
    sram_latency_seq seq = sram_latency_seq::type_id::create("seq");
    phase.raise_objection(this);
    seq.start(env.agent.m_seqr);
    phase.get_objection().set_drain_time(this, 200ns);
    phase.drop_objection(this);
  endtask
endclass
