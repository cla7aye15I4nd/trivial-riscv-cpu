# trivial-riscv

This project is a trivial riscv cpu with tomasulo implemented in Verilog HDL, which is a course project of Computer Architecture, ACM Class @ SJTU.

> 越是强大的设计，有时可能会令人越痛苦																					


### Design


- name: ~~Error~~ **Isla**
- ISA: RISCV 32I
- tomasulo algorithm (out-of-order execution)
- 3-stages pipeline (fetch, dispatch, execute)
- 2-set associative 512B Instruction Cache (Replacing Policy: FIFO)
- Non-stop fetching instruction
- multiple ALU(Arithmetic Logic Unit)
- Segment LED timer, LED light game
- Direct map Data Cache
- Store Buffer

### Performance

- stably running on FPGA (200MHz, 81920 hours)
- IPC = analysing

### Todo

- [ ] Load buffer
- [ ] Instruction dual issue  
- [ ] Branch Prediction
- [ ] Interactive IO
### Reference

- [RISC-V ISA Specification](http://riscv.org/specifications/)
- https://github.com/Evensgn/RISC-V-CPU (Memory Simulator)
- 雷思磊. 自己动手写 CPU. 电子工业出版社, 2014.
- John L. Hennessy, David A. Patterson, et al. Computer Architecture: A Quantitative Approach, Fifth Edition, 2012.
