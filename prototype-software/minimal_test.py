import QpixTxRxTester
import numpy as np
import time

def testFifo(qpt):
    """
    helper function used for testing dual port ram on QpixAsicFifoDummyTop
    """
    def read(x, addr):
        x = (x << 8) & 0xffff_ffff_ffff_ffff
        addr = addr & 0xff
        x = x + addr

        # highest bit must be on
        high = (x >> 32 & 0x7fff_ffff) or 0x8000_0000
        time.sleep(0.05)
        qpt.sendWord(x & 0xffff_ffff, high)

        # get the data back
        time.sleep(0.05)
        low, high = qpt.getWord()
        addr = low & 0xff
        x = low & 0xffff_ff00
        x = x >> 8
        x += high << 32
        return addr, x

    def write(x, addr):
        x = (x << 8) & 0xffff_ffff_ffff_ffff
        addr = addr & 0xff
        x = x + addr
        low = x & 0xffff_ffff
        # highest bit must be off to prevent write
        high = (x & 0x7fff_ffff_0000_0000) >> 32
        time.sleep(0.05)
        qpt.sendWord(low, high)

    # data_words = [1,2,3,4,5, 3<<6, 7<<7]
    # addrs = [1<<1, 1<<2, 1<<3, 1<<4, 1<<5, 1<<6, 1<<7]

    data_words = [np.random.randint(1<<32) for i in range(10)]
    addrs = [i for i in range(10)]

    # write all of the data
    for data, addr in zip(data_words, addrs):
        input("write?")
        write(data, addr)

    # read all of the data
    time.sleep(0.1)
    for data, addr in zip(data_words, addrs):
        input("read?")
        a, d = read(data, addr)
        if a == addr and d == data:
            print(f"0x{addr:02x}.. ", end="")
        else:
            print(f"found INCORRECT pair addr: 0x{addr:02x}/0x{a:02x} - 0x{data:08x}/0x{d:08x}")


def issueTrigger():
    while True:
        resp = input("press enter to send trigger? ")
        if resp == "q":
            break
        t.sendTrg()
        resp = input("trigger sent.. continue with test? q to exit ")
        if resp == "q":
            break

t = QpixTxRxTester.QpixTxRxTester()
testFifo(t)

# # perform echo word test
# # perform test, send 64 bits provided in arg, and check it against received word
# t.doTest(0xaaaa,0xaaaa) # first arg - MSB 32 bits, second arg - LSB 32 bits
# # t.doTest(0xffffffff,0xffffffff)
# issueTrigger()
