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

    // To Decoder
    output reg `inst_t pc0_out,
    output reg `inst_t pc1_out,
    output reg hitx_out,
    output reg hity_out,
    output reg `word_t instx_out,
    output reg `word_t insty_out
);

reg `addr_t pcx, pcy;
wire en_jmp;
wire `addr_t jmp_addr;

assign en_jmp = en_jmp0 & en_jmp1;
assign en_addr = en_jmp0 ? jmp_addr0: jmp_addr1;
assign en_rx_out = 1;
assign en_ry_out = 1;
assign pcx_out = pcx;
assign pcy_out = pcy;

`define REV(inst) {inst[7 : 0], inst[15 : 8], inst[23: 16], inst[31 : 24]}
always @(posedge clk) begin
    if (rst) begin
        pcx <= 0;
        pcy <= 4;
    end else if (rdy) begin
        pc0_out <= pcx;
        pc1_out <= pcy;
        if (hitx) begin
            hitx_out  <= 1;
            instx_out <= `REV(instx);
            if (hity) begin
                hity_out  <= 1;
                insty_out <= `REV(insty);
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
            hitx_out <= 0;
            hity_out <= 0;
        end
    end
end
endmodule // cpu_if