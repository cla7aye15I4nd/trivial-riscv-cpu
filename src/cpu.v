`include "common_defs.vh"
`include "cpu/cpu_defs.vh"
`include "cpu/if/cpu_if.v"
`include "cpu/id/decoder.v"
`include "cpu/id/reg_stat.v"
`include "cpu/dp/allocator.v"
`include "cpu/ex/rs_alu.v"
`include "cpu/ex/ex_alu.v"
`include "cache/cache.v"
// RISCV32I CPU top module
// port modification allowed for debugging purposes

module cpu(
    input  wire                 clk_in,			// system clock signal
    input  wire                 rst_in,			// reset signal
	  input  wire					        rdy_in,			// ready signal, pause cpu when low

    input  wire [ 7:0]          mem_din,		// data input bus
    output wire [ 7:0]          mem_dout,		// data output bus
    output wire [31:0]          mem_a,			// address bus (only 17:0 is used)
    output wire                 mem_wr,			// write/read signal (1 for write)

	  output wire [31:0]			    dbgreg_dout // cpu register output (debugging demo)
);

// implementation goes here

// Specifications:
// - Pause cpu(freeze pc, registers, etc.) when rdy_in is low
// - Memory read takes 2 cycles(wait till next cycle), write takes 1 cycle(no need to wait)
// - Memory is of size 128KB, with valid address ranging from 0x0 to 0x20000
// - I/O port is mapped to address higher than 0x30000 (mem_a[17:16]==2'b11)
// - 0x30000 read: read a byte from input
// - 0x30000 write: write a byte to output (write 0x00 is ignored)
// - 0x30004 read: read clocks passed since cpu starts (in dword, 4 bytes)
// - 0x30004 write: indicates program stop (will output '\0' through uart tx)

wire cache_en_rx, cache_en_ry, cache_hitx, cache_hity;
wire `addr_t cache_pcx, cache_pcy;
wire `word_t cache_instx, cache_insty;
cache cache_instance(
  .clk(clk_in), .rst(rst_in), .rdy(rdy_in),

  .en_rx(cache_en_rx), .pcx(cache_pcx), .hitx(cache_hitx), .instx(cache_instx),
  .en_ry(cache_en_ry), .pcy(cache_pcy), .hity(cache_hity), .insty(cache_insty),

  .data_in(mem_din), .data_out(mem_dout), .r_nw_out(mem_wr), .addr_out(mem_a)
);

wire  if_hit0, if_hit1;
wire `addr_t if_pc0, if_pc1;
wire `inst_t if_inst0, if_inst1;

// IF
cpu_if cpu_if_instance(
    .clk(clk_in), .rst(rst_in), .rdy(rdy_in),

    .hitx(cache_hitx), .hity(cache_hity),
    .instx(cache_instx), .insty(cache_insty),

    .en_rx_out(cache_en_rx), .en_ry_out(cache_en_ry),
    .pcx_out(cache_pcx), .pcy_out(cache_pcy),

    .pc0_out(if_pc0), .pc1_out(if_pc1),
    .hitx_out(if_hit0), .hity_out(if_hit1),
    .instx_out(if_inst0), .insty_out(if_inst1)
);

// Decoder output / RegStat Input
wire `oper_t op0, op1;
wire `word_t imm0, imm1;
wire en_rx0, en_rx1;
wire en_ry0, en_ry1;
wire en_w0, en_w1;
wire `regaddr_t reg_read_addrx0, reg_read_addrx1;
wire `regaddr_t reg_read_addry0, reg_read_addry1;
wire `regaddr_t reg_write_addr0, reg_write_addr1;

// Decoder
decoder decoder_master(
  .clk(clk_in), .rdy(rdy_in), //.stall()
  .hit(if_hit0), .pc(if_pc0), .inst(if_inst0),

  .op(op0), .imm(imm0), 
  .en_rx(en_rx0), .en_ry(en_ry0), .en_w(en_w0),
  .reg_read_addrx(reg_read_addrx0), 
  .reg_read_addry(reg_read_addry0), 
  .reg_write_addr(reg_write_addr0)
);

decoder decoder_salve(
  .clk(clk_in), .rdy(rdy_in), //.stall()
  .hit(if_hit1), .pc(if_pc1), .inst(if_inst1),

  .op(op1), .imm(imm1), 
  .en_rx(en_rx1), .en_ry(en_ry1), .en_w(en_w1),
  .reg_read_addrx(reg_read_addrx1), 
  .reg_read_addry(reg_read_addry1), 
  .reg_write_addr(reg_write_addr1)
);

// RegStat Output 
wire `word_t read_datax0, read_datay0;
wire `word_t read_datax1, read_datay1;
wire `regtag_t read_lockx0, read_locky0, write_lock0;
wire `regtag_t read_lockx1, read_locky1, write_lock1;

// Allocator Update Signal
wire alloc_en_mw0, alloc_en_mw1;
wire `regaddr_t alloc_maddr0, alloc_maddr1;
wire `regtag_t alloc_mtag0, alloc_mtag1;

wire regs_enw0, regs_enw1, regs_enw2;
wire `regaddr_t regs_waddr0, regs_waddr1, regs_waddr2;
wire `word_t regs_wdata0, regs_wdata1, regs_wdata2;

// RegStat
reg_stat reg_stat_instance(
  .imm0(imm0), .imm1(imm1),
  .en_rx0(en_rx0), .reg_read_addrx0(reg_read_addrx0), .read_datax0(read_datax0), .lockx0(read_lockx0),
  .en_ry0(en_ry0), .reg_read_addry0(reg_read_addry0), .read_datay0(read_datay0), .locky0(read_locky0),
  .en_rx1(en_rx1), .reg_read_addrx1(reg_read_addrx1), .read_datax1(read_datax1), .lockx1(read_lockx1),
  .en_ry1(en_ry1), .reg_read_addry1(reg_read_addry1), .read_datay1(read_datay1), .locky1(read_locky1),
  
  .en_rw0(en_w0), .addrw0(reg_write_addr0), .lockw0(write_lock0),
  .en_rw1(en_w1), .addrw1(reg_write_addr1), .lockw1(write_lock1),

  .en_w0(reg_enw0), .reg_write_addr0(regs_waddr0), .write_data0(regs_wdata0),
  .en_w1(reg_enw1), .reg_write_addr1(regs_waddr1), .write_data1(regs_wdata1),
  .en_w2(reg_enw2), .reg_write_addr2(regs_waddr2), .write_data2(regs_wdata2),

  .en_mod0(alloc_en_mw0), .en_mod1(alloc_en_mw1), 
  .reg_addr0(alloc_maddr0), .reg_addr1(alloc_maddr1),
  .reg_tag0(alloc_mtag0), .reg_tag1(alloc_mtag1),

  .clk(clk_in), .rst(rst_in), .rdy(rdy_in)
);

// Allocator
wire alloc_en0, alloc_en1;
wire`sinst_t alloc_op0, alloc_op1;
wire `regtag_t alloc_tagx0, alloc_tagx1;
wire `regtag_t alloc_tagy0, alloc_tagy1;
wire `regtag_t alloc_tagw0, alloc_tagw1;
wire `word_t alloc_datax0, alloc_datax1;
wire `word_t alloc_datay0, alloc_datay1;
wire `addr_t alloc_addrw0, alloc_addrw1;

// ALU
wire alu0_busy_upd, alu1_busy_upd;
wire `regtag_t alu0_tagx_upd, alu0_tagy_upd, alu0_tagw_upd;
wire `regtag_t alu1_tagx_upd, alu1_tagy_upd, alu1_tagw_upd;

allocator allocator_instance(
  .op0(op0), .en_rx0(en_rx0), .en_ry0(en_ry0), .en_w0(en_w0),
  .read_lockx0(read_lockx0), .read_locky0(read_locky0),
  .read_datax0(read_datax0), .read_datay0(read_datay0),
  .read_addrx0(reg_read_addrx0), .read_addry0(reg_read_addry0),
  .write_lock0(write_lock0), .write_addr0(reg_write_addr0),

  .op1(op1), .en_rx1(en_rx1), .en_ry1(en_ry1), .en_w1(en_w1),
  .read_lockx1(read_lockx1), .read_locky1(read_locky1),
  .read_datax1(read_datax1), .read_datay1(read_datay1),
  .read_addrx1(reg_read_addrx1), .read_addry1(reg_read_addry1),
  .write_lock1(write_lock1), .write_addr1(reg_write_addr1),

  .en_mw0(alloc_en_mw0), .en_mw1(alloc_en_mw1),
  .maddr0(alloc_maddr0), .maddr1(alloc_maddr1),
  .mtag0(alloc_mtag0), .mtag1(alloc_mtag1),

  .alu0_busy(alu0_busy_upd), .alu0_tagx_in(alu0_tagx_upd), .alu0_tagy_in(alu0_tagy_upd), .alu0_tagw_in(alu0_tagw_upd), 
  .alu1_busy(alu1_busy_upd), .alu1_tagx_in(alu1_tagx_upd), .alu1_tagy_in(alu1_tagy_upd), .alu1_tagw_in(alu1_tagw_upd),

  .alu0_en_out(alloc_en0), .alu0_op_out(alloc_op0), 
  .alu0_tagx_out(alloc_tagx0), .alu0_tagy_out(alloc_tagy0), .alu0_tagw_out(alloc_tagw0),
  .alu0_datax_out(alloc_datax0), .alu0_datay_out(alloc_datay0), .alu0_addrw_out(alloc_addrw0),

  .alu1_en_out(alloc_en1), .alu1_op_out(alloc_op1), 
  .alu1_tagx_out(alloc_tagx1), .alu1_tagy_out(alloc_tagy1), .alu1_tagw_out(alloc_tagw1),
  .alu1_datax_out(alloc_datax1), .alu1_datay_out(alloc_datay1), .alu1_addrw_out(alloc_addrw1),
  
  .branch_busy(), .ls_busy(), 

  .clk(clk_in), .rst(rst_in), .rdy(rdy_in)
);

wire alu0_busy_in, alu1_busy_in;
wire `sinst_t alu0_op_in, alu1_op_in;
wire `regtag_t alu0_tagx_in, alu1_tagx_in;
wire `regtag_t alu0_tagy_in, alu1_tagy_in;
wire `regtag_t alu0_tagw_in, alu1_tagw_in;
wire `word_t alu0_datax_in, alu1_datax_in;
wire `word_t alu0_datay_in, alu1_datay_in;
wire `regaddr_t alu0_target_in, alu1_target_in;

// rs_alu
rs_alu rs_alu_instance(
  // From allocator
  .en0(alloc_en0), .op0(alloc_op0),
  .tagx0(alloc_tagx0), .tagy0(alloc_tagy0), .tagw0(alloc_tagw0),
  .datax0(alloc_datax0), .datay0(alloc_datay0), .addrw0(alloc_addrw0),

  .en1(alloc_en1), .op1(alloc_op1),
  .tagx1(alloc_tagx1), .tagy1(alloc_tagy1), .tagw1(alloc_tagw1),
  .datax1(alloc_datax1), .datay1(alloc_datay1), .addrw1(alloc_addrw1),

  .busy_alu0(), .alu_tag0(), .alu_data0(),
  .busy_alu1(), .alu_tag1(), .alu_data1(),
  .busy_ls(), .ls_tag(), .ls_data(),

  .alu_busy0_out(), .alu_op0_out(),
  .alu_tagx0_out(), .alu_tagy0_out(), .alu_tagw0_out(),
  .alu_datax0_out(), .alu_datay0_out(), .alu_target0_out(),

  .alu_busy1_out(), .alu_op1_out(),
  .alu_tagx1_out(), .alu_tagy1_out(), .alu_tagw1_out(),
  .alu_datax1_out(), .alu_datay1_out(), .alu_target1_out(),

  .clk(clk_in), .rst(rst_in), .rdy(rdy_in)
);

ex_alu ex_alu_master(
  .alu_busy_in(alu0_busy_in), .alu_op_in(alu0_op_in),
  .alu_tagx_in(alu0_tagx_in), .alu_tagy_in(alu0_tagy_in), .alu_tagw_in(alu0_tagw_in),
  .alu_datax_in(alu0_datax_in), .alu_datay_in(alu0_datay_in), .alu_target_in(alu0_target_in),

  .alu_busy_out(alu0_busy_upd),
  .alu_tagx_out(alu0_tagx_upd), 
  .alu_tagy_out(alu0_tagy_upd), 
  .alu_tagw_out(alu0_tagw_upd),

  .en(reg_enw0), .target_out(regs_waddr0), .data_out(regs_wdata0)
);

endmodule