`ifndef SRAM_PACKET_SVH
`define SRAM_PACKET_SVH

class sram_packet extends uvm_sequence_item;
  typedef enum {
    READ  = 0,
    WRITE = 1
  } op_t;

  rand op_t op;
  rand logic [ADDR_WIDTH-1:0] addr;
  rand logic [DATA_WIDTH-1:0] din;
  rand logic [2:0] read_latency;  // 1..4
  logic we_n;
  logic [DATA_WIDTH-1:0] dout;

  // ecc / fault modelling
  rand logic [ECC_CW-1:0] err_mask;  // bits flipped in stored codeword
  logic ecc_single;
  logic ecc_double;

  // annotation for coverage, filled by the sequences / predictor
  int raw_gap = -1;  // cycles since last write to addr
  time trans_time;

  constraint op_c {op inside {READ, WRITE};}
  constraint addr_c {addr inside {[0 : (2 ** ADDR_WIDTH) - 1]};}
  constraint lat_c {read_latency inside {[1 : 4]};}
  constraint err_c {soft err_mask == '0;}  // clean unless a seq asks for a fault
  constraint data_c {if (op == READ) din == 0;}
  constraint dist_c {
    op dist {
      READ  := 50,
      WRITE := 50
    };
  }

  `uvm_object_utils_begin(sram_packet)
    `uvm_field_enum(op_t, op, UVM_ALL_ON)
    `uvm_field_int(addr, UVM_ALL_ON)
    `uvm_field_int(din, UVM_ALL_ON)
    `uvm_field_int(read_latency, UVM_ALL_ON)
    `uvm_field_int(we_n, UVM_ALL_ON)
    `uvm_field_int(dout, UVM_ALL_ON)
    `uvm_field_int(err_mask, UVM_ALL_ON)
    `uvm_field_int(ecc_single, UVM_ALL_ON)
    `uvm_field_int(ecc_double, UVM_ALL_ON)
    `uvm_field_int(raw_gap, UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name = "sram_packet");
    super.new(name);
  endfunction

  function void post_randomize();
    we_n = (op == WRITE) ? 1'b0 : 1'b1;
  endfunction

  virtual function string convert2string();
    return $sformatf(
        "%s @%0t | %s addr:0x%0h din:0x%0h dout:0x%0h lat:%0d se:%0b de:%0b raw:%0d",
        get_type_name(),
        trans_time,
        op.name(),
        addr,
        din,
        dout,
        read_latency,
        ecc_single,
        ecc_double,
        raw_gap
    );
  endfunction

  virtual function void do_copy(uvm_object rhs);
    sram_packet r;
    if (!$cast(r, rhs)) `uvm_fatal("DO_COPY", "type mismatch")
    super.do_copy(rhs);
    op           = r.op;
    addr         = r.addr;
    din          = r.din;
    read_latency = r.read_latency;
    we_n         = r.we_n;
    dout         = r.dout;
    err_mask     = r.err_mask;
    ecc_single   = r.ecc_single;
    ecc_double   = r.ecc_double;
    raw_gap      = r.raw_gap;
    trans_time   = r.trans_time;
  endfunction

  virtual function bit do_compare(uvm_object rhs, uvm_comparer comparer);
    sram_packet r;
    if (!$cast(r, rhs)) return 0;
    return super.do_compare(
        rhs, comparer
    ) && (op == r.op) && (addr == r.addr) && (din == r.din) && (dout == r.dout);
  endfunction
endclass : sram_packet

`endif
