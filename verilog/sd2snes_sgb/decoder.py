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
  
# operands
eOpr = enum(I=0,
            PC=1,
            S8=2,
            U16=3, # both immediates required?  Could use size to determine immediate size.  also may need a way to id FF vs sign extend
            BC=4,
            DE=5,
            SP=6,
            AF=7,
    
            B=8,
            C=9,
            D=10,
            E=11,
            H=12,
            L=13,
            HL=14,
            A=15,
            )

# upper bit used as mod bit (generally non-memory/memory)
eGrp = enum(SPC=0,MOV=1,INC=2, DEC=3, ALU=4, BIT=5, JMP=6, ___=7,
            MST=8,MLD=9,MIC=10,MDC=11,MLU=12,MBT=13,CLL=14,RET=15)

class Instruction:
  
  def to_string(self):
    if (self.Sze > 3):
      raise ValueError('Size too large: {:}'.format(self.Sze))
    if (self.Lat > 3):
      raise ValueError('Latency too large: {:}'.format(self.Lat))
    return  ( "{0:02b}".format(self.Sze)
            + "{0:02b}".format(self.Lat)
            + "{0:04b}".format(self.Dst)
            + "{0:04b}".format(self.Src)
            + "{0:04b}".format(self.Grp)
            )
  
  @staticmethod
  def defines():
    str = ''
    for i in xrange(len(eOpr.ValueToString)):
      str += '`define OPR_{:}     4\'d{:}\n'.format(eOpr.ValueToString[i], i)
    str += '\n'
    for i in xrange(len(eGrp.ValueToString)):
      str += '`define GRP_{:}     4\'d{:}\n'.format(eGrp.ValueToString[i], i)
    str += '\n'
    str += '`define DEC_SZE     {:}\n'.format('15:14')
    str += '`define DEC_LAT     {:}\n'.format('13:12')
    str += '`define DEC_DST     {:}\n'.format('11:8')
    str += '`define DEC_SRC     {:}\n'.format('7:4')
    str += '`define DEC_GRP     {:}\n'.format('3:0')
    return str
  
  def __init__(self, idx, opc, sze, lat, dst, src, grp):
    self.Idx = idx
    self.Opc = opc
    self.Sze = sze
    self.Lat = lat
    self.Dst = dst
    self.Src = src
    self.Grp = grp
          
def main():
  parser = argparse.ArgumentParser(description='Write decoder to file.')
  #parser.add_argument('--output', required=True, help='file to write out')
  args = parser.parse_args()

  # generate the instruction tables
  mxTable = []
  with open('optable.txt', 'rb') as t:
    opreader = csv.reader(t, delimiter=' ', skipinitialspace=True)
    for i, inst in enumerate(opreader):
      if ' '.join(inst).startswith(';'): continue
      
      try:
        mxTable.append(Instruction(idx=int(inst[0], 16),
                                   opc=inst[1],
                                   sze=(int(inst[2])-1),
                                   lat=(int(inst[3])-int(inst[2])),
                                   dst=eOpr.StringToValue[inst[4]],
                                   src=eOpr.StringToValue[inst[5]],
                                   grp=eGrp.StringToValue[inst[6]]
                                   )
                      )
      except ValueError:
        print 'ValueError: ' + '{0:2x}'.format(i) + ' '.join(inst) + '\n'
  
  output_files = ['ipcore_dir/dec_table.coe', 'dec_table.mif']
  
  for output_file in output_files:
    if os.path.exists(output_file):
      if os.path.isfile(output_file):
        copyfile(output_file, output_file+'.bak')
      else:
        print output_file + ' not a file.'
        sys.exit()
                  
  with open(output_files[0], 'w') as f: 
    f.write('; This .COE file specifies initialization values for a block \n')
    f.write('; memory of depth=256, and width=16. In this case, values are \n')
    f.write('; specified in hexadecimal format.\n')
    f.write('memory_initialization_radix=2;\n')
    f.write('memory_initialization_vector=\n')
    
    for i in xrange(0x100):
      if i != 0x00: f.write(',\n')
      if len(mxTable) <= i:
        f.write('1111111111111111')
      else:
        f.write(mxTable[i].to_string())
        
    f.write(';\n')
    f.close()

  with open(output_files[1], 'w') as f:
    f.write('DEPTH = 256;\n')
    f.write('WIDTH = 16;\n')
    f.write('ADDRESS_RADIX = HEX;\n')
    f.write('DATA_RADIX = BIN;\n')

    f.write('CONTENT\n')
    f.write('BEGIN\n')
      
    for i in xrange(0x100):
      if len(mxTable) <= i:
        f.write('      {:x}: 1111111111111111;\n'.format(i))
      else:
        f.write('      {:x}: {:};\n'.format(i, mxTable[i].to_string()))
        
    f.write('END;\n')
    f.close()

  with open('regs.out', 'w') as f:
    f.write(Instruction.defines())
    f.write('\n')

if __name__ == "__main__":
  main()
