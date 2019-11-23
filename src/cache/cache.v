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
    output wire `byte_t data_out,
    output reg r_nw_out,
    output reg `addr_t addr_out
);

reg [TAG_WIDTH - 1: 0]  tag[0 : BLOCK_SIZE-1];
reg [LINE_WIDTH - 1: 0] data[0 : BLOCK_SIZE-1][0 : 1];
reg valid[0 : BLOCK_SIZE-1][0 : 1];
reg instx_addr, insty_addr;

wire [BLOCK_WIDTH - 1 : 0] pcx_index, pcy_index;
wire [TAG_WIDTH - 1 : 0] pcx_tag, pcy_tag;

// Instruction fetch
assign pcx_tag = pcx[16 : 17 - TAG_WIDTH];
assign pcy_tag = pcy[16 : 17 - TAG_WIDTH];
assign pcx_index = pcx[16 - TAG_WIDTH : 2];
assign pcy_index = pcy[16 - TAG_WIDTH : 2];

integer i;
integer counter;
reg `addr_t read_addr, read_addr_index;
reg `word_t read_data;

always @(*) begin
    if (en_rx) begin
        if (valid[pcx_index][0] && tag[pcx_index][0] == pcx_tag) begin
            hitx = 1;
            instx = data[pcx_index][0];
            instx_addr = `NULL_PTR;
        end else if (valid[pcx_index][1] && tag[pcx_index][1] == pcx_tag) begin
            hitx = 1;
            instx = data[pcx_index][0];
            instx_addr = `NULL_PTR;
        end else begin
            hitx = 0;
            if (instx_addr != `NULL_PTR)
                instx_addr = pcx;
        end
    end

    if (en_ry) begin
        if (valid[pcy_index][0] && tag[pcy_index][0] == pcy_tag) begin
            hity = 1;
            insty = data[pcy_index][0];
            insty_addr = `NULL_PTR;
        end else if (valid[pcy_index][1] && tag[pcy_index][1] == pcy_tag) begin
            hity = 1;
            insty = data[pcy_index][0];
            insty_addr = `NULL_PTR;
        end else begin
            hity = 0;
            if (insty_addr != `NULL_PTR) 
                insty_addr = pcy;
        end
    end
end

always @(posedge clk) begin
    if (rst) begin
        for (i = 0; i < BLOCK_SIZE; i = i + 1) begin
            data[i][0] <= 0; 
            data[i][1] <= 0;
            valid[i][0] <= 0; 
            valid[i][1] <= 0;
            tag[i]      <= 0;
            instx_addr  <= `NULL_PTR;
            insty_addr  <= `NULL_PTR;
            read_addr   <= `NULL_PTR;
            read_data   <= `ZERO_WORD;
            counter     <= 0;
        end
    end else begin
        if (read_addr != `NULL_PTR && counter <= 2) begin
            read_data <= read_data | (data_in << counter);
            counter   <= counter + 1;
            r_nw_out  <= 1;
            addr_out  <= read_addr + counter + 1;
        end else if (read_addr != `NULL_PTR && counter == 3) begin
            read_data <= `ZERO_WORD;
            counter    <= 0;

            // Put read_data in Cache
            if (valid[read_addr_index][0] == 0) begin
                valid[read_addr_index][0] <= 1;
                tag[read_addr_index][0] <= read_addr[16 : 17 - TAG_WIDTH];
                data[read_addr_index][0] <= read_data | (data_in << counter);
            end else if (valid[read_addr_index][1] == 0) begin
                valid[read_addr_index][1] <= 1;
                tag[read_addr_index][1] <= read_addr[16 : 17 - TAG_WIDTH];
                data[read_addr_index][1] <= read_data | (data_in << counter);
            end else begin
                // do not handle write
                valid[read_addr_index][1] <= 1;
                tag[read_addr_index][1] <= read_addr[16 : 17 - TAG_WIDTH];
                data[read_addr_index][1] <= read_data | (data_in << counter);
            end

            // Fetch new addr
            if (instx_addr != `NULL_PTR) begin
                read_addr  <= instx_addr;
                r_nw_out   <= 1;
                addr_out   <= instx_addr;
                instx_addr <= `NULL_PTR;
            end else if (insty_addr != `NULL_PTR) begin
                read_addr  <= insty_addr;
                r_nw_out   <= 1;
                addr_out   <= insty_addr;
                insty_addr <= `NULL_PTR;
            end else begin
                read_addr  <= `NULL_PTR;
            end
        end
    end
end

endmodule // inst_cache