module cache #(
    parameter LINE_WIDTH  = 32,
    parameter BLOCK_WIDTH = 6,
    parameter ADDR_WIDTH = 13,
    parameter BLOCK_SIZE  = 2**BLOCK_WIDTH,
    parameter TAG_WIDTH   = ADDR_WIDTH - BLOCK_WIDTH - 2
)(
    input wire clk,
    input wire rst,
    input wire rdy,

    // data
    input wire en_ls,
    input wire         ls_oper,
    input wire `addr_t ls_addr,
    input wire `word_t ls_data,
    input wire `byte_t ls_size,
    output reg in_fifo, finish,
    output reg `word_t ls_data_out,
    
    // Inst
    input wire en_rx,
    input wire `addr_t pcx,
    output reg hitx,
    output reg `word_t instx,

    input wire en_ry,
    input wire `addr_t pcy,
    output reg hity,
    output reg `word_t insty,

    // memory I/O
    input wire `byte_t data_in,
    output reg `byte_t data_out,
    output reg r_nw_out,
    output reg [31 : 0] addr_out
);

reg [0 : BLOCK_SIZE-1] valid0, valid1;
reg [TAG_WIDTH - 1: 0]  tag0[0 : BLOCK_SIZE-1];
reg [TAG_WIDTH - 1: 0]  tag1[0 : BLOCK_SIZE-1];
reg [LINE_WIDTH - 1: 0] idata0[0 : BLOCK_SIZE-1];
reg [LINE_WIDTH - 1: 0] idata1[0 : BLOCK_SIZE-1];

reg `addr_t instx_addr, insty_addr;
reg  [BLOCK_WIDTH - 1 : 0] addr_index;

// load / store
reg         data_oper;
reg `addr_t data_addr;
reg `byte_t data_size;
reg `word_t data_data;

reg         save0, save1;
reg `word_t cont0, cont1;
reg         oper0, oper1;
reg `addr_t addr0, addr1;
reg `word_t size0, size1;
reg `word_t data , data1;

wire [TAG_WIDTH - 1 : 0]   pcx_tag, pcy_tag, stag;
wire [BLOCK_WIDTH - 1 : 0] pcx_index, pcy_index, sindex;
wire hitx0, hitx1, hity0, hity1;

assign sindex = addr0[ADDR_WIDTH-1 - TAG_WIDTH : 2];
assign stag = addr0[ADDR_WIDTH-1 : ADDR_WIDTH - TAG_WIDTH];

assign pcx_index = pcx[ADDR_WIDTH-1 - TAG_WIDTH : 2];
assign pcy_index = pcy[ADDR_WIDTH-1 - TAG_WIDTH : 2];
assign pcx_tag = pcx[ADDR_WIDTH-1 : ADDR_WIDTH - TAG_WIDTH];
assign pcy_tag = pcy[ADDR_WIDTH-1 : ADDR_WIDTH - TAG_WIDTH];

assign hitx0 = valid0[pcx_index] && tag0[pcx_index] == pcx_tag;
assign hitx1 = valid1[pcx_index] && tag1[pcx_index] == pcx_tag;
assign hity0 = valid0[pcy_index] && tag0[pcy_index] == pcy_tag;
assign hity1 = valid1[pcy_index] && tag1[pcy_index] == pcy_tag;

wire `word_t mem_data;
assign mem_data = data_in;

always @(posedge clk) begin
    if (rst || ~rdy) begin
        hitx <= 0;
        hity <= 0;
        instx <= `OP_NOP;
        insty <= `OP_NOP;
        valid0 <= 0;
        valid1 <= 0;
        data_addr <= `NULL_PTR;
        instx_addr <= `NULL_PTR;
        insty_addr <= `NULL_PTR;
        addr0 <= `NULL_PTR;
        addr1 <= `NULL_PTR;
    end else begin
        hitx <= hitx0 | hitx1;
        hity <= hity0 | hity1;
        instx <= hitx0? idata0[pcx_index]: idata1[pcx_index];
        insty <= hity0? idata0[pcy_index]: idata1[pcy_index];

        if (~hitx0 && ~hitx1 && addr0 != pcx && addr1 != pcx && instx_addr == `NULL_PTR) instx_addr <= pcx;
        if (~hity0 && ~hity1 && addr0 != pcy && addr1 != pcy && insty_addr == `NULL_PTR) insty_addr <= pcy;

        if (en_ls && data_addr == `NULL_PTR) begin
            in_fifo   <= 1;
            data_oper <= ls_oper;
            data_addr <= ls_addr;
            data_size <= ls_size;
            data_data <= ls_data;
        end else begin
            in_fifo   <= 0;
        end

        save0 <= save1;
        cont0 <= cont1;
        addr0 <= addr1;
        oper0 <= oper1;
        size0 <= size1;

        if (addr1 != `NULL_PTR && cont1 != size1) begin
            cont1 <= cont1 + 1;
            data1 <= data1[31 : 8];
            addr_out <= addr1 + cont1;
            r_nw_out <= oper1;
            data_out <= data1[7 : 0];
        end else begin
            cont1 <= 1;
            // fetch new addr
            if (addr1[17] == 1'b1 && ~oper1) begin
                addr1 <= `NULL_PTR;
            end else if (data_addr != `NULL_PTR) begin
                if (addr1 != `NULL_PTR) begin
                    addr1 <= `NULL_PTR;
                    addr_out <= 0;
                    r_nw_out <= `READ_SIGNAL;
                end else begin
                    save1 <= 0;
                    addr1 <= data_addr;
                    oper1 <= data_oper;
                    size1 <= data_size;
                    data_addr <= `NULL_PTR;
                    data1 <= data_data[31 : 8];
                    r_nw_out <= data_oper;
                    addr_out <= data_addr;
                    data_out <= data_data[7 : 0];
                end
            end else if (instx_addr != `NULL_PTR) begin
                save1 <= 1;
                addr1 <= instx_addr;
                instx_addr <= `NULL_PTR;
                oper1 <= `READ_SIGNAL;
                size1 <= 4;
                r_nw_out <= `READ_SIGNAL;
                addr_out <= instx_addr;
            end else if (insty_addr != `NULL_PTR) begin
                save1 <= 1;
                addr1 <= insty_addr;
                insty_addr <= `NULL_PTR;
                oper1 <= `READ_SIGNAL;
                size1 <= 4;
                r_nw_out <= `READ_SIGNAL;
                addr_out <= insty_addr;
            end else begin
                addr1 <= `NULL_PTR;
                addr_out <= 0;
                r_nw_out <= `READ_SIGNAL;
            end
        end 
        
        if (addr0 != `NULL_PTR && ~oper0) begin
            data <= {data, data_in};
            if (cont0 == size0) begin
                if (save0) begin
                    if (~valid0[sindex]) begin
                        valid0[sindex] <= 1;
                        tag0[sindex] <= stag;
                        idata0[sindex] <= {data, data_in};
                    end else begin
                        valid1[sindex] <= 1;
                        tag1[sindex] <= stag;
                        idata1[sindex] <= {data, data_in};
                    end
                end else begin
                    ls_data_out <= {data, data_in};      
                end
            end
            finish <= (cont0 == size0 && ~save0) ? ~oper0: 0;
        end else begin
            finish <= 0;
        end
    end
end

endmodule // inst_cache