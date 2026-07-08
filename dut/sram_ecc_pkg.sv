`ifndef SRAM_ECC_PKG_SV
`define SRAM_ECC_PKG_SV

// secded (39,32) hamming + overall parity
// shared by the behavioral model and the scoreboard so both agree on the code
package sram_ecc_pkg;

  localparam int ECC_DATA = 32;
  localparam int ECC_PARITY = 7;  // 6 hamming + 1 overall
  localparam int ECC_CW = ECC_DATA + ECC_PARITY;  // 39 bit codeword

  function automatic bit is_pow2(input int i);
    return (i == 1) || (i == 2) || (i == 4) || (i == 8) || (i == 16) || (i == 32);
  endfunction

  // build the 1-indexed hamming vector with data in the non parity slots
  function automatic logic [38:1] ecc_interleave(input logic [31:0] data);
    logic [38:1] cw;
    int j;
    j = 0;
    for (int i = 1; i <= 38; i++) begin
      if (is_pow2(i)) cw[i] = 1'b0;
      else begin
        cw[i] = data[j];
        j++;
      end
    end
    return cw;
  endfunction

  // pull the 32 data bits back out of the hamming vector
  function automatic logic [31:0] ecc_extract(input logic [38:1] cw);
    logic [31:0] data;
    int j;
    j = 0;
    for (int i = 1; i <= 38; i++) begin
      if (!is_pow2(i)) begin
        data[j] = cw[i];
        j++;
      end
    end
    return data;
  endfunction

  // returns {overall, p5..p0}
  function automatic logic [6:0] ecc_encode(input logic [31:0] data);
    logic [38:1] cw;
    logic [ 5:0] p;
    cw = ecc_interleave(data);
    for (int k = 0; k < 6; k++) begin
      logic acc;
      acc = 1'b0;
      for (int i = 1; i <= 38; i++) if (i[k]) acc ^= cw[i];
      p[k] = acc;
    end
    return {(^{data, p}), p};
  endfunction

  function automatic void ecc_decode(input logic [31:0] data_in, input logic [6:0] check_in,
                                     output logic [31:0] data_out, output logic single_err,
                                     output logic double_err);
    logic [38:1] cw;
    logic [ 5:0] syndrome;
    logic        parity_err;
    logic [ 6:0] regen;

    regen      = ecc_encode(data_in);
    syndrome   = regen[5:0] ^ check_in[5:0];
    parity_err = ^{data_in, check_in};

    single_err = 1'b0;
    double_err = 1'b0;
    cw         = ecc_interleave(data_in);

    if (syndrome == 0 && !parity_err) begin
    end else if (parity_err) begin
      single_err = 1'b1;
      if (syndrome != 0 && syndrome <= 38) cw[syndrome] = ~cw[syndrome];
    end else begin
      // syndrome set but parity ok -> double bit, not correctable
      double_err = 1'b1;
    end

    data_out = ecc_extract(cw);
  endfunction

endpackage

`endif
