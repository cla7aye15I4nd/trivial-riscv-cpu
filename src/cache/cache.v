`timescale 1ns/1ps

module cache 
#(
    parameter LINE_WIDTH  = 32,
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
    output reg `addr_t addr_out
);

reg valid[0 : BLOCK_SIZE-1][0 : 1];
reg [TAG_WIDTH - 1: 0]  tag[0 : BLOCK_SIZE-1];
reg [LINE_WIDTH - 1: 0] idata[0 : BLOCK_SIZE-1][0 : 1];

reg `addr_t instx_addr_p, insty_addr_p;
reg `addr_t instx_addr_n, insty_addr_n;

wire [TAG_WIDTH - 1 : 0] pcx_tag, pcy_tag;
wire [14 - TAG_WIDTH : 0] pcx_index, pcy_index;
reg [14 - TAG_WIDTH : 0] addr_index;

// Instruction fetch
assign pcx_tag = pcx[16 : 17 - TAG_WIDTH];
assign pcy_tag = pcy[16 : 17 - TAG_WIDTH];

assign pcx_index = pcx[16 - TAG_WIDTH : 2];
assign pcy_index = pcy[16 - TAG_WIDTH : 2];

// load / store
reg `byte_t mode;
reg         data_oper;
reg `addr_t data_addr_p, data_addr_n;
reg `addr_t data_size;
reg `addr_t data_data;

reg `word_t counter;
reg `addr_t addr;
reg `word_t size;
reg `word_t data;

wire `byte_t mem_data;
assign mem_data = data_in;
 
integer i;
always @(posedge clk) begin
    if (rst) begin
        instx_addr_p  <= `NULL_PTR;
        insty_addr_p  <= `NULL_PTR;
        data_addr_p   <= `NULL_PTR;
        in_fifo     <= 0;
    end else begin
        if (en_ls && ls_addr != `NULL_PTR && data_addr_n == `NULL_PTR) begin
            data_oper <= ls_oper;
            data_addr_p <= ls_addr;
            data_size <= ls_size;
            data_data <= ls_data;
            in_fifo   <= 1;
        end else begin
            data_addr_p <= data_addr_n;
            in_fifo   <= 0;
        end

        if (en_rx && pcx != `NULL_PTR) begin
            if (valid[pcx_index][0] && tag[pcx_index][0] == pcx_tag) begin
                hitx <= 1;
                instx <= idata[pcx_index][0];
                instx_addr_p <= `NULL_PTR;
            end else if (valid[pcx_index][1] && tag[pcx_index][1] == pcx_tag) begin
                hitx <= 1;
                instx <= idata[pcx_index][1];
                instx_addr_p <= `NULL_PTR;
            end else begin
                hitx <= 0;
                instx <= `ZERO;
                if (instx_addr_n == `NULL_PTR && pcx != addr)
                    instx_addr_p <= pcx;
                else
                    instx_addr_p <= instx_addr_n;
            end
        end else begin
            hitx <= 0;
            instx_addr_p <= instx_addr_n;
        end

        if (en_ry && pcy != `NULL_PTR) begin
            if (valid[pcy_index][0] && tag[pcy_index][0] == pcy_tag) begin
                hity <= 1;
                insty <= idata[pcy_index][0];
                insty_addr_p <= `NULL_PTR;
            end else if (valid[pcy_index][1] && tag[pcy_index][1] == pcy_tag) begin
                hity <= 1;
                insty <= idata[pcy_index][1];
                insty_addr_p <= `NULL_PTR;
            end else begin
                hity <= 0;
                insty <= `ZERO;
                if (insty_addr_n == `NULL_PTR && pcy != addr) 
                    insty_addr_p <= pcy;
                else
                    insty_addr_p <= insty_addr_n;
            end
        end else begin
            hity <= 0;
            insty_addr_p <= insty_addr_n;
        end
    end
end

always @(negedge clk) begin
    if (rst) begin
        for (i = 0; i < BLOCK_SIZE; i = i + 1) begin
            idata[i][0] <= 0; 
            idata[i][1] <= 0;
            valid[i][0] <= 0; 
            valid[i][1] <= 0;
            tag[i]      <= 0;
        end
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
                instx_addr_n <= instx_addr_p;
                insty_addr_n <= insty_addr_p;
                data_addr_n <= data_addr_p;
            end else begin
                counter   <= 0;
                if (mode == 2'b10) begin
                    finish <= 0;
                    instx_addr_n <= instx_addr_p;
                    insty_addr_n <= insty_addr_p;
                    data_addr_n <= data_addr_p;
                    // Put read_data in Cache
                    if (valid[addr_index][0] == 0) begin
                        valid[addr_index][0] <= 1;
                        tag[addr_index][0] <= addr[16 : 17 - TAG_WIDTH];
                        idata[addr_index][0] <= {data, mem_data};
                    end else begin
                        valid[addr_index][1] <= 1;
                        tag[addr_index][1] <= addr[16 : 17 - TAG_WIDTH];
                        idata[addr_index][1] <= {data, mem_data};
                    end 
                end else if (mode == 2'b00) begin
                    ls_data_out <= {data, mem_data};
                    finish <= 1;
                    instx_addr_n <= instx_addr_p;
                    insty_addr_n <= insty_addr_p;
                    data_addr_n <= data_addr_p;
                end else begin
                    finish <= 0;
                    instx_addr_n <= instx_addr_p;
                    insty_addr_n <= insty_addr_p;
                    data_addr_n <= data_addr_p;
                end

                // Fetch new addr
                if (data_addr_p != `NULL_PTR) begin                                   
                    mode <= data_oper == `READ_SIGNAL ? 2'b00: 2'b01;                  
                    addr <= data_addr_p; 
                    size <= data_size;                                              
                    data <= data_oper == `READ_SIGNAL ? `ZERO: data_data[31 : 8];   
                    r_nw_out  <= data_oper == `WRITE_SIGNAL? `WRITE_SIGNAL : `READ_SIGNAL;
                    data_out  <= data_oper == `WRITE_SIGNAL? data_data[7 : 0]: 0;   
                    addr_out  <= data_addr_p;
                    data_addr_n <= `NULL_PTR; /* warning */
                    instx_addr_n <= instx_addr_p; 
                    insty_addr_n <= insty_addr_p;      
                end else if (instx_addr_p != `NULL_PTR) begin             
                    mode <= 2'b10;                                      
                    addr <= instx_addr_p;                                 
                    size <= 4;                                          
                    data <= `ZERO;                                      
                    r_nw_out   <= `READ_SIGNAL;                         
                    addr_out   <= instx_addr_p;        
                    data_addr_n <= data_addr_p;
                    instx_addr_n <= `NULL_PTR; /* warning */     
                    insty_addr_n <= insty_addr_p;         
                    addr_index <= instx_addr_p[16 - TAG_WIDTH : 2];       
                end else if (insty_addr_p != `NULL_PTR) begin             
                    mode <= 2'b10;                                      
                    addr <= insty_addr_p;                                 
                    size <= 4;                                          
                    data <= `ZERO;                                      
                    r_nw_out   <= `READ_SIGNAL;                         
                    addr_out   <= insty_addr_p;                           
                    insty_addr_n <= `NULL_PTR; /* warning */ 
                    instx_addr_n <= instx_addr_p;            
                    data_addr_n <= data_addr_p; 
                    addr_index <= insty_addr_p[16 - TAG_WIDTH : 2];       
                end else begin                                          
                    mode <= 2'b11;                                      
                    addr <= `NULL_PTR;                                  
                    data <= `ZERO;                                      
                    addr_out <= `ZERO;                                  
                    r_nw_out   <= `READ_SIGNAL;
                    instx_addr_n <= instx_addr_p;
                    insty_addr_n <= insty_addr_p;
                    data_addr_n <= data_addr_p;
                end

            end
        end else begin
            counter <= 0;    
            if (data_addr_p != `NULL_PTR) begin                                   
                mode <= data_oper == `READ_SIGNAL ? 2'b00: 2'b01;                  
                addr <= data_addr_p;
                size <= data_size;                                              
                data <= data_oper == `READ_SIGNAL ? `ZERO: data_data[31 : 8];   
                r_nw_out  <= data_oper == `WRITE_SIGNAL? `WRITE_SIGNAL : `READ_SIGNAL;
                data_out  <= data_oper == `WRITE_SIGNAL? data_data[7 : 0]: 0;   
                addr_out  <= data_addr_p;                             
                data_addr_n <= `NULL_PTR; /* warning */  
                instx_addr_n <= instx_addr_p; 
                insty_addr_n <= insty_addr_p;            
            end else if (instx_addr_p != `NULL_PTR) begin             
                mode <= 2'b10;                                      
                addr <= instx_addr_p;                                 
                size <= 4;                                          
                data <= `ZERO;                                      
                r_nw_out   <= `READ_SIGNAL;                         
                addr_out   <= instx_addr_p;                           
                instx_addr_n <= `NULL_PTR; /* warning */   
                insty_addr_n <= insty_addr_p;           
                addr_index <= instx_addr_p[16 - TAG_WIDTH : 2];       
            end else if (insty_addr_p != `NULL_PTR) begin             
                mode <= 2'b10;                                      
                addr <= insty_addr_p;                                 
                size <= 4;                                          
                data <= `ZERO;                                      
                r_nw_out   <= `READ_SIGNAL;                         
                addr_out   <= insty_addr_p;                           
                instx_addr_n <= `NULL_PTR; /* warning */  
                insty_addr_n <= insty_addr_p;            
                addr_index <= insty_addr_p[16 - TAG_WIDTH : 2];       
            end else begin                                          
                mode <= 2'b11;                                      
                addr <= `NULL_PTR;                                  
                data <= `ZERO;                                      
                addr_out <= `ZERO;                                  
                r_nw_out   <= `READ_SIGNAL;   
                instx_addr_n <= instx_addr_p;
                insty_addr_n <= insty_addr_p;
            end

        end
    end
end

endmodule // inst_cache