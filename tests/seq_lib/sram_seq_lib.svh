//======================================================
// base sequence with objection handling
//======================================================
class sram_base_seq extends uvm_sequence #(sram_packet);
  `uvm_object_utils(sram_base_seq)

  // one rep. address per coverage region
  bit [ADDR_WIDTH-1:0] region_addr[8] = '{0, 512, 1500, 2500, 3500, 5000, 7000, 8191};

  function new(string name = "sram_base_seq");
    super.new(name);
  endfunction

  virtual task pre_body();
    uvm_phase phase = get_starting_phase();
    if (phase != null) phase.raise_objection(this);
  endtask

  virtual task post_body();
    uvm_phase phase = get_starting_phase();
    if (phase != null) phase.drop_objection(this);
  endtask

  // helpers
  task do_write(bit [ADDR_WIDTH-1:0] a, bit [DATA_WIDTH-1:0] d);
    req = sram_packet::type_id::create("wr");
    start_item(req);
    if (!req.randomize() with {
          op == WRITE;
          addr == a;
          din == d;
        })
      `uvm_error(get_type_name(), "write randomize failed")
    finish_item(req);
  endtask

  task do_read(bit [ADDR_WIDTH-1:0] a, bit [2:0] lat, int gap = -1, bit [ECC_CW-1:0] mask = '0);
    req = sram_packet::type_id::create("rd");
    start_item(req);
    if (!req.randomize() with {
          op == READ;
          addr == a;
          read_latency == lat;
          err_mask == mask;
        })
      `uvm_error(get_type_name(), "read randomize failed")
    req.raw_gap = gap;
    finish_item(req);
  endtask
endclass


//======================================================
// random read/write traffic
//======================================================
class sram_random_seq extends sram_base_seq;
  `uvm_object_utils(sram_random_seq)

  rand int num_transactions = 300;

  function new(string name = "sram_random_seq");
    super.new(name);
  endfunction

  task body();
    for (int i = 0; i < num_transactions; i++) begin
      req = sram_packet::type_id::create("req");
      start_item(req);
      if (!req.randomize() with {
            op dist {
              WRITE := 6,
              READ  := 4
            };
            read_latency inside {[1 : 4]};
          })
        `uvm_error(get_type_name(), "randomize failed")
      finish_item(req);
    end
  endtask
endclass


//======================================================
// data pattern sweep, write then read back each pattern
//======================================================
class sram_pattern_seq extends sram_base_seq;
  `uvm_object_utils(sram_pattern_seq)

  function new(string name = "sram_pattern_seq");
    super.new(name);
  endfunction

  task body();
    bit [DATA_WIDTH-1:0] pats[] = '{
        32'h0000_0000,
        32'hFFFF_FFFF,
        32'hAAAA_AAAA,
        32'h5555_5555,
        32'hF0F0_F0F0,
        32'h0F0F_0F0F,
        32'h0000_0001,
        32'h1234_5678
    };

    foreach (pats[i]) begin
      bit [ADDR_WIDTH-1:0] a = region_addr[i%8];
      bit [2:0] lat = 1 + (i % 4);
      do_write(a, pats[i]);
      do_read(a, lat);
    end
  endtask
endclass


//======================================================
// read after write hazards across gaps, regions and latencies
//======================================================
class sram_raw_hazard_seq extends sram_base_seq;
  `uvm_object_utils(sram_raw_hazard_seq)

  int gaps[] = '{0, 1, 2, 3, 4, 8, 20};

  function new(string name = "sram_raw_hazard_seq");
    super.new(name);
  endfunction

  task body();
    foreach (region_addr[r]) begin
      foreach (gaps[g]) begin
        for (int lat = 1; lat <= 4; lat++) begin
          bit [DATA_WIDTH-1:0] d = 32'hCAFE_0000 + (r << 8) + gaps[g];
          do_write(region_addr[r], d);
          // intervening traffic to a scratch region to build the gap
          repeat (gaps[g]) do_write(1024, 32'hDEAD_BEEF);
          do_read(region_addr[r], lat[2:0], gaps[g]);
        end
      end
    end
  endtask
endclass


//======================================================
// ecc single bit correction across every codeword position
//======================================================
class sram_ecc_seq extends sram_base_seq;
  `uvm_object_utils(sram_ecc_seq)

  function new(string name = "sram_ecc_seq");
    super.new(name);
  endfunction

  task body();
    bit [DATA_WIDTH-1:0] seed = 32'hA5A5_5A5A;
    for (int pos = 0; pos < ECC_CW; pos++) begin
      bit [ADDR_WIDTH-1:0] a = region_addr[pos%8];
      bit [2:0] lat = 1 + (pos % 4);
      bit [ECC_CW-1:0] mask;
      mask = '0;
      mask[pos] = 1'b1;  // one hot fault at this codeword position
      do_write(a, seed ^ pos);
      do_read(a, lat, -1, mask);  // single flipped bit, corrected on read
    end
  endtask
endclass


//======================================================
// ecc double bit detection, two flipped bits are uncorrectable
//======================================================
class sram_ecc_double_seq extends sram_base_seq;
  `uvm_object_utils(sram_ecc_double_seq)

  function new(string name = "sram_ecc_double_seq");
    super.new(name);
  endfunction

  task body();
    for (int i = 0; i < 16; i++) begin
      bit [ADDR_WIDTH-1:0] a = region_addr[i%8];
      bit [2:0] lat = 1 + (i % 4);
      int b0 = i % ECC_CW;
      int b1 = (i * 7 + 3) % ECC_CW;
      bit [ECC_CW-1:0] mask;
      if (b1 == b0) b1 = (b1 + 1) % ECC_CW;
      mask = '0;
      mask[b0] = 1'b1;
      mask[b1] = 1'b1;  // two flipped bits, detected not corrected
      do_write(a, 32'hD0D0_0000 + i);
      do_read(a, lat, -1, mask);
    end
  endtask
endclass


//======================================================
// read latency sweep 1..4
//======================================================
class sram_latency_seq extends sram_base_seq;
  `uvm_object_utils(sram_latency_seq)

  function new(string name = "sram_latency_seq");
    super.new(name);
  endfunction

  task body();
    for (int lat = 1; lat <= 4; lat++) begin
      foreach (region_addr[r]) begin
        do_write(region_addr[r], 32'h1111_0000 + r);
        do_read(region_addr[r], lat[2:0]);
      end
    end
  endtask
endclass


//======================================================
// same address stress
//======================================================
class sram_same_addr_seq extends sram_base_seq;
  `uvm_object_utils(sram_same_addr_seq)

  rand bit [ADDR_WIDTH-1:0] target_addr = 42;

  function new(string name = "sram_same_addr_seq");
    super.new(name);
  endfunction

  task body();
    repeat (20) begin
      bit [DATA_WIDTH-1:0] d = $urandom();
      do_write(target_addr, d);
      do_read(target_addr, 3'd2, 0);
    end
  endtask
endclass
