#!c:\Python27\python.exe

import argparse
import os.path
import sys
import csv

from shutil import copyfile

def enum(*sequential, **named):
  enums = dict(zip(sequential, range(len(sequential))), **named)
  forward = dict((key, value) for key, value in enums.iteritems())
  reverse = dict((value, key) for key, value in enums.iteritems())
  enums['StringToValue'] = forward
  enums['ValueToString'] = reverse
  return type('Enum', (), enums)
  
#class ByteCount(Enum):

eOpcode = enum(
               ADC=0,
               AND=1,
               ASL=2,
               BCC=3,
               BCS=4,
               BEQ=5,
               BIT=6,
               BMI=7,
               BNE=8,
               BPL=9,
               BRA=10,
               BRK=11,
               BRL=12,
               BVC=13,
               BVS=14,
               CLC=15,
               CLD=16,
               CLI=17,
               CLV=18,
               CMP=19,
               COP=20,
               CPX=21,
               CPY=22,
               DEC=23,
               DEX=24,
               DEY=25,
               EOR=26,
               INC=27,
               INX=28,
               INY=29,
               JML=30,
               JMP=31,
               JSL=32,
               JSR=33,
               LDA=34,
               LDX=35,
               LDY=36,
               LSR=37,
               MVN=38,
               MVP=39,
               NOP=40,
               ORA=41,
               PEA=42,
               PEI=43,
               PER=44,
               PHA=45,
               PHB=46,
               PHD=47,
               PHK=48,
               PHP=49,
               PHX=50,
               PHY=51,
               PLA=52,
               PLB=53,
               PLD=54,
               PLP=55,
               PLX=56,
               PLY=57,
               REP=58,
               ROL=59,
               ROR=60,
               RTI=61,
               RTL=62,
               RTS=63,
               SBC=64,
               SEC=65,
               SED=66,
               SEI=67,
               SEP=68,
               STA=69,
               STP=70,
               STX=71,
               STY=72,
               STZ=73,
               TAX=74,
               TAY=75,
               TCD=76,
               TCS=77,
               TDC=78,
               TRB=79,
               TSB=80,
               TSC=81,
               TSX=82,
               TXA=83,
               TXS=84,
               TXY=85,
               TYA=86,
               TYX=87,
               WAI=88,
               WDM=89,
               XBA=90,
               XCE=91,
              )

# addressing modes
eMode = enum(Absolute=0,
             AbsoluteIndexedX=1,
             AbsoluteIndexedY=2,
             AbsoluteIndexedIndirect=3,
             AbsoluteIndirect=4,
             AbsoluteIndirectLong=5,
             AbsoluteLong=6,
             AbsoluteLongIndexedX=7,
             Accumulator=8,
             #BlockMove=
             
             DirectPage=9,
             DirectPageIndexedX=10,
             DirectPageIndexedY=11,
             DirectPageIndexedIndirectX=12,
             DirectPageIndirect=13,
             DirectPageIndirectLong=14,
             DirectPageIndirectIndexedY=15,
             DirectPageIndirectLongIndexedY=16,
             
             Immediate=17,
             Implied=18,
             ProgramCounterRelative=19,
             ProgramCounterRelativeLong=20,
             
             StackAbsolute=21,
             StackDirectPageIndirect=22,
             StackInterrupt=23,
             StackProgramCounterRelative=24,
             StackPull=25,
             StackPush=26,
             StackRTI=27,
             StackRTL=28,
             StackRTS=29,
             StackRelative=30,
             StackRelativeIndirectIndexedY=31,
            )

ePrc = enum(B=0,M=1,X=2,W=3)
eReg = enum(I=0,A=1,X=2,Y=3,S=4,D=5,B=6,P=7,K=4,   C=0,Z=1,V=2,N=3,c=4,z=5,v=6,n=7)
eGrp = enum(PRI=0,RMW=1,CBR=2,JMP=3,PHS=4,PLL=5,CMP=6,STS=7,MOV=8,TXR=9,SPC=10,SMP=11,STK=12,XCH=13,TST=14,NOP=15)
eBnk = enum(P=0,D=1,Z=2,O=3)
eAdd = enum(O16=0,DPR=1,PCR=2,SPL=3,SMI=4,SPR=5)
eMod = enum(X=0,Y=1,P=2,I=3)

class Instruction:
  
  def to_string(self):
    str = ""
    #str += "{0:01b}".format(self.G_Pri) + "{0:01b}".format(self.G_Rmw) + "{0:01b}".format(self.G_Cbr) + "{0:01b}".format(self.G_Jmp) + "{0:01b}".format(self.G_Phs) + "{0:01b}".format(self.G_Pll) + "{0:01b}".format(self.G_Cmp) + "{0:01b}".format(self.G_Sts) + "{0:01b}".format(self.G_Mov) + "{0:01b}".format(self.G_Txr) + "{0:01b}".format(self.G_Spc) + "{0:01b}".format(self.G_Smp) + "{0:01b}".format(self.G_Stk) + "{0:01b}".format(self.G_Xch) + "{0:01b}".format(self.G_Tst) + "{0:016b}".format(0)
    str +=  "{0:01b}".format(self.Stk) + "{0:01b}".format(self.Lng) + "{0:01b}".format(self.Ind) + "{0:01b}".format(self.Imm) + "{0:02b}".format(self.Mod) + "{0:03b}".format(self.Add) + "{0:02b}".format(self.Bnk) + "{0:04b}".format(self.Grp) + "{0:02b}".format(self.Operands) + "{0:04b}".format(self.Latency) + "{0:02b}".format(self.Prc) + "{0:03b}".format(self.Src) + "{0:03b}".format(self.Dst) + "{0:01b}".format(self.Load) + "{0:01b}".format(self.Store) + "{0:01b}".format(self.Ctl)
    return str
  
  @staticmethod
  def defines():
    str = ''
    str += '`define GRP_PRI     0\n'
    str += '`define GRP_RMW     1\n'
    str += '`define GRP_CBR     2\n'
    str += '`define GRP_JMP     3\n'
    str += '`define GRP_PHS     4\n'
    str += '`define GRP_PLL     5\n'
    str += '`define GRP_CMP     6\n'
    str += '`define GRP_STS     7\n'
    str += '`define GRP_MOV     8\n'
    str += '`define GRP_TXR     9\n'
    str += '`define GRP_SPC     10\n'
    str += '`define GRP_SMP     11\n'
    str += '`define GRP_STK     12\n'
    str += '`define GRP_XCH     13\n'
    str += '`define GRP_TST     14\n'
    str += '\n'
    str += '`define ADD_O16     0\n'
    str += '`define ADD_DPR     1\n'
    str += '`define ADD_PCR     2\n'
    str += '`define ADD_SPL     3\n'
    str += '`define ADD_SMI     4\n'
    str += '`define ADD_SPR     5\n'
    str += '\n'
    str += '`define BNK_PBR     0\n'
    str += '`define BNK_DBR     1\n'
    str += '`define BNK_ZRO     2\n'
    str += '`define BNK_O24     3\n'
    str += '\n'
    str += '`define MOD_X16     0\n'
    str += '`define MOD_Y16     1\n'
    str += '`define MOD_YPT     2\n'
    str += '`define MOD_INV     3\n'
    str += '\n'
    str += '`define ADD_STK     31:31\n'
    str += '`define ADD_LNG     30:30\n'
    str += '`define ADD_IND     29:29\n'
    str += '`define ADD_IMM     28:28\n'
    str += '`define ADD_MOD     27:26\n'
    str += '`define ADD_ADD     25:23\n'
    str += '`define ADD_BNK     22:21\n'
    str += '`define DEC_GROUP   20:17\n'
    str += '`define DEC_SIZE    16:15\n'
    str += '`define DEC_LATENCY 14:11\n'
    str += '`define DEC_PRC     10:9\n'
    str += '`define DEC_SRC      8:6\n'
    str += '`define DEC_DST      5:3\n'
    str += '`define DEC_LOAD     2:2\n'
    str += '`define DEC_STORE    1:1\n'
    str += '`define DEC_CONTROL  0:0\n'
    str += '\n'
    str += '`define PRC_B        0\n'
    str += '`define PRC_M        1\n'
    str += '`define PRC_X        2\n'
    str += '`define PRC_W        3\n'
    str += '\n'
    str += '`define REG_Z        0\n'
    str += '`define REG_A        1\n'
    str += '`define REG_X        2\n'
    str += '`define REG_Y        3\n'
    str += '`define REG_S        4\n'
    str += '`define REG_D        5\n'
    str += '`define REG_B        6\n'
    str += '`define REG_P        7\n'
    str += '`define REG_K        4\n'
    return str
  
  def __init__(self, index, opcode, mode, operands, latency, prc, src, dst, load, store, ctl, grp, imm, bnk, add, mod, ind, lng, stk):
    self.Index = index
    self.Opcode = opcode
    self.Mode = mode
    self.Operands = operands
    self.Latency = latency
    self.Prc = prc
    self.Src = src
    self.Dst = dst
    self.Load = load
    self.Store = store
    self.Ctl = ctl
    self.Grp = grp
    self.Imm = imm
    self.Bnk = bnk
    self.Add = add
    self.Mod = mod
    self.Ind = ind
    self.Lng = lng
    self.Stk = stk
          
def main():
  parser = argparse.ArgumentParser(description='Write decoder to file.')
  parser.add_argument('file', help='file to write out')
  args = parser.parse_args()

  # generate the instruction tables
  mxTable = []
  with open('optable.txt', 'rb') as t:
    opreader = csv.reader(t, delimiter=' ', skipinitialspace=True)
    for inst in opreader:
      if ' '.join(inst).startswith(';'): continue
      
      try:
        mxTable.append(Instruction(index=int(inst[0], 16), opcode=eOpcode.StringToValue[inst[1]], mode=eMode.StringToValue[inst[2]], operands=(int(inst[3])-1), latency=(int(inst[4])-1), prc=ePrc.StringToValue[inst[5]], src=eReg.StringToValue[inst[6]], dst=eReg.StringToValue[inst[7]], load=int(inst[8]), store=int(inst[9]), ctl=int(inst[10]), grp=eGrp.StringToValue[inst[11]], imm=int(inst[12]), bnk=eBnk.StringToValue[inst[13]], add=eAdd.StringToValue[inst[14]], mod=eMod.StringToValue[inst[15]], ind=int(inst[16]), lng=int(inst[17]), stk=int(inst[18])));
      except ValueError:
        print 'ValueError: ' + ' '.join(inst) + '\n'
  
  if os.path.exists(args.file):
    if os.path.isfile(args.file):
      copyfile(args.file, args.file+'.bak')
    else:
      print args.file + ' not a file.'
      sys.exit()
                  
  with open(args.file, 'w') as f: 
    f.write('; This .COE file specifies initialization values for a block \n')
    f.write('; memory of depth=256, and width=32. In this case, values are \n')
    f.write('; specified in hexadecimal format.\n')
    f.write('memory_initialization_radix=2;\n')
    f.write('memory_initialization_vector=\n')
    
    for i in xrange(0x100):
      if i != 0x00: f.write(',\n')
      if len(mxTable) <= i:
        f.write('11111111111111111111111111111111')
      else:
        f.write(mxTable[i].to_string())
        
    f.write(';\n')
    f.close()

  #  str = "{0:07b}".format(self.Opcode) + "{0:05b}".format(self.Mode) + "{0:02b}".format(self.Operands) + "{0:04b}".format(self.Latency) + "{0:02b}".format(self.Prc) + "{0:03b}".format(self.Src) + "{0:03b}".format(self.Dst) + "{0:06b}".format(0)
  with open('regs.out', 'w') as f:
    f.write(Instruction.defines())
    f.write('\n')
        
if __name__ == "__main__":
  main()
