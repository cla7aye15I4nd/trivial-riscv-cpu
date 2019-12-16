# trivial-riscv

This project is a trivial riscv cpu with tomasulo implemented in Verilog HDL, which is a course project of Computer Architecture, ACM Class @ SJTU.

### Design

- ISA: RISCV 32I
- tomasulo algorithm
- 2-set associative 512B Instruction Cache
- 3-stages pipeline
- multiple ALU(Arithmetic Logic Unit)

### Performance

- stably running on FPGA(200MHz)
- IPC = analysing

### Todo

- [ ] Replacing Policy, FIFO
- [ ] 2-set associative Data Cache
- [ ] Instruction dual issue
- [ ] ROM (handle exception)
- [ ] Branch Prediction(G-share)
- [ ] Interactive IO
- [ ] Virtual Memory(TLB)

### Reference

- [RISC-V ISA Specification](http://riscv.org/specifications/)
- https://github.com/Evensgn/RISC-V-CPU (Memory Simulator)
- 雷思磊. 自己动手写 CPU. 电子工业出版社, 2014.
- John L. Hennessy, David A. Patterson, et al. Computer Architecture: A Quantitative Approach, Fifth Edition, 2012.