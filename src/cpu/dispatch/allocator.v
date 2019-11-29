module allocator(
    // Waiting alloc
    input wire `oper_t op0_in,
    input wire `addr_t pc1_in,
    input wire en_rx0_in, en_ry0_in, en_w0_in,
    input wire `word_t imm0_in, datax0_in, datay0_in, 
    input wire `regtag_t tagx0_in, tagy0_in, tagw0_in,
    input wire `regaddr_t addrx0_in, addry0_in, addrw0_in,

    input wire `oper_t op1_in,
    input wire `addr_t pc0_in,
    input wire en_rx1_in, en_ry1_in, en_w1_in,
    input wire `word_t imm1_in, datax1_in, datay1_in, 
    input wire `regtag_t tagx1_in, tagy1_in, tagw1_in,
    input wire `regaddr_t addrx1_in, addry1_in, addrw1_in,

    // Update Reg State
    output reg en_mw0, 
    output reg `regtag_t mtag0,
    output reg `regaddr_t maddr0,
    
    output reg en_mw1,
    output reg `regtag_t mtag1,
    output reg `regaddr_t maddr1,
    
    // current alu state
    input wire alu0_busy_in,
    input wire `regtag_t alu0_tagx_in,
    input wire `regtag_t alu0_tagy_in,
    input wire `regtag_t alu0_tagw_in,

    input wire alu1_busy_in,
    input wire `regtag_t alu1_tagx_in,
    input wire `regtag_t alu1_tagy_in,
    input wire `regtag_t alu1_tagw_in,

    input wire ls_busy_in,
    input wire `regtag_t ls_tagx_in,
    input wire `regtag_t ls_tagy_in,
    input wire `regtag_t ls_tagw_in,

    input wire branch_busy_in,
    input wire `regtag_t branch_tagx_in,
    input wire `regtag_t branch_tagy_in,

    // issue
    output reg alu0_en_out,
    output reg `addr_t alu0_pc_out,
    output reg `sinst_t alu0_op_out,
    output reg `regtag_t alu0_tagx_out,
    output reg `regtag_t alu0_tagy_out,
    output reg `regtag_t alu0_tagw_out,
    output reg `word_t alu0_datax_out,
    output reg `word_t alu0_datay_out,
    output reg `regaddr_t alu0_addrw_out,

    output reg alu1_en_out,
    output reg `addr_t alu1_pc_out,
    output reg `sinst_t alu1_op_out,
    output reg `regtag_t alu1_tagx_out,
    output reg `regtag_t alu1_tagy_out,
    output reg `regtag_t alu1_tagw_out,
    output reg `word_t alu1_datax_out,
    output reg `word_t alu1_datay_out,
    output reg `regaddr_t alu1_addrw_out,

    output reg ls_en_out,
    output reg `sinst_t ls_op_out,
    output reg `word_t ls_offset_out,
    output reg `regtag_t ls_tagx_out,
    output reg `regtag_t ls_tagy_out,
    output reg `regtag_t ls_tagw_out,
    output reg `word_t ls_datax_out,
    output reg `word_t ls_datay_out,
    output reg `regaddr_t ls_addrw_out,

    output reg branch_en_out,
    output reg `addr_t branch_pc_out,
    output reg `word_t branch_offset_out,
    output reg `sinst_t branch_op_out,
    output reg `regtag_t branch_tagx_out,
    output reg `regtag_t branch_tagy_out,
    output reg `word_t branch_datax_out,
    output reg `word_t branch_datay_out,

    output reg issue0, issue1,
    input wire clk,
    input wire rst,
    input wire rdy
);

reg `oper_t op0;
reg `addr_t pc0;
reg en_rx0, en_ry0, en_w0;
reg `word_t imm0, datax0, datay0;
reg `regtag_t tagx0, tagy0, tagw0;
reg `regaddr_t addrx0, addry0, addrw0;

reg `oper_t op1;
reg `addr_t pc1;
reg en_rx1, en_ry1, en_w1;
reg `word_t imm1, datax1, datay1;
reg `regtag_t tagx1, tagy1, tagw1;
reg `regaddr_t addrx1, addry1, addrw1;

always @(negedge clk) begin
    if (rst) begin
        issue0 <= 1;
        issue1 <= 1;
    end else begin
        if (issue0) begin
            op0 <= op0_in;
            pc0 <= pc0_in;
            {en_rx0, en_ry0, en_w0} <= {en_rx0_in, en_ry0_in, en_w0_in};
            {imm0, datax0, datay0} <= {imm0_in, datax0_in, datay0_in};
            {tagx0, tagy0, tagw0} <= {tagx0_in, tagy0_in, tagw0_in};
            {addrx0, addry0, addrw0} <= {addrx0_in, addry0_in, addrw0_in};

            if (issue1) begin 
                op1 <= op1_in;
                pc1 <= pc1_in;
                {en_rx1, en_ry1, en_w1} <= {en_rx1_in, en_ry1_in, en_w1_in};
                {imm1, datax1, datay1} <= {imm1_in, datax1_in, datay1_in};
                {tagx1, tagy1, tagw1} <= {tagx1_in, tagy1_in, tagw1_in};
                {addrx1, addry1, addrw1} <= {addrx1_in, addry1_in, addrw1_in};
            end
        end
    end
end

always @(*) begin
    case (op0[7 : 4])
    4'b0001, 4'b0010, 4'b0101, 4'b1101: begin
        if (alu0_busy_in == 0 || {alu0_busy_in, alu0_tagx_in, alu0_tagy_in, alu0_tagw_in} == {1'b1, {3{`UNLOCKED}}}) begin
            issue0          = 1;
            alu0_op_out     = op0[3 : 0];
            alu0_tagx_out   = tagx0; // must exist
            alu0_datax_out  = datax0;
            alu0_tagy_out   = en_ry0 ? tagy0: `UNLOCKED;
            alu0_datay_out  = en_ry0 ? datay0: `ZERO;
            alu0_tagw_out   = tagw0; // must exist
            alu0_addrw_out  = addrw0;
            alu0_pc_out     = pc0_in;
            en_mw0          = 1;
            maddr0          = addrw0;
            mtag0           = `ALU_MASTER;
        end else if (alu1_busy_in == 0 || {alu1_busy_in, alu1_tagx_in, alu1_tagy_in, alu1_tagw_in} == {1'b1, {3{`UNLOCKED}}}) begin
            issue1          = 1;
            alu1_op_out     = op0[3 : 0];
            alu1_tagx_out   = tagx0; // must exist
            alu1_datax_out  = datax0;
            alu1_tagy_out   = en_ry0 ? tagy0: `UNLOCKED;
            alu1_datay_out  = en_ry0 ? datay0: `ZERO;
            alu1_tagw_out   = tagw0; // must exist
            alu1_addrw_out  = addrw0;
            alu1_pc_out     = pc0_in;
            en_mw0          = 1;
            maddr0          = addrw0;
            mtag0           = `ALU_SALVER;
        end else begin
            issue0 = 0;
            en_mw0 = 0;
            mtag0  = `UNLOCKED;
        end
    end
    4'b0011, 4'b1001: begin
        if (ls_busy_in == 0) begin
            issue0        = 1;
            ls_op_out     = op0[3 : 0];
            ls_offset_out = imm0;
            ls_tagx_out   = tagx0; // must exist
            ls_datax_out  = datax0;
            ls_tagy_out   = en_ry0 ? tagy0: `UNLOCKED;
            ls_datay_out  = datay0;
            ls_tagw_out   = op0[7 : 4] == 4'b1001 ? tagw0 : `UNLOCKED;
            ls_addrw_out  = addrw0;
            en_mw0        = op0[7 : 4] == 4'b1001 ? 1 : 0; // LOAD prefix
            maddr0        = addrw0;
            mtag0         = `LOAD_STORE;
        end else begin
            issue0 = 0;
            en_mw0 = 0;
            mtag0  = `UNLOCKED;
        end
    end
    4'b0100: begin 
        if (branch_busy_in == 0 || {branch_busy_in, branch_tagx_in, branch_tagy_in} == {1'b1, {2{`UNLOCKED}}}) begin
            issue0              = 1;
            branch_op_out       = op0[3 : 0];
            branch_offset_out   = imm0;
            branch_tagx_out     = tagx0;
            branch_datax_out    = datax0;
            branch_tagy_out     = tagy0;
            branch_datay_out    = datay0;
            en_mw0              = 0;
            mtag0               = `BRANCH_SEL;  
        end else begin
            issue0 = 0;
            en_mw0 = 0;
            mtag0  = `UNLOCKED;
        end
    end
    4'b1111: begin
        issue0 = 1;
        en_mw0 = 0;
        mtag0  = `UNLOCKED;
    end
    default: begin
        issue0 = 0;
        en_mw0 = 0;
        mtag0  = `UNLOCKED;
    end
    endcase

    alu0_en_out = mtag0 == `ALU_MASTER ? 1: 0;
    alu1_en_out = mtag0 == `ALU_SALVER ? 1: 0;
    ls_en_out   = mtag0 == `LOAD_STORE ? 1: 0;
    branch_en_out=mtag0 == `BRANCH_SEL ? 1: 0;

    /* must clean !!!!! */
    en_mw1 = 0;
    maddr1 = `ZERO;
    mtag1  = `UNLOCKED;
end
endmodule // allocator