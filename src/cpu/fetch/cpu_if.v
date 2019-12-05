module cpu_if(
    input wire clk,
    input wire rdy,
    input wire rst,
    
    // From Icache
    input wire hitx,
    input wire hity,
    input wire `word_t instx,
    input wire `word_t insty,

    // To Icache
    output wire en_rx_out,
    output wire en_ry_out,
    output wire `addr_t pcx_out,
    output wire `addr_t pcy_out,

    // From alu
    input wire en_jmp0,
    input wire `addr_t jmp_addr0,
    input wire en_jmp1,
    input wire `addr_t jmp_addr1,

    // From branch`
    input wire en_branch,
    input wire `addr_t result,
    output reg `word_t predict,
    output reg branch_mode,

    // To Decoder
    input wire issue0, issue1,
    output reg `inst_t pc0_out,
    output reg `inst_t pc1_out,
    output reg hitx_out,
    output reg hity_out,
    output reg `word_t instx_out,
    output reg `word_t insty_out
);

reg jmp_stall;
wire is_jmp0, is_jmp1;
reg `addr_t pcx, pcy;
wire en_jmp;
wire `addr_t jmp_addr;

wire `word_t offset;

assign en_rx_out = 1;
assign en_ry_out = 0;
assign pcx_out = pcx;
assign pcy_out = pcy;

// JUMP
assign en_jmp = en_jmp0 | en_jmp1;
assign jmp_addr = en_jmp0 ? jmp_addr0: jmp_addr1;
assign is_jmp0 = ~branch_mode && ~jmp_stall && hitx && (instx[30 : 24] == 7'b1101111 || (instx[30 : 24] == 7'b1100111 && instx[22 : 20] == 3'b000)) ? 1 : 0;
assign is_jmp1 = ~branch_mode && ~jmp_stall && hity && (insty[30 : 24] == 7'b1101111 || (insty[30 : 24] == 7'b1100111 && insty[22 : 20] == 3'b000)) ? 1 : 0;

// BRANCH
assign is_branch0 = hitx && instx[30 : 24] == 7'b1100011;
assign is_branch1 = hity && insty[30 : 24] == 7'b1100011;
// assign offset0 = {instx[]};

`define REV(inst) {inst[7 : 0], inst[15 : 8], inst[23: 16], inst[31 : 24]}

always @(negedge clk) begin
    if (rst) begin
        branch_mode <= 0;
        jmp_stall <= 0;
        pcx <= 0;
        pcy <= 4;
    end else if (rdy) begin
        if (en_branch) begin
            branch_mode <= 0;
            pc0_out <= result;
            pc1_out <= result + 4;
            pcx <= result;
            pcy <= result + 4;
            instx_out <= `OP_NOP;
            insty_out <= `OP_NOP;
        end else if (en_jmp) begin
            jmp_stall <= 0;
            pc0_out <= jmp_addr;
            pc1_out <= jmp_addr + 4;
            pcx <= jmp_addr;
            pcy <= jmp_addr + 4;
            instx_out <= `OP_NOP;
            insty_out <= `OP_NOP;
        end else begin
            if (issue0) begin
                if (issue1) begin
                    pc0_out <= pcx;
                    pc1_out <= pcy;
                    if (hitx) begin
                        hitx_out  <= 1;
                        if (jmp_stall || branch_mode) begin
                            instx_out <= `OP_NOP;
                        end else begin
                            instx_out <=  `REV(instx);
                            //predict   <= is_branch0 ? pcx + 4 : `ZERO;
                            branch_mode <= is_branch0 ? 1: 0;
                        end
                        if (hity) begin
                            // useless now
                            hity_out  <= 1;
                            insty_out <= (is_jmp0 || jmp_stall) ? `OP_NOP : `REV(insty);
                            pcx <= pcx + 8;
                            pcy <= pcy + 8;
                        end else begin
                            hity_out  <= 0;
                            insty_out <= `OP_NOP;
                            pcx <= pcx + 4;
                            pcy <= pcy + 4;
                        end
                    end else begin
                        instx_out <= `OP_NOP;
                        insty_out <= `OP_NOP;
                        hitx_out <= 0;
                        hity_out <= 0;
                    end
                    if (jmp_stall == 0 && (is_jmp0 || is_jmp1)) begin
                        jmp_stall <= 1;
                    end
                end else begin
                    /* no */
                end
            end else begin
                /* just reamin | do nothing */
            end
        end
    end
end
endmodule // cpu_if