// riscv top module file
// modification allowed for debugging purposes

`timescale 1ns/1ps
module riscv_top
#(
	parameter SIM = 0						// whether in simulation
)
(
	input wire 			EXCLK,
	input wire [0:15]  sw,
	input wire			btnC, 
	input wire         btnL, btnR,
	input wire         btnU, btnD,
	output wire 		Tx,
	input wire 			Rx,
	output wire[0:15]  led,
	output wire [0:6]   seg,
	output wire [3:0]   an
);

localparam SYS_CLK_FREQ = 150000000;
localparam UART_BAUD_RATE = 115200;
localparam RAM_ADDR_WIDTH = 17; 			// 128KiB ram, should not be modified

reg rst;
reg rst_delay;
reg [63: 0] counter;
wire clk;

// assign EXCLK (or your own clock module) to clk
assign clk = EXCLK;

//  clk_wiz_0 clk_wiz(
//  .clk_out1(clk),
//  // Status and control signals
//  .reset(0),
//  .locked(),
//  // Clock in ports
//  .clk_in1(EXCLK)
//  );

always @(posedge clk or posedge btnC)
begin
	if (btnC) begin
	    counter     <= 0;      
		rst			<=	1'b1;
		rst_delay	<=	1'b1;
	end else begin
		rst_delay	<=	1'b0;
		rst			<=	rst_delay;
		counter     <= counter + 1;
	end
end

//
// System Memory Buses
//
wire [ 7:0]	cpumc_din;
wire [31:0]	cpumc_a;
wire        cpumc_wr;

//
// RAM: internal ram
//
wire 						ram_en;
wire [RAM_ADDR_WIDTH-1:0]	ram_a;
wire [ 7:0]					ram_dout;

ram #(.ADDR_WIDTH(RAM_ADDR_WIDTH))ram0(
	.clk_in(clk),
	.en_in(ram_en),
	.r_nw_in(~cpumc_wr),
	.a_in(ram_a),
	.d_in(cpumc_din),
	.d_out(ram_dout)
);

assign 		ram_en = (cpumc_a[RAM_ADDR_WIDTH:RAM_ADDR_WIDTH-1] == 2'b11) ? 1'b0 : 1'b1;
assign 		ram_a = cpumc_a[RAM_ADDR_WIDTH-1:0];

//
// CPU: CPU that implements RISC-V 32b integer base user-level real-mode ISA
//
wire [31:0] cpu_ram_a;
wire        cpu_ram_wr;
wire [ 7:0] cpu_ram_din;
wire [ 7:0] cpu_ram_dout;
wire		cpu_rdy;

wire [31:0] cpu_dbgreg_dout;

//fakecpu cpu0(
cpu cpu0(
	.clk_in(clk),
	.rst_in(rst),
	.rdy_in(cpu_rdy),

	.mem_din(cpu_ram_din),
	.mem_dout(cpu_ram_dout),
	.mem_a(cpu_ram_a),
	.mem_wr(cpu_ram_wr),

	.dbgreg_dout(cpu_dbgreg_dout)	// demo
);

//
// HCI: host communication interface block. Use controller to interact.
//
wire 						hci_active_out;
wire [ 7:0] 				hci_ram_din;
wire [ 7:0] 				hci_ram_dout;
wire [RAM_ADDR_WIDTH-1:0] 	hci_ram_a;
wire        				hci_ram_wr;

wire 						hci_io_en;
wire [ 2:0]					hci_io_sel;
wire [ 7:0]					hci_io_din;
wire [ 7:0]					hci_io_dout;
wire 						hci_io_wr;

hci #(.SYS_CLK_FREQ(SYS_CLK_FREQ),
	.RAM_ADDR_WIDTH(RAM_ADDR_WIDTH),
	.BAUD_RATE(UART_BAUD_RATE)) hci0
(
	.clk(clk),
	.rst(rst),
	.tx(Tx),
	.rx(Rx),
	.active(hci_active_out),
	.ram_din(hci_ram_din),
	.ram_dout(hci_ram_dout),
	.ram_a(hci_ram_a),
	.ram_wr(hci_ram_wr),
	.io_sel(hci_io_sel),
	.io_en(hci_io_en),
	.io_din(hci_io_din),
	.io_dout(hci_io_dout),
	.io_wr(hci_io_wr),

	.cpu_dbgreg_din(cpu_dbgreg_dout)	// demo
);

assign hci_io_sel	= cpumc_a[2:0];
assign hci_io_en	= (cpumc_a[RAM_ADDR_WIDTH:RAM_ADDR_WIDTH-1] == 2'b11) ? 1'b1 : 1'b0;
assign hci_io_wr	= cpumc_wr;
assign hci_io_din	= cpumc_din;

// hci is always disabled in simulation
wire hci_active;
assign hci_active 	= hci_active_out & ~SIM;

// indicates debug break
assign led = sw ^ {sw[1 : 15], 1'b0} ^ {1'b0, sw[0 : 14]};

// pause cpu on hci active
assign cpu_rdy		= (hci_active) ? 1'b0			 : 1'b1;

// Mux cpumc signals from cpu or hci blk, depending on debug break state (hci_active).
assign cpumc_a      = (hci_active) ? hci_ram_a		 : cpu_ram_a;
assign cpumc_wr		= (hci_active) ? hci_ram_wr      : cpu_ram_wr;
assign cpumc_din    = (hci_active) ? hci_ram_dout    : cpu_ram_dout;

assign cpu_ram_din 	= (hci_io_en)  ? hci_io_dout 	 : ram_dout;
assign hci_ram_din 	= ram_dout;

reg [3: 0] an_out, LED_BCD;
reg [6: 0] seg_out;

assign an = an_out;
assign seg = seg_out;

always @(*) begin
    case(counter[19:18])
    2'b00: begin
        an_out = 4'b0111; 
        LED_BCD = (counter[40:24] / 1000) % 10;
    end
    2'b01: begin
        an_out = 4'b1011;
        LED_BCD = (counter[40:24] / 100) % 10;
    end
    2'b10: begin
        an_out = 4'b1101;
        LED_BCD = (counter[40:24] / 10) % 10;        
    end
    2'b11: begin
        an_out = 4'b1110;       
        LED_BCD = (counter[40:24]) % 10; 
    end   

    endcase
end

always @(*) begin
    case(LED_BCD)
    4'b0000: seg_out = 7'b0000001;  
    4'b0001: seg_out = 7'b1001111;
    4'b0010: seg_out = 7'b0010010;
    4'b0011: seg_out = 7'b0000110;
    4'b0100: seg_out = 7'b1001100;
    4'b0101: seg_out = 7'b0100100;
    4'b0110: seg_out = 7'b0100000;
    4'b0111: seg_out = 7'b0001111;
    4'b1000: seg_out = 7'b0000000;  
    4'b1001: seg_out = 7'b0000100;
    default: seg_out = 7'b0101010;
    endcase
end

endmodule