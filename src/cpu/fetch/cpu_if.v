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
    output reg `word_t instx_out
    // input wire issue1,
    // output reg hity_out,
    // output reg `addr_t pc1_out,
    // output reg `word_t insty_out
);

reg jmp_stall;
reg branch_mode;
reg `addr_t pcx, pcy;

wire is_jmp0;
// wire is_jmp1;
wire en_jmp;
wire `addr_t jmp_addr;

wire `word_t offset;

assign en_rx_out = 1;
assign en_ry_out = 1;
assign pcx_out = pcx;
assign pcy_out = pcy;

// JUMP
assign en_jmp = en_jmp0 | en_jmp1;
assign jmp_addr = en_jmp0 ? jmp_addr0: jmp_addr1;
assign is_jmp0 = ~branch_mode && ~jmp_stall && hitx && (instx[30 : 24] == 7'b1101111 || (instx[30 : 24] == 7'b1100111 && instx[22 : 20] == 3'b000));

// BRANCH
assign is_branch0 = hitx && instx[30 : 24] == 7'b1100011;

`define REV(inst) {inst[7 : 0], inst[15 : 8], inst[23: 16], inst[31 : 24]}

reg issue0_s;
always @(posedge clk) begin
    issue0_s <= issue0;
end

always @(negedge clk) begin
    if (rst || ~rdy) begin
        branch_mode <= 0;
        jmp_stall <= 0;
        pcx <= 0;
        pcy <= 4;
        instx_out <= `OP_NOP;
    end else begin
        if (en_branch) begin
            branch_mode <= 0;
            pc0_out <= result;
            pcx <= result;
            pcy <= result + 4;
            instx_out <= `OP_NOP;
        end else if (en_jmp) begin
            jmp_stall <= 0;
            pc0_out <= jmp_addr;
            pcx <= jmp_addr;
            pcy <= jmp_addr + 4;
            instx_out <= `OP_NOP;
        end else if (issue0_s) begin
            pc0_out <= pcx;
            if (hitx) begin
                hitx_out  <= 1;
                pcx <= pcx + 4;
                pcy <= pcy + 4;
                if (jmp_stall || branch_mode) begin
                    instx_out <= `OP_NOP;
                end else begin
                    instx_out <=  `REV(instx);                 
                    branch_mode <= is_branch0;
                    jmp_stall <= is_jmp0;                   
                end
            end else begin
                instx_out <= `OP_NOP;
                hitx_out <= 0;
            end
        end
    end
end
endmodule // cpu_if