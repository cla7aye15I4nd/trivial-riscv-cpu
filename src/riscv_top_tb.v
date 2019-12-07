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
        #200000 $finish;
    end

    riscv_top #(.SIM(1))riscv_top_instance (
        .EXCLK(clk), .btnC(btn), .Rx(rx)
    );
endmodule // cpu_tb