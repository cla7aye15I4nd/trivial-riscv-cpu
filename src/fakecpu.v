// fake cpu for demostrating memory & IO r/w
// will output junk bytes based on memory content

// features used
// - memory read/write
// - input/output
// - halt

module fakecpu(
    input  wire                 clk_in,
    input  wire                 rst_in,
    input  wire                 rdy_in,

    input  wire [ 7:0]          mem_din,
    output wire [ 7:0]          mem_dout,
    output wire [31:0]          mem_a,
    output wire                 mem_wr,

    output wire [31:0]          dbgreg_dout
);

reg[31:0]   q_pc, d_pc;               // fake pc
reg[31:0]   q_reg, d_reg;             // fake register
reg[31:0]   q_addr, d_addr;
reg[ 7:0]   q_dout, d_dout;
reg         q_wr, d_wr;
reg[ 3:0]   q_stage, d_stage;

localparam      S_T0    = 4'h0;
localparam      S_T1    = 4'h1;
localparam      S_T2    = 4'h2;
localparam      S_T3    = 4'h3;
localparam      S_T4    = 4'h4;
localparam      S_T5    = 4'h5;
localparam      S_T6    = 4'h6;
localparam      S_T7    = 4'h7;
localparam      S_T8    = 4'h8;

always @(posedge clk_in) begin
  if (rst_in)
    begin
      q_pc        <= 32'h00000000;
      q_reg       <= 32'h00000000;
      q_addr      <= 32'h00000000;
      q_dout      <= 32'h00000000;
      q_wr        <= 1'b0;
      q_stage     <= S_T1;
    end
  else if (rdy_in)
    begin
      q_pc        <= d_pc;
      q_reg       <= d_reg;
      q_addr      <= d_addr;
      q_dout      <= d_dout;
      q_wr        <= d_wr;
      q_stage     <= d_stage;
    end
  else
    begin
      q_pc        <= q_pc;
      q_reg       <= q_reg;
      q_addr      <= q_addr;
      q_dout      <= q_dout;
      q_wr        <= q_wr;
      q_stage     <= q_stage;
    end
end

always @(*) begin
  d_stage = S_T0;
  d_reg = q_reg;
  d_pc = q_pc;
  d_dout = 8'h00;
  d_wr = 1'b0;
  d_addr = 32'h00000000;

  case (q_stage)
    S_T0:
      d_stage = S_T1;
    S_T1:                         // memory read: address = pc
      begin
        d_addr = q_pc;
        d_stage = S_T2;
      end
    S_T2:                         // waiting data
      begin
        d_stage = S_T3;
      end
    S_T3:                         // data fetched, reading from input
      begin
        d_reg = mem_din;
        d_addr = 32'h00030000;
        d_stage = S_T4;
      end
    S_T4:                         // waiting data
      begin
        d_stage = S_T5;
      end
    S_T5:                         // data fetched
      begin
        // d_reg = q_reg + mem_din;  // will read 8'hxx in simulation
        d_reg = q_reg + 1'b1;
        d_stage = S_T6;
      end
    S_T6:
      begin                       // write to output
        d_addr = 32'h00030000;
        d_dout = {2'b00, q_reg[5:0]} + 8'h30;
        d_wr = 1'b1;
        d_stage = S_T7;
      end
    S_T7:                         // memory write: address = pc
      begin
        d_addr = q_pc;
        d_dout = {q_reg[6:0],1'b1};
        d_wr = 1'b1;
        d_stage = S_T8;
      end
    S_T8:                         // halt on reaching memory limit, else increase pc
      begin
        if (q_pc==32'h00020000)
          begin
            d_addr = 32'h00030004;
            d_wr = 1'b1;
          end
        else
          begin
            d_pc = q_pc + 4'h4;
          end
        d_stage = S_T1;
      end
  endcase
end

assign mem_a = q_addr;
assign mem_dout = q_dout;
assign mem_wr = q_wr;
assign dbgreg_dout = q_pc;

endmodule
