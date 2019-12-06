`include "common_defs.v"
`include "cpu/cpu_defs.v"
`include "cpu/fetch/cpu_if.v"
`include "cpu/dispatch/decoder.v"
`include "cpu/dispatch/reg_stat.v"
`include "cpu/dispatch/allocator.v"
`include "cpu/execute/rs_alu.v"
`include "cpu/execute/ex_alu.v"
`include "cpu/execute/rs_ls.v"
`include "cpu/execute/ex_ls.v"
`include "cpu/execute/rs_branch.v"
`include "cpu/execute/ex_branch.v"
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
wire cahce_en_ls, cache_ls_oper, cahce_in_fifo, cahce_finish;
wire `addr_t cache_ls_addr;
wire `byte_t cache_ls_size;
wire `word_t cache_ls_data;
wire `word_t cache_data_out;

cache cache_instance(
  .clk(clk_in), .rst(rst_in), .rdy(rdy_in),

  .en_ls(cache_en_ls), 
  .ls_oper(cache_ls_oper),
  .ls_addr(cache_ls_addr), 
  .ls_size(cache_ls_size),
  .ls_data(cache_ls_data),
  .in_fifo(cache_in_fifo), .finish(cache_finish),
  .ls_data_out(cache_data_out),

  .en_rx(cache_en_rx), .pcx(cache_pcx), .hitx(cache_hitx), .instx(cache_instx),
  .en_ry(cache_en_ry), .pcy(cache_pcy), .hity(cache_hity), .insty(cache_insty),

  .data_in(mem_din), .data_out(mem_dout), .r_nw_out(mem_wr), .addr_out(mem_a)
);

wire  if_hit0, if_hit1, issue0, issue1;
wire `addr_t if_pc0, if_pc1;
wire `inst_t if_inst0, if_inst1;
wire en_jmp0, en_jmp1;
wire `addr_t jmp_addr0, jmp_addr1;
wire en_branch;
wire `word_t result;

// IF
cpu_if cpu_if_instance(
    .clk(clk_in), .rst(rst_in), .rdy(rdy_in),

    .hitx(cache_hitx), .hity(cache_hity),
    .instx(cache_instx), .insty(cache_insty),

    .en_rx_out(cache_en_rx), .en_ry_out(cache_en_ry),
    .pcx_out(cache_pcx), .pcy_out(cache_pcy),

    .en_jmp0(en_jmp0), .en_jmp1(en_jmp1),
    .jmp_addr0(jmp_addr0), .jmp_addr1(jmp_addr1),

    .en_branch(en_branch), .result(result),

    .issue0(issue0), .issue1(issue1),
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
wire `addr_t alloc_pc0, alloc_pc1;

wire mod_enw0, mod_enw1, mod_enw2;
wire `regaddr_t mod_addr0, mod_addr1, mod_addr2;
wire `regtag_t  mod_tag0, mod_tag1, mod_tag2;

// Decoder
decoder decoder_master(
  .clk(clk_in), .rdy(rdy_in), .rst(rst_in),
  .hit(if_hit0), .issue(issue0),
  .pc_in(if_pc0), .inst_in(if_inst0),

  .pc_out(alloc_pc0),
  .op(op0), .imm(imm0), 
  .en_rx(en_rx0), .en_ry(en_ry0), .en_w(en_w0),
  .reg_read_addrx(reg_read_addrx0), 
  .reg_read_addry(reg_read_addry0), 
  .reg_write_addr(reg_write_addr0)
);

decoder decoder_salve(
  .clk(clk_in), .rdy(rdy_in), .rst(rst_in),
  .hit(if_hit1), .issue(issue1),
  .pc_in(if_pc1), .inst_in(if_inst1),

  .pc_out(alloc_pc1),
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

wire alu0_busy_in, alu1_busy_in, ls_busy_in, branch_busy_in;
wire `sinst_t alu0_op_in, alu1_op_in, ls_op_in, branch_op_in;
wire `regtag_t alu0_tagx_in, alu1_tagx_in, ls_tagx_in, branch_tagx_in;
wire `regtag_t alu0_tagy_in, alu1_tagy_in, ls_tagy_in, branch_tagy_in;
wire `regtag_t alu0_tagw_in, alu1_tagw_in, ls_tagw_in;
wire `word_t alu0_datax_in, alu1_datax_in, ls_datax_in, branch_datax_in;
wire `word_t alu0_datay_in, alu1_datay_in, ls_datay_in, branch_datay_in;
wire `regaddr_t alu0_target_in, alu1_target_in, ls_target_in;
wire `word_t ls_offset_in, branch_offset_in;

// RegStat
reg_stat reg_stat_instance(
  .imm0(imm0), .imm1(imm1),
  .en_rx0(en_rx0), .addrx0(reg_read_addrx0), .datax0(read_datax0), .tagx0(read_lockx0),
  .en_ry0(en_ry0), .addry0(reg_read_addry0), .datay0(read_datay0), .tagy0(read_locky0),
  .en_rx1(en_rx1), .addrx1(reg_read_addrx1), .datax1(read_datax1), .tagx1(read_lockx1),
  .en_ry1(en_ry1), .addry1(reg_read_addry1), .datay1(read_datay1), .tagy1(read_locky1),
  
  .en_rw0(en_w0), .addrw0(reg_write_addr0), .tagw0(write_lock0),
  .en_rw1(en_w1), .addrw1(reg_write_addr1), .tagw1(write_lock1),

  .en_w0(regs_enw0), .reg_write_addr0(regs_waddr0), .write_data0(regs_wdata0),
  .en_w1(regs_enw1), .reg_write_addr1(regs_waddr1), .write_data1(regs_wdata1),
  .en_w2(regs_enw2), .reg_write_addr2(regs_waddr2), .write_data2(regs_wdata2),

  .en_mod0(mod_enw0), .reg_addr0(mod_addr0), .reg_tag0(mod_tag0),
  // .en_mod1(mod_enw1), .reg_addr1(mod_addr1), .reg_tag1(mod_tag1),

  .clk(clk_in), .rst(rst_in), .rdy(rdy_in)
);

// Allocator
wire `addr_t alu0_pc_out, alu1_pc_out, branch_pc_out;
wire alloc_en0, alloc_en1, alloc_ls_en;
wire`sinst_t alloc_op0, alloc_op1, alloc_ls_op, alloc_branch_op;
wire `regtag_t alloc_tagx0, alloc_tagx1, alloc_ls_tagx, alloc_branch_tagx;
wire `regtag_t alloc_tagy0, alloc_tagy1, alloc_ls_tagy, alloc_branch_tagy;
wire `regtag_t alloc_tagw0, alloc_tagw1, alloc_ls_tagw;
wire `word_t alloc_datax0, alloc_datax1, alloc_ls_datax, alloc_branch_datax;
wire `word_t alloc_datay0, alloc_datay1, alloc_ls_datay, alloc_branch_datay;
wire `regaddr_t alloc_addrw0, alloc_addrw1, alloc_ls_addrw;

// ALU / LS / Branch
wire alu0_busy_upd, alu1_busy_upd, ls_busy_upd, branch_busy_upd;
wire `addr_t alu0_pc_in, alu1_pc_in, branch_pc_in;
wire `word_t alloc_branch_offset, alloc_ls_offset;
wire alu0_next_busy, alu1_next_busy, ls_next_busy, branch_next_busy;
wire `regtag_t alu0_next_tagx, alu0_next_tagy, alu0_next_tagw;
wire `regtag_t alu1_next_tagx, alu1_next_tagy, alu1_next_tagw;

allocator allocator_instance(
  .op0_in(op0), .pc0_in(alloc_pc0), 
  .imm0_in(imm0), .datax0_in(read_datax0), .datay0_in(read_datay0),
  .tagx0_in(read_lockx0), .tagy0_in(read_locky0), .tagw0_in(write_lock0),
  .addrw0_in(reg_write_addr0),

  .op1_in(op1), .pc1_in(alloc_pc1), 
  .imm1_in(imm1), .datax1_in(read_datax1), .datay1_in(read_datay1),
  .tagx1_in(read_lockx1), .tagy1_in(read_locky1), .tagw1_in(write_lock1),
  .addrw1_in(reg_write_addr1),

  .alu0_busy_in(alu0_next_busy), 
  .alu1_busy_in(alu1_next_busy), 
  .ls_busy_in(ls_next_busy), 
  .branch_busy_in(branch_next_busy),

  .alu0_pc_out(alu0_pc_in), .alu0_en_out(alloc_en0), .alu0_op_out(alloc_op0), 
  .alu0_tagx_out(alloc_tagx0), .alu0_tagy_out(alloc_tagy0), .alu0_tagw_out(alloc_tagw0),
  .alu0_datax_out(alloc_datax0), .alu0_datay_out(alloc_datay0), .alu0_addrw_out(alloc_addrw0),

  .alu1_pc_out(alu1_pc_in), .alu1_en_out(alloc_en1), .alu1_op_out(alloc_op1), 
  .alu1_tagx_out(alloc_tagx1), .alu1_tagy_out(alloc_tagy1), .alu1_tagw_out(alloc_tagw1),
  .alu1_datax_out(alloc_datax1), .alu1_datay_out(alloc_datay1), .alu1_addrw_out(alloc_addrw1),
  
  .ls_en_out(alloc_ls_en), .ls_op_out(alloc_ls_op), .ls_offset_out(alloc_ls_offset),
  .ls_tagx_out(alloc_ls_tagx), .ls_tagy_out(alloc_ls_tagy), .ls_tagw_out(alloc_ls_tagw),
  .ls_datax_out(alloc_ls_datax), .ls_datay_out(alloc_ls_datay), .ls_addrw_out(alloc_ls_addrw),

  .branch_pc_out(branch_pc_in), .branch_en_out(alloc_branch_en), 
  .branch_offset_out(alloc_branch_offset), .branch_op_out(alloc_branch_op),
  .branch_tagx_out(alloc_branch_tagx), .branch_tagy_out(alloc_branch_tagy),
  .branch_datax_out(alloc_branch_datax), .branch_datay_out(alloc_branch_datay),

  .en_mw0(regs_enw0), .reg_write_addr0(regs_waddr0), .write_data0(regs_wdata0),
  .en_mw1(regs_enw1), .reg_write_addr1(regs_waddr1), .write_data1(regs_wdata1),
  .en_mw2(regs_enw2), .reg_write_addr2(regs_waddr2), .write_data2(regs_wdata2),

  .en_mod0(mod_enw0), .reg_addr0(mod_addr0), .reg_tag0(mod_tag0),
  
  .issue0(issue0), .issue1(issue1),
  .clk(clk_in), .rst(rst_in), .rdy(rdy_in)
);

// rs_alu
rs_alu rs_alu_instance(
  // From allocator
  .pc0(alu0_pc_in),
  .en0(alloc_en0), .op0(alloc_op0),
  .tagx0(alloc_tagx0), .tagy0(alloc_tagy0), .tagw0(alloc_tagw0),
  .datax0(alloc_datax0), .datay0(alloc_datay0), .addrw0(alloc_addrw0),

  .pc1(alu1_pc_in),
  .en1(alloc_en1), .op1(alloc_op1),
  .tagx1(alloc_tagx1), .tagy1(alloc_tagy1), .tagw1(alloc_tagw1),
  .datax1(alloc_datax1), .datay1(alloc_datay1), .addrw1(alloc_addrw1),

  .en_alu0(regs_enw0), .busy_alu0(alu0_busy_upd), .alu_data0(regs_wdata0),
  .en_alu1(regs_enw1), .busy_alu1(alu1_busy_upd), .alu_data1(regs_wdata1),
  .en_ls(regs_enw2), .busy_ls(ls_busy_upd), .ls_data(regs_wdata2),

  .alu0_next_busy(alu0_next_busy),
  .alu1_next_busy(alu1_next_busy),
  
  .alu_pc0_out(alu0_pc_out),
  .alu_busy0_out(alu0_busy_in), .alu_op0_out(alu0_op_in),
  .alu_tagx0_out(alu0_tagx_in), .alu_tagy0_out(alu0_tagy_in), .alu_tagw0_out(alu0_tagw_in),
  .alu_datax0_out(alu0_datax_in), .alu_datay0_out(alu0_datay_in), .alu_target0_out(alu0_target_in),

  .alu_pc1_out(alu1_pc_out),
  .alu_busy1_out(alu1_busy_in), .alu_op1_out(alu1_op_in),
  .alu_tagx1_out(alu1_tagx_in), .alu_tagy1_out(alu1_tagy_in), .alu_tagw1_out(alu1_tagw_in),
  .alu_datax1_out(alu1_datax_in), .alu_datay1_out(alu1_datay_in), .alu_target1_out(alu1_target_in),

  .clk(clk_in), .rst(rst_in), .rdy(rdy_in)
);

//rs_ls
rs_ls rs_ls_instance(
  .en(alloc_ls_en), .op(alloc_ls_op), .imm(alloc_ls_offset),
  .tagx(alloc_ls_tagx), .tagy(alloc_ls_tagy), .tagw(alloc_ls_tagw),
  .datax(alloc_ls_datax), .datay(alloc_ls_datay), .addrw(alloc_ls_addrw),

  .en_alu0(regs_enw0), .busy_alu0(alu0_busy_upd), .alu_data0(regs_wdata0),
  .en_alu1(regs_enw1), .busy_alu1(alu1_busy_upd), .alu_data1(regs_wdata1),
  .en_ls(regs_enw2), .busy_ls(ls_busy_upd), .ls_data(regs_wdata2),

  .ls_next_busy(ls_next_busy), 
  .ls_busy_out(ls_busy_in), .ls_offset_out(ls_offset_in), .ls_op_out(ls_op_in),
  .ls_tagx_out(ls_tagx_in), .ls_tagy_out(ls_tagy_in), .ls_tagw_out(ls_tagw_in),
  .ls_datax_out(ls_datax_in), .ls_datay_out(ls_datay_in), .ls_target_out(ls_target_in),

  //.enw2(mod_enw2), .regaddr2(mod_addr2), .regtag2(mod_tag2),

  .clk(clk_in), .rst(rst_in), .rdy(rdy_in)
);

rs_branch rs_branch_instance(
  .pc(branch_pc_in), .en(alloc_branch_en), .op(alloc_branch_op), 
  .imm(alloc_branch_offset), .tagx(alloc_branch_tagx), .tagy(alloc_branch_tagy), 
  .datax(alloc_branch_datax), .datay(alloc_branch_datay), 

  .en_alu0(regs_enw0), .busy_alu0(alu0_busy_upd), .alu_data0(regs_wdata0),
  .en_alu1(regs_enw1), .busy_alu1(alu1_busy_upd), .alu_data1(regs_wdata1),
  .en_ls(regs_enw2), .busy_ls(ls_busy_upd), .ls_data(regs_wdata2),
  .busy_branch(branch_busy_upd),

  .pc_out(branch_pc_out), .branch_busy_out(branch_busy_in),
  .branch_offset_out(branch_offset_in), .branch_op_out(branch_op_in), 
  .branch_tagx_out(branch_tagx_in), .branch_tagy_out(branch_tagy_in),
  .branch_datax_out(branch_datax_in), .branch_datay_out(branch_datay_in),
  .branch_next_busy(branch_next_busy),

  .clk(clk_in), .rst(rst_in), .rdy(rdy_in)
);

ex_alu ex_alu_master(
  .pc_in(alu0_pc_out),
  .alu_busy_in(alu0_busy_in), .alu_op_in(alu0_op_in),
  .alu_tagx_in(alu0_tagx_in), .alu_tagy_in(alu0_tagy_in), .alu_tagw_in(alu0_tagw_in),
  .alu_datax_in(alu0_datax_in), .alu_datay_in(alu0_datay_in), .alu_target_in(alu0_target_in),

  .alu_busy_out(alu0_busy_upd),

  .en(regs_enw0), .target_out(regs_waddr0), .data_out(regs_wdata0),

  .en_jmp(en_jmp0), .jmp_addr(jmp_addr0), 
  .clk(clk_in), .rdy(rdy_in)
);

ex_alu ex_alu_salver(
  .pc_in(alu1_pc_out),
  .alu_busy_in(alu1_busy_in), .alu_op_in(alu1_op_in),
  .alu_tagx_in(alu1_tagx_in), .alu_tagy_in(alu1_tagy_in), .alu_tagw_in(alu1_tagw_in),
  .alu_datax_in(alu1_datax_in), .alu_datay_in(alu1_datay_in), .alu_target_in(alu1_target_in),

  .alu_busy_out(alu1_busy_upd),

  .en(regs_enw1), .target_out(regs_waddr1), .data_out(regs_wdata1),

  .en_jmp(en_jmp1), .jmp_addr(jmp_addr1),  
  .clk(clk_in), .rdy(rdy_in)
);

ex_ls ex_ls_instance(
  .offset_in(ls_offset_in), .ls_busy_in(ls_busy_in), .ls_op_in(ls_op_in),
  .ls_tagx_in(ls_tagx_in), .ls_tagy_in(ls_tagy_in), .ls_tagw_in(ls_tagw_in),
  .ls_datax_in(ls_datax_in), .ls_datay_in(ls_datay_in), .ls_target_in(ls_target_in),

  .ls_busy_out(ls_busy_upd),

  .en(regs_enw2), .target_out(regs_waddr2), .data_out(regs_wdata2),

  .en_ls(cache_en_ls), 
  .ls_oper(cache_ls_oper),
  .ls_addr(cache_ls_addr), 
  .ls_size(cache_ls_size),
  .ls_data(cache_ls_data), 

  .in_fifo_in(cache_in_fifo), 
  .finish(cache_finish),
  .ls_data_in(cache_data_out),

  .clk(clk_in), .rst(rst_in), .rdy(rdy_in)
);

ex_branch ex_branch_instance(
  .pc_in(branch_pc_out), .offset_in(branch_offset_in),
  .branch_busy_in(branch_busy_in), .branch_op_in(branch_op_in),
  .branch_tagx_in(branch_tagx_in), .branch_tagy_in(branch_tagy_in),
  .branch_datax_in(branch_datax_in), .branch_datay_in(branch_datay_in),

  .branch_busy_out(branch_busy_upd), 

  .en(en_branch), .dest_out(result), 
  .clk(clk_in), .rdy(rdy_in)
);

endmodule