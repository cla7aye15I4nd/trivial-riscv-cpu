module cache 
#(
    parameter LINE_WIDTH  = 32,
    parameter BLOCK_WIDTH = 6,
    parameter ADDR_WIDTH = 13,
    parameter BLOCK_SIZE  = 2**BLOCK_WIDTH,
    parameter TAG_WIDTH   = ADDR_WIDTH - BLOCK_WIDTH - 2
)
(
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

reg `addr_t instx_addr_p, insty_addr_p;
reg `addr_t instx_addr_n, insty_addr_n;

wire [TAG_WIDTH - 1 : 0] pcx_tag, pcy_tag;
wire [BLOCK_WIDTH - 1 : 0] pcx_index, pcy_index;
reg [BLOCK_WIDTH - 1 : 0] addr_index;

// Instruction fetch
assign pcx_tag = pcx[ADDR_WIDTH-1 : ADDR_WIDTH - TAG_WIDTH];
assign pcy_tag = pcy[ADDR_WIDTH-1 : ADDR_WIDTH - TAG_WIDTH];

assign pcx_index = pcx[ADDR_WIDTH-1 - TAG_WIDTH : 2];
assign pcy_index = pcy[ADDR_WIDTH-1 - TAG_WIDTH : 2];

// load / store
reg `byte_t mode;
reg         data_oper;
reg `addr_t data_addr_p, data_addr_n;
reg `byte_t data_size;
reg `word_t data_data;

reg `word_t counter;
reg `addr_t addr;
reg `word_t size;
reg `word_t data;

wire `byte_t mem_data;
assign mem_data = data_in;
 
integer i;
always @(posedge clk) begin
    if (rst || ~rdy) begin
        instx_addr_p  <= `NULL_PTR;
        insty_addr_p  <= `NULL_PTR;
        data_addr_p   <= `NULL_PTR;
        in_fifo     <= 0;
    end else begin
        if (en_ls && data_addr_n == `NULL_PTR) begin
            data_oper <= ls_oper;
            data_addr_p <= ls_addr;
            data_size <= ls_size;
            data_data <= ls_data;
            in_fifo   <= 1;
        end else begin
            data_addr_p <= data_addr_n;
            in_fifo   <= 0;
        end

        if (en_rx) begin
            if (valid0[pcx_index] && tag0[pcx_index] == pcx_tag) begin
                hitx <= 1;
                instx <= idata0[pcx_index];
                instx_addr_p <= `NULL_PTR;
            end else if (valid1[pcx_index] && tag1[pcx_index] == pcx_tag) begin
                hitx <= 1;
                instx <= idata1[pcx_index];
                instx_addr_p <= `NULL_PTR;
            end else begin
                hitx <= 0;
                instx <= `ZERO;
                if (instx_addr_n == `NULL_PTR && pcx != addr)
                    instx_addr_p <= pcx;
            end
        end else begin
            hitx <= 0;
        end

        if (en_ry) begin
            if (valid0[pcy_index] && tag0[pcy_index] == pcy_tag) begin
                hity <= 1;
                insty <= idata0[pcy_index];
                insty_addr_p <= `NULL_PTR;
            end else if (valid1[pcy_index] && tag1[pcy_index] == pcy_tag) begin
                hity <= 1;
                insty <= idata1[pcy_index];
                insty_addr_p <= `NULL_PTR;
            end else begin
                hity <= 0;
                insty <= `ZERO;
                if (insty_addr_n == `NULL_PTR && pcy != addr) 
                    insty_addr_p <= pcy;
            end
        end else begin
            hity <= 0;
        end
    end
end

always @(negedge clk) begin
    if (rst || ~rdy) begin
        valid0 <= 0;
        valid1 <= 0;
        mode <= 2'b11;
        addr <= `NULL_PTR;
        data <= `ZERO;
        instx_addr_n <= `NULL_PTR;
        insty_addr_n <= `NULL_PTR;
        data_addr_n <= `NULL_PTR;
        counter     <= 0;
    end else /*if (rdy)*/ begin  
        if (mode != 2'b11) begin
            if (size - counter > 1) begin
                if (mode == 2'b01) begin
                    data_out  <= data[7 : 0];
                    data      <= data[31 : 8];
                    r_nw_out  <= `WRITE_SIGNAL;
                end else begin
                    data <= {data, mem_data};
                    r_nw_out  <= `READ_SIGNAL;
                end
                finish    <= 0;
                counter   <= counter + 1;
                addr_out  <= addr + counter + 1;                
                data_addr_n <= data_addr_p;
            end else begin
                counter   <= 0;
                if (mode == 2'b10) begin
                    finish <= 0;
                    data_addr_n <= data_addr_p;
                    // Put read_data in Cache
                    if (valid0[addr_index] == 0) begin
                        valid0[addr_index] <= 1;
                        tag0[addr_index] <= addr[ADDR_WIDTH-1 : ADDR_WIDTH - TAG_WIDTH];
                        idata0[addr_index] <= {data, mem_data};
                    end else begin
                        valid1[addr_index] <= 1;
                        tag1[addr_index] <= addr[ADDR_WIDTH-1 : ADDR_WIDTH - TAG_WIDTH];
                        idata1[addr_index] <= {data, mem_data};
                    end 
                end else if (mode == 2'b00) begin
                    ls_data_out <= {data, mem_data};
                    finish <= 1;                
                    data_addr_n <= data_addr_p;
                end else begin
                    finish <= 0;
                    data_addr_n <= data_addr_p;
                end

                // Fetch new addr
                if (data_addr_p != `NULL_PTR) begin                                   
                    mode <= data_oper == `READ_SIGNAL ? 2'b00: 2'b01;                  
                    addr <= data_addr_p;
                    size <= data_size;                                              
                    data <= data_data[31 : 8];   
                    r_nw_out  <= data_oper;
                    data_out  <= data_data[7 : 0];   
                    addr_out  <= data_addr_p;                             
                    data_addr_n <= `NULL_PTR;          
                end else if (instx_addr_p != `NULL_PTR) begin             
                    mode <= 2'b10;                                      
                    addr <= instx_addr_p;                                 
                    size <= 4;                                          
                    data <= `ZERO;                                      
                    r_nw_out   <= `READ_SIGNAL;                         
                    addr_out   <= instx_addr_p;                           
                    instx_addr_n <= `NULL_PTR; 
                    addr_index <= instx_addr_p[ADDR_WIDTH-1 - TAG_WIDTH : 2];       
                end else if (insty_addr_p != `NULL_PTR) begin             
                    mode <= 2'b10;                                      
                    addr <= insty_addr_p;                                 
                    size <= 4;                                          
                    data <= `ZERO;                                      
                    r_nw_out   <= `READ_SIGNAL;                         
                    addr_out   <= insty_addr_p;                           
                    insty_addr_n <= `NULL_PTR;
                    addr_index <= insty_addr_p[ADDR_WIDTH-1 - TAG_WIDTH : 2];       
                end else begin                                          
                    mode <= 2'b11;                                      
                    addr <= `NULL_PTR;                                  
                    r_nw_out   <= `READ_SIGNAL;   
                end

            end
        end else begin
            counter <= 0;    
            if (data_addr_p != `NULL_PTR) begin                                   
                mode <= data_oper == `READ_SIGNAL ? 2'b00: 2'b01;                  
                addr <= data_addr_p;
                size <= data_size;                                              
                data <= data_data[31 : 8];   
                r_nw_out  <= data_oper;
                data_out  <= data_data[7 : 0];   
                addr_out  <= data_addr_p;                             
                data_addr_n <= `NULL_PTR;          
            end else if (instx_addr_p != `NULL_PTR) begin             
                mode <= 2'b10;                                      
                addr <= instx_addr_p;                                 
                size <= 4;                                          
                data <= `ZERO;                                      
                r_nw_out   <= `READ_SIGNAL;                         
                addr_out   <= instx_addr_p;                           
                instx_addr_n <= `NULL_PTR; 
                addr_index <= instx_addr_p[ADDR_WIDTH-1 - TAG_WIDTH : 2];       
            end else if (insty_addr_p != `NULL_PTR) begin             
                mode <= 2'b10;                                      
                addr <= insty_addr_p;                                 
                size <= 4;                                          
                data <= `ZERO;                                      
                r_nw_out   <= `READ_SIGNAL;                         
                addr_out   <= insty_addr_p;                           
                insty_addr_n <= `NULL_PTR;
                addr_index <= insty_addr_p[ADDR_WIDTH-1 - TAG_WIDTH : 2];       
            end else begin                                          
                mode <= 2'b11;                                      
                addr <= `NULL_PTR;                                  
                r_nw_out   <= `READ_SIGNAL;   
            end
        end
    end
end

endmodule // inst_cache