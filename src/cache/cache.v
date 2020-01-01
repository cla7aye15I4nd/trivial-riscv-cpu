module cache #(
    parameter LINE_WIDTH  = 32,
    parameter BLOCK_WIDTH = 6,
    parameter ADDR_WIDTH = 13,
    parameter BLOCK_SIZE  = 2**BLOCK_WIDTH,
    parameter TAG_WIDTH   = ADDR_WIDTH - BLOCK_WIDTH - 2,
    parameter QUEEN_SIZE  = 16
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
    output reg finish,
    output wire `word_t qsize,
    output reg `word_t ls_data_out,
    output reg `word_t stk_data_out,
    
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

wire instk;
wire [`STK - 1 : 0] line_index;
reg `byte_t stk[0: `STKSIZE - 1];

assign line_index    = ls_addr[`STK - 1 : 0];
assign instk = ls_addr[16 : `STK] == {(17 - `STK){1'b1}};

reg [0 : BLOCK_SIZE-1] ivalid0, ivalid1, irouter;
reg [TAG_WIDTH - 1: 0]  itag0[0 : BLOCK_SIZE-1];
reg [TAG_WIDTH - 1: 0]  itag1[0 : BLOCK_SIZE-1];
reg [LINE_WIDTH - 1: 0] idata0[0 : BLOCK_SIZE-1];
reg [LINE_WIDTH - 1: 0] idata1[0 : BLOCK_SIZE-1];

reg `addr_t instx_addr, insty_addr;
reg  [BLOCK_WIDTH - 1 : 0] addr_index;

// load / store
reg [3 : 0] head, tail;
reg `word_t count_add, count_del;
reg         data_oper[0 : QUEEN_SIZE-1];
reg `addr_t data_addr[0 : QUEEN_SIZE-1];
reg `byte_t data_size[0 : QUEEN_SIZE-1];
reg `word_t data_data[0 : QUEEN_SIZE-1];

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

assign hitx0 = ivalid0[pcx_index] && itag0[pcx_index] == pcx_tag;
assign hitx1 = ivalid1[pcx_index] && itag1[pcx_index] == pcx_tag;
assign hity0 = ivalid0[pcy_index] && itag0[pcy_index] == pcy_tag;
assign hity1 = ivalid1[pcy_index] && itag1[pcy_index] == pcy_tag;

assign qsize = count_add - count_del;

`define REV(inst) {inst[7 : 0], inst[15 : 8], inst[23: 16], inst[31 : 24]}

integer i;
wire `word_t mem_data;
assign mem_data = data_in;

wire `byte_t byte0 = stk[line_index|0];
wire `byte_t byte1 = stk[line_index|1];
wire `byte_t byte2 = stk[line_index|2];
wire `byte_t byte3 = stk[line_index|3];

always @(*) begin
    if (~en_ls) begin
        stk_data_out = 0;
    end else if (ls_size == 1) begin
        stk_data_out = byte0;
    end else if(ls_size == 2) begin
        stk_data_out = {byte0, byte1};
    end else if (ls_size == 4) begin
        stk_data_out = {byte0, byte1, byte2, byte3};
    end else begin
        stk_data_out = 0;
    end
end 

always @(posedge clk) begin
    if (rst || ~rdy) begin
        hitx <= 0;
        hity <= 0;
        instx <= `OP_NOP;
        insty <= `OP_NOP;
        ivalid0 <= 0;
        ivalid1 <= 0;
        irouter  <= 0;
        instx_addr <= `NULL_PTR;
        insty_addr <= `NULL_PTR;
        addr0 <= `NULL_PTR;
        addr1 <= `NULL_PTR;
        head  <= 0;
        tail  <= 0;
        count_add <= 0;
        count_del <= 0;
    end else begin
        hitx <= hitx0 | hitx1;
        hity <= hity0 | hity1;
        instx <= hitx0? idata0[pcx_index]: hitx1 ? idata1[pcx_index]: `OP_NOP;
        insty <= hity0? idata0[pcy_index]: hity1 ? idata1[pcy_index]: `OP_NOP;

        if (~hitx0 && ~hitx1 && addr0[12 : 2] != pcx[12 : 2] && addr1[12 : 2] != pcx[12 : 2]) instx_addr <= pcx;
        if (~hity0 && ~hity1 && addr0[12 : 2] != pcy[12 : 2] && addr1[12 : 2] != pcy[12 : 2]) insty_addr <= pcy;

        if (en_ls) begin    
            $display("%x", ls_addr);        
            if (instk) begin                
                if (ls_oper == `WRITE_SIGNAL) begin
                    if (ls_size == 1) begin
                        stk[line_index]   <= ls_data[7 : 0];
                    end else if(ls_size == 2) begin
                        stk[line_index]   <= ls_data[7 : 0];
                        stk[line_index+1] <= ls_data[15 : 8];
                    end else if (ls_size == 4) begin
                        stk[line_index]   <= ls_data[7 : 0];
                        stk[line_index+1] <= ls_data[15 : 8];
                        stk[line_index+2] <= ls_data[23 : 16];
                        stk[line_index+3] <= ls_data[31 : 24];
                    end
                end
            end else begin
                data_oper[head] <= ls_oper;
                data_addr[head] <= ls_addr;
                data_size[head] <= ls_size;
                data_data[head] <= ls_data;
                head <= head + 1;
                count_add <= count_add + 1;
            end
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
            end else if (count_add != count_del) begin
                if (addr1 != `NULL_PTR) begin
                    addr1 <= `NULL_PTR;
                    addr_out <= 0;
                    r_nw_out <= `READ_SIGNAL;
                end else begin
                    save1 <= 0;
                    addr1 <= data_addr[tail];
                    oper1 <= data_oper[tail];
                    size1 <= data_size[tail];
                    data1 <= data_data[tail][31 : 8];
                    r_nw_out <= data_oper[tail];
                    addr_out <= data_addr[tail];
                    data_out <= data_data[tail][7 : 0];
                    tail <= tail + 1;
                    count_del <= count_del + 1;
                end
            end else if (en_ls && ~instk) begin
                if (addr1 != `NULL_PTR) begin
                    addr1 <= `NULL_PTR;
                    addr_out <= 0;
                    r_nw_out <= `READ_SIGNAL;
                end else begin
                    save1 <= 0;
                    addr1 <= ls_addr;
                    oper1 <= ls_oper;
                    size1 <= ls_size;
                    data1 <= ls_data[31 : 8];
                    r_nw_out <= ls_oper;
                    addr_out <= ls_addr;
                    data_out <= ls_data[7 : 0];
                    tail <= tail + 1;
                    count_del <= count_del + 1;
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
                    if (~ivalid0[sindex] || ~irouter[sindex]) begin
                        ivalid0[sindex] <= 1;
                        itag0[sindex] <= stag;
                        idata0[sindex] <= {data, data_in};
                    end else begin
                        ivalid1[sindex] <= 1;
                        itag1[sindex] <= stag;
                        idata1[sindex] <= {data, data_in};
                    end
                    irouter[sindex] <= irouter[sindex] ^ 1;
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