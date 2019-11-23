module cpu_if(
    input wire clk,
    input wire rdy,
    input wire rst,
    
    input wire hitx,
    input wire hity,
    input wire `word_t instx,
    input wire `word_t insty,

    output wire en_rx_out,
    output wire en_ry_out,
    output wire `addr_t pcx_out,
    output wire `addr_t pcy_out,

    output reg `inst_t pc0_out,
    output reg `inst_t pc1_out,
    output reg hitx_out,
    output reg hity_out,
    output reg `word_t instx_out,
    output reg `word_t insty_out
);

reg `addr_t pcx, pcy;

assign en_rx = 1;
assign en_ry = 1;
assign pcx_out = pcx;
assign pcy_out = pcy;

always @(posedge clk) begin
    if (rst) begin
        pcx <= 0;
        pcy <= 4;
    end else if (rdy) begin
        pc0_out <= pcx;
        pc1_out <= pcy;
        if (hitx) begin
            hitx_out  <= 1;
            instx_out <= instx;
            if (hity) begin
                hity_out  <= 1;
                insty_out <= insty;
                pcx <= pcx + 8;
                pcy <= pcy + 8;
            end else begin
                hity_out  <= 0;
                pcx <= pcx + 4;
                pcy <= pcy + 4;
            end
        end else begin
            hitx_out <= 0;
            hity_out <= 0;
        end
    end
end
endmodule // cpu_if