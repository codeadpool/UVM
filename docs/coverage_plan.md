# sram uvc coverage plan

single port 32kB sram controller, 8192 x 32 with secded ecc and runtime read
latency. functional coverage lives in `sv/top/sram_coverage.svh`, sampled off the
driver stream so it sees the sequence intent (raw gap, injected fault, latency).

## coverpoints

| coverpoint  | what it captures                                          |
|-------------|-----------------------------------------------------------|
| cp_op       | read vs write                                             |
| cp_addr     | address regions across the 8k word map                   |
| cp_data     | zero, ones, aa, 55, f0, 0f, walking, misc data patterns   |
| cp_raw      | read after write gap 0,1,2,3,4,near,far                   |
| cp_ecc      | clean, single bit corrected, double bit detected          |
| cp_ecc_pos  | affected bit position groups over the 39b codeword        |
| cp_lat      | read latency 1,2,3,4                                       |

## crosses

x_op_addr, x_op_data, x_op_lat, x_raw_addr, x_raw_lat, x_addr_lat, x_ecc_lat.

## how it is closed

- `sram_pattern_seq` writes and reads back each data pattern.
- `sram_raw_hazard_seq` sweeps every gap across every region and latency.
- `sram_ecc_seq` flips one bit per codeword position, exercising correction at
  every position and every latency.
- `sram_ecc_double_seq` flips two bits so the code detects an uncorrectable error.
- `sram_latency_seq` sweeps latency 1..4 across all regions.
- `sram_random_seq` fills in the remaining cross space.

the covergroup prints an overall number and a per point breakdown in
`report_phase`, so coverage is readable straight from the sim log.

## timing

model delays are the nominal pvt 0.7v 25c corner from
`asap7_srambank_excerpt.lib`:

- setup  ~48 ps
- hold   ~6.4 ps
- clk to dataout ~134 ps
- min pulse width ~4 ps

these drive the `specify` block and the dataout access delay in
`dut/sram_behavioral_model.sv`, so rtl sim is timing aware before a gate netlist
exists.
