module cpu_if(
    input wire clk,
    input wire rdy,
    input wire rst,
    
    // From Icache
    input wire hitx,
    // input wire hity,
    input wire `word_t instx,
    // input wire `word_t insty,

    // To Icache
    output wire en_rx_out,
    output wire `addr_t pcx_out,
    output wire en_ry_out,
    output wire `addr_t pcy_out,

    // From alu
    input wire en_jmp0,
    input wire `addr_t jmp_addr0,
    input wire en_jmp1,
    input wire `addr_t jmp_addr1,

    // From branch`
    input wire en_branch,
    input wire `addr_t result,
    
    // To Decoder
    input wire issue0,
    output reg hitx_out,
    output reg `addr_t pc0_out,    
    output reg `word_t instx_out,

    output reg `word_t inst_count
    // input wire issue1,
    // output reg hity_out,
    // output reg `addr_t pc1_out,
    // output reg `word_t insty_out
);

reg jmp_stall;
reg branch_mode;
reg `addr_t pcx, pcy;

wire en_jmp;
wire is_jmp0;
wire `word_t offset;
wire `addr_t jmp_addr;

assign en_rx_out = 1;
assign en_ry_out = 1;
assign pcx_out = pcx;
assign pcy_out = pcy;

`define REV(inst) {inst[7 : 0], inst[15 : 8], inst[23: 16], inst[31 : 24]}

// JUMP
assign en_jmp = en_jmp0 | en_jmp1;
assign jmp_addr = en_jmp0 ? jmp_addr0: jmp_addr1;

assign is_jumpx0 = ~branch_mode && ~jmp_stall && hitx && instx[30 : 24] == 7'b1101111;
assign is_jumpy0 = instx[30 : 24] == 7'b1100111 && instx[22 : 20] == 3'b000;
assign offset = is_jumpx0 ? {instx[7 : 7], instx[11 : 8], instx[23 : 20], instx[12 : 12], instx[6 : 0], instx[15 : 14], 2'b0}: 4;
assign is_jmp0 = ~branch_mode && ~jmp_stall && hitx && is_jumpy0;

// BRANCH
assign is_branch0 = hitx && instx[30 : 24] == 7'b1100011;

reg issue0_s, en_branch_s;
reg `word_t result_s;
reg stall;

always @(posedge clk) begin
    issue0_s <= issue0;
    en_branch_s <= en_branch;
    result_s <= result;
end

always @(negedge clk) begin
    if (rst || ~rdy) begin
        branch_mode <= 0;
        jmp_stall <= 0;
        pcx <= 0;
        pcy <= 4;
        hitx_out <= 0;
        inst_count <= 0;
        stall = 0;
    end else begin
        if (en_branch_s) begin
            branch_mode <= 0;
            pc0_out <= result_s;
            pcx <= result_s;
            pcy <= result_s + 4;
            hitx_out <= 0;
        end else if (en_jmp) begin
            jmp_stall <= 0;
            pc0_out <= jmp_addr;
            pcx <= jmp_addr;
            pcy <= jmp_addr + 4;
            hitx_out <= 0;
        end else if (issue0_s) begin
            pc0_out <= pcx;
            if (hitx) begin                
                pcx <= pcx + offset;
                pcy <= pcx + offset + 4;
                instx_out <= `REV(instx);  
                if (jmp_stall || branch_mode || stall) begin
                    hitx_out <= 0;
                end else begin
                    hitx_out  <= 1;
                    inst_count <= inst_count + 1;                                         
                    branch_mode <= is_branch0;
                    jmp_stall <= is_jmp0;
                    stall <= pcx == 20;
                end
            end else begin
                hitx_out <= 0;
            end
        end
    end
end
endmodule // cpu_if