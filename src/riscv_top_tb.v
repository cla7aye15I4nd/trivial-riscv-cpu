`include "common/fifo/fifo.v"

`include "common/uart/uart_rx.v"
`include "common/uart/uart_tx.v"
`include "common/uart/uart_baud_clk.v"
`include "common/uart/uart.v"

`include "hci.v"
`include "cpu.v"
`include "ram/ram.v"
`include "riscv_top.v"
`timescale 1ns/1ps  

module cpu_tb();
    reg clk;
    reg btn;
    reg rx;
    
    initial begin
        $dumpfile("test.vcd");
        $dumpvars(0, cpu_tb);
        rx = 0;
        clk = 0;
        forever #50 clk = ~clk;
    end

    initial begin
        btn = 1;
        #200 btn = 0;
        #20000 $finish;
    end

    riscv_top #(.SIM(1))riscv_top_instance (
        .EXCLK(clk), .btnC(btn), .Rx(rx)
    );
endmodule // cpu_tb