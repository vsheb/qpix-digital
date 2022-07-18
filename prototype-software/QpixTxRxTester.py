from qpix_interface import QPInterface

class QpixTxRxTester:
  def __init__(self):
    self.s = QPInterface()
  
  def sendWord(self, low32bit = 0, high32bit = 0) : 
    # set a 64-bit word to be transfered
    self.s.regWrite(0xb, high32bit)
    self.s.regWrite(0xc, low32bit)
    # initiate transfer
    self.s.regWrite(0xa,1) 
  
  def getWord(self) : 
    if self.s.regRead(0x1) != 1000 :
      h = self.s.regRead(0xd)
      l = self.s.regRead(0xe)
      return l,h
    else:
      raise Exception('DAQ node is still in busy state')

  def doTest(self, low32bit = 0, high32bit = 0):
    self.sendWord(low32bit, high32bit)
    l,h = self.getWord()
    if l == low32bit and h == high32bit:
      print('OK')
    else : 
      print('ERROR:: write', hex(low32bit),hex(high32bit), 'read', hex(l), hex(h))
