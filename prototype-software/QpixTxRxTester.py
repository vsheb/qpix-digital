from qpix_interface import QPInterface
from qpix_interface import REG_ADDR

class QpixTxRxTester(QPInterface):
  def __init__(self):
    super().__init__()
    self.verify()

  def verify(self):
    """
    send information to the blank scratch register and make sure you can read
    and write back a random word
    """
    verification = 0x10101010
    self.regWrite(0x0, verification);
    check = self.regRead(0x0);
    if check != verification:
      print("WARNING verification check failed!")
      print(f"0x{verification:08x} != 0x{check:08x}")
    else:
      print("verification passed. communication with registers established..")
    status = self.regRead(0x1);
    print("current status:", status)

  def sendTrg(self) :
    """
    Send interrogation (trigger) command
    """
    self.regWrite(REG_ADDR['CMD'], 0x1);
  
  def sendWord(self, low32bit = 0, high32bit = 0) : 
    # set a 64-bit word to be transfered
    self.regWrite(0xb, high32bit)
    self.regWrite(0xc, low32bit)
    # initiate transfer
    self.regWrite(0xa,1) 
  
  def getWord(self) : 
    h = self.regRead(0xd)
    l = self.regRead(0xe)
    return l,h

  def doTest(self, low32bit = 0, high32bit = 0):
    self.sendWord(low32bit, high32bit)
    l,h = self.getWord()
    if l == low32bit and h == high32bit:
      print('OK')
    else : 
      print('ERROR: write', hex(low32bit),hex(high32bit), 'read', hex(l), hex(h))
