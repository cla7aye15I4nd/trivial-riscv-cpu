`define REFETCH                                             \
    if (en) begin                                           \
        en         <= 0;                                    \
        mode       <= 1;                                    \
        read_addr  <= data_addr;                            \
        r_nw_out   <= rw_s;                                 \
        read_size  <= data_size;                            \
        addr_out   <= data_addr;                            \
        read_data  <= rw_s ? ls_data_in: `ZERO;             \
        data_addr  <= `NULL_PTR; /* warning */              \
    end else if (instx_addr != `NULL_PTR) begin             \
        mode       <= 0;                                    \
        read_addr_index <= instx_addr[16 - TAG_WIDTH : 2];  \
        read_addr  <= instx_addr;                           \
        r_nw_out   <= `READ_SIGNAL;                         \
        addr_out   <= instx_addr;                           \
        read_data  <= `ZERO;                                \
        instx_addr <= `NULL_PTR; /* warning */              \
    end else if (insty_addr != `NULL_PTR) begin             \
        mode       <= 0;                                    \
        read_addr_index <= insty_addr[16 - TAG_WIDTH : 2];  \
        read_addr  <= insty_addr;                           \
        r_nw_out   <= `READ_SIGNAL;                         \
        addr_out   <= insty_addr;                           \
        read_data  <= `ZERO;                                \
        insty_addr <= `NULL_PTR; /* warning */              \
    end else begin                                          \
        read_addr  <= `NULL_PTR;                            \
        read_data <= `ZERO;                                 \
    end

module cache 
#(
    parameter LINE_WIDTH  = 64,
    parameter BLOCK_WIDTH = 10,
    parameter BLOCK_SIZE  = 1024,
    parameter TAG_WIDTH   = 5
)
(
    input wire clk,
    input wire rst,
    input wire rdy,

    // data
    input wire en_ls,
    input wire r_nw_in,
    input wire `addr_t ls_addr,
    input wire `byte_t ls_size,
    input wire `word_t ls_data_in,

    output reg finish,
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
    output reg `addr_t addr_out
);

reg [TAG_WIDTH - 1: 0]  tag[0 : BLOCK_SIZE-1];
reg [LINE_WIDTH - 1: 0] data[0 : BLOCK_SIZE-1][0 : 1];
reg valid[0 : BLOCK_SIZE-1][0 : 1];
reg `addr_t instx_addr, insty_addr;

wire [TAG_WIDTH - 1 : 0] pcx_tag, pcy_tag;
wire [14 - TAG_WIDTH : 0] pcx_index, pcy_index;
reg [14 - TAG_WIDTH : 0] read_addr_index;

// Instruction fetch
assign pcx_tag = pcx[16 : 17 - TAG_WIDTH];
assign pcy_tag = pcy[16 : 17 - TAG_WIDTH];

assign pcx_index = pcx[16 - TAG_WIDTH : 2];
assign pcy_index = pcy[16 - TAG_WIDTH : 2];

// load / store
reg en, rw_s;
reg `addr_t data_addr;
reg `byte_t data_size;
reg `word_t ls_data;

reg mode; // inst / data
reg `byte_t counter;
reg `addr_t read_addr;
reg `byte_t read_size;
reg `word_t read_data;

wire `byte_t mem_data;
assign mem_data = data_in;
 
 integer i;
always @(posedge clk) begin
    if (rst) begin
        en          <= 0;
        rw_s        <= 0;
        ls_data     <= `ZERO;
        instx_addr  <= `NULL_PTR;
        insty_addr  <= `NULL_PTR;
        data_addr   <= `NULL_PTR;
    end else begin
        if (en_ls && data_addr == `NULL_PTR) begin
            en        <= 1;
            rw_s      <= r_nw_in;
            data_size <= ls_size;
            ls_data   <= rw_s ? ls_data_in: 0;
            if (read_addr != ls_addr)
                data_addr <= ls_addr;
        end

        if (en_rx) begin
            if (pcx != `NULL_PTR) begin
                if (valid[pcx_index][0] && tag[pcx_index][0] == pcx_tag) begin
                    hitx <= 1;
                    instx <= data[pcx_index][0];
                    instx_addr <= `NULL_PTR;
                end else if (valid[pcx_index][1] && tag[pcx_index][1] == pcx_tag) begin
                    hitx <= 1;
                    instx <= data[pcx_index][0];
                    instx_addr <= `NULL_PTR;
                end else begin
                    hitx <= 0;
                    instx <= `ZERO;
                    if (instx_addr == `NULL_PTR && pcx != read_addr)
                        instx_addr <= pcx;
                end
            end
        end

        if (en_ry) begin
            if (pcy != `NULL_PTR) begin
                if (valid[pcy_index][0] && tag[pcy_index][0] == pcy_tag) begin
                    hity <= 1;
                    insty <= data[pcy_index][0];
                    insty_addr <= `NULL_PTR;
                end else if (valid[pcy_index][1] && tag[pcy_index][1] == pcy_tag) begin
                    hity <= 1;
                    insty <= data[pcy_index][0];
                    insty_addr <= `NULL_PTR;
                end else begin
                    hity <= 0;
                    insty <= `ZERO;
                    if (insty_addr == `NULL_PTR && pcy != read_addr) 
                        insty_addr <= pcy;
                end
            end
        end
    end
end

always @(negedge clk) begin
    if (rst) begin
        for (i = 0; i < BLOCK_SIZE; i = i + 1) begin
            data[i][0]  <= 0; 
            data[i][1]  <= 0;
            valid[i][0] <= 0; 
            valid[i][1] <= 0;
            tag[i]      <= 0;
        end
        read_addr   <= `NULL_PTR;
        read_data   <= `ZERO;
        read_size   <= `ZERO;
        counter     <= 0;
    end else if (rdy) begin  
        if (read_addr != `NULL_PTR) begin
            if (mode) begin
                if (read_size - counter > 1) begin
                    counter   <= counter + 1;
                    r_nw_out  <= rw_s;
                    addr_out  <= read_addr + counter + 1;
                    finish    <= 0;
                    if (rw_s == 1) begin
                        data_out  <= read_data[read_size - counter];
                    end else begin
                        read_data <= {read_data, mem_data};
                    end
                end else begin
                    counter   <= 0;
                    finish    <= 1;
                    ls_data_out <= {read_data, mem_data};

                    `REFETCH;
                end
            end else begin
                finish    <= 0;
                if (counter <= 2) begin
                    read_data <= {read_data, mem_data};
                    counter   <= counter + 1;
                    r_nw_out  <= `READ_SIGNAL;
                    addr_out  <= read_addr + counter + 1;
                end else /* if (counter == 3) */ begin
                    counter   <= 0;
                    // Put read_data in Cache
                    if (valid[read_addr_index][0] == 0) begin
                        valid[read_addr_index][0] <= 1;
                        tag[read_addr_index][0] <= read_addr[16 : 17 - TAG_WIDTH];
                        data[read_addr_index][0] <= {read_data, mem_data};
                    end else if (valid[read_addr_index][1] == 0) begin
                        valid[read_addr_index][1] <= 1;
                        tag[read_addr_index][1] <= read_addr[16 : 17 - TAG_WIDTH];
                        data[read_addr_index][1] <= {read_data, mem_data};
                    end else begin
                        // do not handle write
                        valid[read_addr_index][1] <= 1;
                        tag[read_addr_index][1] <= read_addr[16 : 17 - TAG_WIDTH];
                        data[read_addr_index][1] <= {read_data, mem_data};
                    end

                    // Fetch new addr
                    `REFETCH
                end
            end
        end else /* if(read_addr == `NULL_PTR) */ begin
            counter <= 0;            
            // Fetch new addr
            `REFETCH
        end
    end
end

endmodule // inst_cache