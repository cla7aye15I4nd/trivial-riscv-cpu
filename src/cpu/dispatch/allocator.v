`define INST_PORT_DEF(op, en_rx, en_ry, en_w, read_lockx, read_locky, read_datax, read_datay, read_addrx, read_addry, write_lock, write_addr)  \
    input wire `oper_t op,              \
    input wire en_rx,                   \
    input wire en_ry,                   \
    input wire en_w,                    \
    input wire `regtag_t  read_lockx,   \
    input wire `regtag_t  read_locky,   \
    input wire `regtag_t  write_lock,   \
    input wire `word_t read_datax,      \
    input wire `word_t read_datay,      \
    input wire `regaddr_t read_addrx,   \
    input wire `regaddr_t read_addry,   \
    input wire `regaddr_t write_addr,

`define MODIFY_VAR_DEF(en_w, addr, tag)     \
    output reg en_w,                        \
    output reg `regaddr_t addr,             \
    output reg `regtag_t tag,               

module allocator(
    input wire `addr_t pc0_in,
    input wire `addr_t pc1_in,

    `INST_PORT_DEF(
        op0, en_rx0, en_ry0, en_w0, 
        read_lockx0, read_locky0, 
        read_datax0, read_datay0, 
        read_addrx0, read_addry0, 
        write_lock0, write_addr0)
    `INST_PORT_DEF(
        op1, en_rx1, en_ry1, en_w1, 
        read_lockx1, read_locky1, 
        read_datax1, read_datay1, 
        read_addrx1, read_addry1, 
        write_lock1, write_addr1)

    // Update Reg State
    `MODIFY_VAR_DEF(en_mw0, maddr0, mtag0)
    `MODIFY_VAR_DEF(en_mw1, maddr1, mtag1)
    
    input wire alu0_busy,
    input wire `regtag_t alu0_tagx_in,
    input wire `regtag_t alu0_tagy_in,
    input wire `regtag_t alu0_tagw_in,

    input wire alu1_busy,
    input wire `regtag_t alu1_tagx_in,
    input wire `regtag_t alu1_tagy_in,
    input wire `regtag_t alu1_tagw_in,

    input wire ls_busy,
    input wire `regtag_t ls_tagx_in,
    input wire `regtag_t ls_tagy_in,
    input wire `regtag_t ls_tagw_in,

    output reg `addr_t alu0_pc_out,
    output reg alu0_en_out,
    output reg `sinst_t alu0_op_out,
    output reg `regtag_t alu0_tagx_out,
    output reg `regtag_t alu0_tagy_out,
    output reg `regtag_t alu0_tagw_out,
    output reg `word_t alu0_datax_out,
    output reg `word_t alu0_datay_out,
    output reg `addr_t alu0_addrw_out,

    output wire `addr_t alu1_pc_out,
    output reg alu1_en_out,
    output reg `sinst_t alu1_op_out,
    output reg `regtag_t alu1_tagx_out,
    output reg `regtag_t alu1_tagy_out,
    output reg `regtag_t alu1_tagw_out,
    output reg `word_t alu1_datax_out,
    output reg `word_t alu1_datay_out,
    output reg `addr_t alu1_addrw_out,

    output reg ls_en_out,
    output reg `sinst_t ls_op_out,
    output reg `regtag_t ls_tagx_out,
    output reg `regtag_t ls_tagy_out,
    output reg `regtag_t ls_tagw_out,
    output reg `word_t ls_datax_out,
    output reg `word_t ls_datay_out,
    output reg `addr_t ls_addrw_out,

    input wire branch_busy,

    input wire clk,
    input wire rst,
    input wire rdy
);

reg [0 : `ALU_CNT + `BRANCH_CNT + `LS_CNT - 1] busy;

integer i;

always @(negedge clk) begin
    if (op0 != `OP_NOP) begin
        case (op0[7 : 4])
        4'b0001, 4'b0010, 4'b0101, 4'b1001: begin
            if (alu0_busy == 0 || 
                (alu0_busy == 1 && alu0_tagx_in == `UNLOCKED 
                                && alu0_tagy_in == `UNLOCKED
                                && alu0_tagw_in == `UNLOCKED)) begin
                alu0_en_out     <= 1;
                alu0_op_out     <= op0[3 : 0];
                alu0_tagx_out   <= read_lockx0; // must exist
                alu0_datax_out  <= read_datax0;
                alu0_tagy_out   <= en_ry0 ? read_locky0: `UNLOCKED;
                alu0_datay_out  <= en_ry0 ? read_datay0: `ZERO_WORD;
                alu0_tagw_out   <= write_lock0; // must exist
                alu0_addrw_out  <= write_addr0;
                alu0_pc_out     <= pc0_in;
                en_mw0 <= 1;
                maddr0 <= write_addr0;
                mtag0  <= `ALU_MASTER;
            end
        end
        4'b0011, 4'b1001: begin
            if (ls_busy == 0 ||
                (ls_busy == 1 && ls_tagx_in == `UNLOCKED
                              && ls_tagy_in == `UNLOCKED
                              && ls_tagw_in == `UNLOCKED)) begin
                ls_en_out     <= 1;
                ls_op_out     <= op0[3 : 0];
                ls_tagx_out   <= read_lockx0; // must exist
                ls_datax_out  <= read_datax0;
                ls_tagy_out   <= en_ry0 ? read_locky0: `UNLOCKED;
                ls_datay_out  <= en_ry0 ? read_datay0: `ZERO_WORD;
                ls_tagw_out   <= write_lock0; // must exist
                ls_addrw_out  <= write_addr0;
                en_mw0 <= op0[7 : 4] == 4'b1001 ? 1 : 0; // LOAD prefix
                maddr0 <= write_addr0;
                mtag0  <= `LOAD_STORE;
            end
        end
        endcase
    end else begin
        en_mw0 <= 0;
        en_mw1 <= 0;
        maddr0 <= `ZERO_WORD;
        maddr1 <= `ZERO_WORD;
        mtag0  <= `ZERO_WORD;
        mtag1  <= `ZERO_WORD;
        alu0_en_out <= 0;
        alu1_en_out <= 0;
    end
end

endmodule // allocator