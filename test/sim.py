def rev(inst):
    assert(len(inst) == 32)
    return ' '.join([inst[24 : 32], inst[16 : 24], inst[8 : 16], inst[0 : 8]])

def pad(x, sz):
    num = bin(x)[2:]
    assert(len(num) <= sz)
    return '0' * (sz - len(num)) + num

def LUI(imm, rd):
    print(rev(pad(imm, 20) + pad(rd, 5) + '0110111'))

def AUIPC(imm, rd):
    print(rev(pad(imm, 20) + pad(rd, 5) + '0010111'))
    
def ADDI(imm, rs1, rd):
    print(rev(pad(imm, 12) + pad(rs1, 5) + '000' + pad(rd, 5) + '0010011'))

def ADD(rs1, rs2, rd):
    print(rev('0' * 7 + pad(rs1, 5) + pad(rs2, 5) + '000' + pad(rd, 5) + '0110011'))

def LB(imm, rs1, rd):
    print(rev(pad(imm, 12) + pad(rs1, 5) + '000' + pad(rd, 5) + '0000011'))

def LH(imm, rs1, rd):
    print(rev(pad(imm, 12) + pad(rs1, 5) + '001' + pad(rd, 5) + '0000011'))

def LW(imm, rs1, rd):
    print(rev(pad(imm, 12) + pad(rs1, 5) + '010' + pad(rd, 5) + '0000011'))    

def SW(imm, rs1, rs2):
    imm = pad(imm, 12)
    print(rev(imm[:7] + pad(rs2, 5) + pad(rs1, 5) + '010' + imm[7:] + '0100011'))

def BLT(imm, rs1, rs2):
    imm = pad(imm, 13)
    print(rev(imm[0 : 1] + imm[2 : 8] + pad(rs2, 5) + pad(rs1, 5) + '100' + imm[8 : 12] + imm[1 : 2] + '1100011'))

ADDI(16, 0, 4)
BLT(12, 0, 4)
ADDI(16, 0, 4)
ADDI(16, 0, 4)
ADDI(16, 0, 4)
ADDI(16, 0, 4)
ADDI(16, 0, 4)
ADDI(16, 0, 4)
ADDI(16, 0, 4)
ADDI(16, 0, 4)
ADDI(16, 0, 4)
ADDI(16, 0, 4)